#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Chance to enemy skin", 
	author = "d0naciak", 
	description = "Skill: Chance to enemy skin", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToEnemySkin[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToEnemySkin[MAXPLAYERS+1];
bool g_hooksRegistered[MAXPLAYERS+1];

public void OnMapStart() {
	PrecacheModel("models/player/ctm_idf.mdl");
	PrecacheModel("models/player/tm_phoenix.mdl");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_chanceToEnemySkin");

	CreateNative("CodD0_SetClientChanceToEnemySkin", nat_SetClientChanceToEnemySkin);
	CreateNative("CodD0_GetClientChanceToEnemySkin", nat_GetClientChanceToEnemySkin);
}

public int nat_SetClientChanceToEnemySkin(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToEnemySkin[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToEnemySkin[client] = 0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToEnemySkin[client][i] && (!g_activeChanceToEnemySkin[client] || g_chanceToEnemySkin[client][i] < g_activeChanceToEnemySkin[client])) {
			g_activeChanceToEnemySkin[client] = g_chanceToEnemySkin[client][i];
		}
	}

	if (g_activeChanceToEnemySkin[client]) {
		if (!g_hooksRegistered[client]) {
			SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooksRegistered[client] = true;
		}
	} else if (g_hooksRegistered[client]) {
		if (IsPlayerAlive(client)) {
			ChangeSkin(client, false);
		}

		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		g_hooksRegistered[client] = false;
	}
}

public int nat_GetClientChanceToEnemySkin(Handle plugin, int paramsNum) {
	return g_chanceToEnemySkin[GetNativeCell(1)][GetNativeCell(2)];
}

public void ev_Spawn_Post(int client) {
	if(IsPlayerAlive(client) && GetRandomInt(1, g_activeChanceToEnemySkin[client]) == 1) {
		ChangeSkin(client, true);
	}
}

void ChangeSkin(int client, bool replace) {
	switch(GetClientTeam(client)) {
		case 2: SetEntityModel(client, replace ? "models/player/ctm_idf.mdl" : "models/player/tm_phoenix.mdl");
		case 3: SetEntityModel(client, replace ? "models/player/tm_phoenix.mdl" : "models/player/ctm_idf.mdl");
	}
}