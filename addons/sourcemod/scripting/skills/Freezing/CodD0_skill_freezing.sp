#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

#define EF_BONEMERGE				(1 << 0)
#define EF_NOSHADOW				 	(1 << 4)
#define EF_NORECEIVESHADOW		  	(1 << 6)

public Plugin myinfo =  {
	name = "COD d0 Skill: Freezing", 
	author = "d0naciak", 
	description = "Skill: Freezing", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToFreeze[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToFreeze[MAXPLAYERS+1];

Handle g_timerUnfreeze[MAXPLAYERS+1];
int g_clientGlowId[MAXPLAYERS+1];

public void OnPluginStart() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart() {
	PrecacheSound("physics/glass/glass_strain2.wav", true);
	PrecacheSound("physics/glass/glass_bottle_break2.wav", true);
}

public void OnMapEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		g_timerUnfreeze[i] = null;
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
	RegPluginLibrary("CodD0_skill_freezing");

	CreateNative("CodD0_SetClientChanceToFreeze", nat_SetClientChanceToFreeze);
	CreateNative("CodD0_GetClientChanceToFreeze", nat_GetClientChanceToFreeze);
}

public int nat_SetClientChanceToFreeze(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToFreeze[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToFreeze[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToFreeze[client][i] && (!g_activeChanceToFreeze[client] || g_chanceToFreeze[client][i] < g_activeChanceToFreeze[client])) {
			g_activeChanceToFreeze[client] = g_chanceToFreeze[client][i];
		}
	}
}

public int nat_GetClientChanceToFreeze(Handle plugin, int paramsNum) {
	return g_chanceToFreeze[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

	if(g_timerUnfreeze[client] != null) {
		KillTimer(g_timerUnfreeze[client]);
		g_timerUnfreeze[client] = null;
	}
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if(damageType & DMG_BULLET && g_activeChanceToFreeze[attacker] && GetRandomInt(1,g_activeChanceToFreeze[attacker]) == 1) {
		Freeze(victim);
	}
}

public void ev_Spawn_Post(int client) {
	if(IsPlayerAlive(client) && g_timerUnfreeze[client] != null) {
		KillTimer(g_timerUnfreeze[client]);
		g_timerUnfreeze[client] = null;
	}
}

void Freeze(int client) {
	if(g_timerUnfreeze[client] != null) {
		KillTimer(g_timerUnfreeze[client]);
		g_timerUnfreeze[client] = null;
	} else {
		int entity = AttachGlowToPlayer(client, {47, 183, 250, 255});

		if(entity >= 0) {
			g_clientGlowId[client] = EntIndexToEntRef(entity);
		}
		
	}

	float origin[3];

	SetEntityMoveType(client, MOVETYPE_NONE);
	g_timerUnfreeze[client] = CreateTimer(4.0, timer_Unfreeze, client, TIMER_FLAG_NO_MAPCHANGE);

	GetClientAbsOrigin(client, origin);
	EmitAmbientSound("physics/glass/glass_strain2.wav", origin, client, SNDLEVEL_RAIDSIREN);
}

public Action timer_Unfreeze(Handle timer, any client) {
	if(IsPlayerAlive(client)) {
		float origin[3];
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		RemoveGlow(EntRefToEntIndex(g_clientGlowId[client]));

		GetClientAbsOrigin(client, origin);
		EmitAmbientSound("physics/glass/glass_bottle_break2.wav", origin, client, SNDLEVEL_RAIDSIREN);
	}

	g_timerUnfreeze[client] = null;
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