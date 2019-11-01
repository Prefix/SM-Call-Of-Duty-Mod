#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: No fall damage", 
	author = "d0naciak", 
	description = "Skill: No fall damage", 
	version = "1.0", 
	url = "d0naciak.pl"
};

bool g_noFallDamage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeNoFallDamage[MAXPLAYERS+1];

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
	RegPluginLibrary("CodD0_skill_noFallDamage");

	CreateNative("CodD0_SetClientNoFallDamage", nat_SetClientNoFallDamage);
	CreateNative("CodD0_GetClientNoFallDamage", nat_GetClientNoFallDamage);
}

public int nat_SetClientNoFallDamage(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_noFallDamage[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeNoFallDamage[client] = false;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_noFallDamage[client][i]) {
			g_activeNoFallDamage[client] = true;
			break;
		}
	}
}

public int nat_GetClientNoFallDamage(Handle plugin, int paramsNum) {
	return g_noFallDamage[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if(g_activeNoFallDamage[victim] && (attacker == 0 || attacker > MAXPLAYERS) && damageType & DMG_FALL) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}