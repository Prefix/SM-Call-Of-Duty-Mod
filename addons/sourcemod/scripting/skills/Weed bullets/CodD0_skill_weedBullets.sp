#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

#define EF_BONEMERGE				(1 << 0)
#define EF_NOSHADOW				 	(1 << 4)
#define EF_NORECEIVESHADOW		  	(1 << 6)

public Plugin myinfo =  {
	name = "COD d0 Skill: Weed bullets", 
	author = "d0naciak", 
	description = "Skill: Weed bullets", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToWeed[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToWeed[MAXPLAYERS+1];

int g_clientGlowId[MAXPLAYERS+1];
Handle g_timerWeeding[MAXPLAYERS+1];

public void OnPluginStart() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientDisconnect(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_weedBullets");

	CreateNative("CodD0_SetClientChanceToWeedOpponnent", nat_SetClientChanceToWeedOpponnent);
	CreateNative("CodD0_GetClientChanceToWeedOpponnent", nat_GetClientChanceToWeedOpponnent);
}

public int nat_SetClientChanceToWeedOpponnent(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToWeed[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToWeed[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToWeed[client][i] && (!g_activeChanceToWeed[client] || g_chanceToWeed[client][i] < g_activeChanceToWeed[client])) {
			g_activeChanceToWeed[client] = g_chanceToWeed[client][i];
		}
	}
}

public int nat_GetClientChanceToWeedOpponnent(Handle plugin, int paramsNum) {
	return g_chanceToWeed[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

	if (g_timerWeeding[client] != null) {
		KillTimer(g_timerWeeding[client]);
		g_timerWeeding[client] = null;
	}
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if (damageType & DMG_BULLET && g_activeChanceToWeed[attacker] && GetRandomInt(1, g_activeChanceToWeed[attacker]) == 1) {
		Weed(victim);
	}
}

public void ev_Spawn_Post(int client) {
	if (IsPlayerAlive(client) && g_timerWeeding[client] != null) {
		KillTimer(g_timerWeeding[client]);
		g_timerWeeding[client] = null;
	}
}

void Weed(int victim) {
	if (g_timerWeeding[victim] == null) {
		int entity = AttachGlowToPlayer(victim, {139, 255, 23, 255});
		if(entity >= 0) {
			g_clientGlowId[victim] = EntIndexToEntRef(entity);
		}

		g_timerWeeding[victim] = CreateTimer(5.0, timer_EndOfWeeding, victim);
	}
}

public Action timer_EndOfWeeding(Handle hTimer, any victim) {
	g_timerWeeding[victim] = null;

	if(IsClientInGame(victim) && IsPlayerAlive(victim)) {
		RemoveGlow(EntRefToEntIndex(g_clientGlowId[victim]));
	}
	
	return Plugin_Continue;
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon) {
	if(g_timerWeeding[client] == null) {
		return Plugin_Continue;
	}

	velocity[0] = -velocity[0];
	velocity[1] = -velocity[1];

	if(buttons & IN_MOVELEFT) {
		buttons &= ~IN_MOVELEFT;
		buttons |= IN_MOVERIGHT;
	} else if(buttons & IN_MOVERIGHT) {
		buttons &= ~IN_MOVERIGHT;
		buttons |= IN_MOVELEFT;
	}

	if(buttons & IN_FORWARD) {
		buttons &= ~IN_FORWARD;
		buttons |= IN_BACK;
	} else if(buttons & IN_BACK) {
		buttons &= ~IN_BACK;
		buttons |= IN_FORWARD;
	}

	return Plugin_Changed;
}

int AttachGlowToPlayer(int client, const int iColors[4]) {
	int iEnt = CreateEntityByName("prop_dynamic_glow");

	if(iEnt == -1) {
		return -1;
	}

	char szModel[256];

	GetClientModel(client, szModel, sizeof(szModel));

	DispatchKeyValue(iEnt, "model", szModel);
	DispatchKeyValue(iEnt, "solid", "0");
	DispatchKeyValue(iEnt, "fademindist", "1");
	DispatchKeyValue(iEnt, "fademaxdist", "1");
	DispatchKeyValue(iEnt, "fadescale", "2.0");
	SetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(iEnt);
	SetEntityRenderMode(iEnt, RENDER_GLOW);
	SetEntityRenderColor(iEnt, 0, 0, 0, 0);
	SetEntProp(iEnt, Prop_Send, "m_fEffects", EF_BONEMERGE);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("primary");
	AcceptEntityInput(iEnt, "SetParentAttachment", iEnt, iEnt, 0);
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(iEnt, "AddOutput");

	static int iOffset;

	if (!iOffset && (iOffset = GetEntSendPropOffs(iEnt, "m_clrGlow")) == -1) {
		AcceptEntityInput(iEnt, "FireUser1");
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return -1;
	}

	// Enable glow for custom skin
	SetEntProp(iEnt, Prop_Send, "m_bShouldGlow", true);
	SetEntProp(iEnt, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(iEnt, Prop_Send, "m_flGlowMaxDist", 10000.0);

	// So now setup given glow colors for the skin
	for(int i=0;i<3;i++) {
		SetEntData(iEnt, iOffset + i, iColors[i], _, true); 
	}

	return iEnt;
}

void RemoveGlow(int iEnt) {
	if(iEnt != INVALID_ENT_REFERENCE) {
		SetEntProp(iEnt, Prop_Send, "m_bShouldGlow", false);
		AcceptEntityInput(iEnt, "FireUser1");
	}
}