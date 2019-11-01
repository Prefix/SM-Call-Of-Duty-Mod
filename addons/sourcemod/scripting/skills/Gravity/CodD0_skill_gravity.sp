#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Gravity", 
	author = "d0naciak", 
	description = "Skill: Gravity", 
	version = "1.0", 
	url = "d0naciak.pl"
};

float g_gravity[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actGravity[MAXPLAYERS+1];
bool g_hooks[MAXPLAYERS+1];

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_gravity[i][j] = 1.0;
		}

		g_actGravity[i] = 1.0;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_gravity");

	CreateNative("CodD0_SetClientGravity", nat_SetClientGravity);
	CreateNative("CodD0_GetClientGravity", nat_GetClientGravity);
}

public int nat_SetClientGravity(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_gravity[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_actGravity[client] = 1.0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_gravity[client][i] < g_actGravity[client]) {
			g_actGravity[client] = g_gravity[client][i];
		}
	}

	if (IsClientInGame(client)) {
		SetEntityGravity(client, g_actGravity[client]);
	}

	if (!g_hooks[client]) {
		if(g_actGravity[client] < 1.0) {
			SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooks[client] = true;
		}
	} else if(g_actGravity[client] >= 1.0) { 
		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		g_hooks[client] = false;
	}
}

public int nat_GetClientGravity(Handle plugin, int paramsNum) {
	return view_as<int>(g_gravity[GetNativeCell(1)][GetNativeCell(2)]);
}

public void ev_Spawn_Post(int client) {
	if (IsPlayerAlive(client)) {
		SetEntityGravity(client, g_actGravity[client]);
	}
}