#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Burning", 
	author = "d0naciak", 
	description = "Skill: Burning", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToBurn[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToBurn[MAXPLAYERS+1];

int g_burnsNum[MAXPLAYERS+1];
Handle g_timerBurning[MAXPLAYERS+1];

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
	RegPluginLibrary("CodD0_skill_burning");

	CreateNative("CodD0_SetClientChanceToBurn", nat_SetClientChanceToBurn);
	CreateNative("CodD0_GetClientChanceToBurn", nat_GetClientChanceToBurn);
}

public int nat_SetClientChanceToBurn(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToBurn[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToBurn[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToBurn[client][i] && (!g_activeChanceToBurn[client] || g_chanceToBurn[client][i] < g_activeChanceToBurn[client])) {
			g_activeChanceToBurn[client] = g_chanceToBurn[client][i];
		}
	}
}

public int nat_GetClientChanceToBurn(Handle plugin, int paramsNum) {
	return g_chanceToBurn[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

	if (g_timerBurning[client] != null) {
		KillTimer(g_timerBurning[client]);
		g_timerBurning[client] = null;
	}
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if (damageType & DMG_BULLET && g_activeChanceToBurn[attacker] && GetRandomInt(1, g_activeChanceToBurn[attacker]) == 1) {
		g_burnsNum[victim] = 0;
		IgniteEntity(victim, 4.0);

		if(g_timerBurning[victim] == null) {
			DataPack dataPack;
			
			g_timerBurning[victim] = CreateDataTimer(0.5, timer_Burn, dataPack, TIMER_REPEAT);
			WritePackCell(dataPack, attacker);
			WritePackCell(dataPack, victim);
		}
	}
}

public void ev_Spawn_Post(int client) {
	if(IsPlayerAlive(client) && g_timerBurning[client] != null) {
		KillTimer(g_timerBurning[client]);
		g_timerBurning[client] = null;
	}
}

public Action timer_Burn(Handle hTimer, DataPack dataPack) {
	ResetPack(dataPack);
	int attacker = ReadPackCell(dataPack);
	int victim = ReadPackCell(dataPack);
	
	if(!IsClientInGame(victim) || !IsPlayerAlive(victim) || !IsClientInGame(attacker)) {
		g_timerBurning[victim] = null;
		return Plugin_Stop;
	}
	
	g_burnsNum[victim] ++;
	CodD0_InflictDamage(attacker, attacker, victim, 5.0, 0.03125, DMG_BURN, -1);
	
	if(g_burnsNum[victim] >= 8) {
		g_timerBurning[victim] = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}