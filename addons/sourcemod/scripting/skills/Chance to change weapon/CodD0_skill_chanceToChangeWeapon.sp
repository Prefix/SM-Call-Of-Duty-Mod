#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Chance to change weapon", 
	author = "d0naciak", 
	description = "Skill: Chance to change weapon", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToChangeWeapon[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToChangeWeapon[MAXPLAYERS+1];

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
	RegPluginLibrary("CodD0_skill_chanceToChangeWeapon");

	CreateNative("CodD0_SetClientChanceToChangeWeapon", nat_SetClientChanceToChangeWeapon);
	CreateNative("CodD0_GetClientChanceToChangeWeapon", nat_GetClientChanceToChangeWeapon);
}

public int nat_SetClientChanceToChangeWeapon(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToChangeWeapon[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToChangeWeapon[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToChangeWeapon[client][i] && (!g_activeChanceToChangeWeapon[client] || g_chanceToChangeWeapon[client][i] < g_activeChanceToChangeWeapon[client])) {
			g_activeChanceToChangeWeapon[client] = g_chanceToChangeWeapon[client][i];
		}
	}
}

public int nat_GetClientChanceToChangeWeapon(Handle plugin, int paramsNum) {
	return g_chanceToChangeWeapon[GetNativeCell(1)][GetNativeCell(2)];
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

	if(damageType & DMG_BULLET && g_activeChanceToChangeWeapon[attacker] && GetRandomInt(1,g_activeChanceToChangeWeapon[attacker]) == 1) {
		int victimKnife = GetPlayerWeaponSlot(victim, CS_SLOT_KNIFE);
		if(victimKnife > 0) {
			SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", victimKnife);
		}
	}
}