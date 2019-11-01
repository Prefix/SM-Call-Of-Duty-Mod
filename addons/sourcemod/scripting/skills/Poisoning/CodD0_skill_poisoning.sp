#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

#define EF_BONEMERGE				(1 << 0)
#define EF_NOSHADOW				 	(1 << 4)
#define EF_NORECEIVESHADOW		  	(1 << 6)

public Plugin myinfo =  {
	name = "COD d0 Skill: Poisoning", 
	author = "d0naciak", 
	description = "Skill: Poisoning", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_offset_thrower;

int g_chanceToPoison[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToPoison[MAXPLAYERS+1];
bool g_poisoningSmokes[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activePoisoningSmokes[MAXPLAYERS+1];

int g_posionsNum[MAXPLAYERS+1], g_clientGlowId[MAXPLAYERS+1];
Handle g_timerPoisoning[MAXPLAYERS+1];

public void OnPluginStart() {
	g_offset_thrower = FindSendPropInfo("CBaseGrenade", "m_hThrower");
	if (g_offset_thrower == -1) {
		SetFailState("Can't find m_hThrower offset");
	}

	HookEvent("smokegrenade_detonate", ev_SmokeGrenadeDetonate_Post);

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
	RegPluginLibrary("CodD0_skill_poisoning");

	CreateNative("CodD0_SetClientChanceToPoison", nat_SetClientChanceToPoison);
	CreateNative("CodD0_GetClientChanceToPoison", nat_GetClientChanceToPoison);

	CreateNative("CodD0_SetClientPoisoningSmokes", nat_SetClientPoisoningSmokes);
	CreateNative("CodD0_GetClientPoisoningSmokes", nat_GetClientPoisoningSmokes);
}

public int nat_SetClientChanceToPoison(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToPoison[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToPoison[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToPoison[client][i] && (!g_activeChanceToPoison[client] || g_chanceToPoison[client][i] < g_activeChanceToPoison[client])) {
			g_activeChanceToPoison[client] = g_chanceToPoison[client][i];
		}
	}
}

public int nat_GetClientChanceToPoison(Handle plugin, int paramsNum) {
	return g_chanceToPoison[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientPoisoningSmokes(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_poisoningSmokes[client][GetNativeCell(2)] = view_as<bool>(GetNativeCell(3));
	g_activePoisoningSmokes[client] = false;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_poisoningSmokes[client][i]) {
			g_activePoisoningSmokes[client] = true;
			break;
		}
	}
}

public int nat_GetClientPoisoningSmokes(Handle plugin, int paramsNum) {
	return view_as<int>(g_poisoningSmokes[GetNativeCell(1)][GetNativeCell(2)]);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

	if (g_timerPoisoning[client] != null) {
		KillTimer(g_timerPoisoning[client]);
		g_timerPoisoning[client] = null;
	}
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if (damageType & DMG_BULLET && g_activeChanceToPoison[attacker] && GetRandomInt(1, g_activeChanceToPoison[attacker]) == 1) {
		Poison(victim, attacker, 16, 0.1, 1.0, 0.025);
	}
}

public void ev_SmokeGrenadeDetonate_Post(Handle event, const char[] name, bool dontBroadcast) {
	int thrower = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!thrower || !g_activePoisoningSmokes[thrower]) {
		return;
	}

	int entity = GetEventInt(event, "entityid");
	CreateTimer(0.1, timer_FindPlayersToPoison, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action timer_FindPlayersToPoison(Handle timer, any entityRef) {
	int entity = EntRefToEntIndex(entityRef);

	if(entity == INVALID_ENT_REFERENCE) {
		return Plugin_Stop;
	}

	float position[2][3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position[0]);
	int thrower = GetEntDataEnt2(entity, g_offset_thrower);
	
	if(!thrower || !IsClientInGame(thrower)) {
		return Plugin_Stop;
	}

	int team = GetClientTeam(thrower);

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || team == GetClientTeam(i)) {
			continue;
		}

		GetClientAbsOrigin(i, position[1]);

		if(GetVectorDistance(position[0], position[1]) <= 220.0) {
			Poison(i, thrower, 5, 0.25, 2.0, 0.05);
		}
	}

	return Plugin_Continue;
}

public void ev_Spawn_Post(int client) {
	if (IsPlayerAlive(client) && g_timerPoisoning[client] != null) {
		KillTimer(g_timerPoisoning[client]);
		g_timerPoisoning[client] = null;
	}
}

void Poison(int victim, int attacker, int poisons, float time, float damage, float damagePerInt) {
	g_posionsNum[victim] = poisons;

	if (g_timerPoisoning[victim] == null) {
		DataPack dataPack;

		int entity = AttachGlowToPlayer(victim, {157, 29, 171, 255});
		if(entity >= 0) {
			g_clientGlowId[victim] = EntIndexToEntRef(entity);
		}

		g_timerPoisoning[victim] = CreateDataTimer(time, timer_Poison, dataPack, TIMER_REPEAT);
		WritePackCell(dataPack, attacker);
		WritePackCell(dataPack, victim);
		WritePackCell(dataPack, view_as<int>(damage));
		WritePackCell(dataPack, view_as<int>(damagePerInt));
	}
}

public Action timer_Poison(Handle hTimer, DataPack dataPack) {
	ResetPack(dataPack);
	int attacker = ReadPackCell(dataPack);
	int victim = ReadPackCell(dataPack);
	float damage = view_as<float>(ReadPackCell(dataPack));
	float damagePerInt = view_as<float>(ReadPackCell(dataPack));
	
	if(!IsClientInGame(victim) || !IsPlayerAlive(victim) || !IsClientInGame(attacker)) {
		g_timerPoisoning[victim] = null;
		return Plugin_Stop;
	}
	
	CodD0_InflictDamage(attacker, attacker, victim, damage, damagePerInt, DMG_POISON, -1);
	
	if(!(--g_posionsNum[victim])) {
		RemoveGlow(EntRefToEntIndex(g_clientGlowId[victim]));
		g_timerPoisoning[victim] = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
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