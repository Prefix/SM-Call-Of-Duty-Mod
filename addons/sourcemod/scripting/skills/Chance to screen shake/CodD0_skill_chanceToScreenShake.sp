#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Chance to screen shake", 
	author = "d0naciak", 
	description = "Skill: Chance to screen shake", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToScreenShake[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToScreenShake[MAXPLAYERS+1];

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
	RegPluginLibrary("CodD0_skill_chanceToScreenShake");

	CreateNative("CodD0_SetClientChanceToScreenShake", nat_SetClientChanceToScreenShake);
	CreateNative("CodD0_GetClientChanceToScreenShake", nat_GetClientChanceToScreenShake);
}

public int nat_SetClientChanceToScreenShake(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToScreenShake[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToScreenShake[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToScreenShake[client][i] && (!g_activeChanceToScreenShake[client] || g_chanceToScreenShake[client][i] < g_activeChanceToScreenShake[client])) {
			g_activeChanceToScreenShake[client] = g_chanceToScreenShake[client][i];
		}
	}
}

public int nat_GetClientChanceToScreenShake(Handle plugin, int paramsNum) {
	return g_chanceToScreenShake[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if(damageType & DMG_BULLET && g_activeChanceToScreenShake[attacker] && GetRandomInt(1,g_activeChanceToScreenShake[attacker]) == 1) {
		Shake(victim, 10.0);
	}
}

stock void Shake(int client, float Amp=1.0) {
	Handle message = StartMessageOne("Shake", client, 1);
	PbSetInt(message, "command", 0);
	PbSetFloat(message, "local_amplitude", Amp);
	PbSetFloat(message, "frequency", 100.0);
	PbSetFloat(message, "duration", 1.5);
	EndMessage();
}