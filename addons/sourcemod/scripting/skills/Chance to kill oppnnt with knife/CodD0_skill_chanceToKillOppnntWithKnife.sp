#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Chance to kill opponent with knife", 
	author = "d0naciak", 
	description = "Skill: Chance to kill opponent with knife", 
	version = "1.0", 
	url = "d0naciak.pl"
};

#define MAX_WEAPONS (view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES))
int g_chanceToKillOppnntWithKnife[MAXPLAYERS+1][CodD0_SkillSlot_Max][MAX_WEAPONS+1], g_actChanceToKillOppnntWithKnife[MAXPLAYERS+1][MAX_WEAPONS+1];

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
	RegPluginLibrary("CodD0_skill_chanceToKillOppnntWithKnife");

	CreateNative("CodD0_SetClientChanceToKillOppnntWithKnife", nat_SetClientChanceToKillOppnntWithKnife);
	CreateNative("CodD0_GetClientChanceToKillOppnntWithKnife", nat_GetClientChanceToKillOppnntWithKnife);
}

public int nat_SetClientChanceToKillOppnntWithKnife(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = GetNativeCell(3);

	g_chanceToKillOppnntWithKnife[client][GetNativeCell(2)][weaponID] = GetNativeCell(4);
	g_actChanceToKillOppnntWithKnife[client][weaponID] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToKillOppnntWithKnife[client][i][weaponID] && (!g_actChanceToKillOppnntWithKnife[client][weaponID] || g_chanceToKillOppnntWithKnife[client][i][weaponID] < g_actChanceToKillOppnntWithKnife[client][weaponID])) {
			g_actChanceToKillOppnntWithKnife[client][weaponID] = g_chanceToKillOppnntWithKnife[client][i][weaponID];
		}
	}
}

public int nat_GetClientChanceToKillOppnntWithKnife(Handle plugin, int paramsNum) {
	return g_chanceToKillOppnntWithKnife[GetNativeCell(1)][GetNativeCell(2)][GetNativeCell(3)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return Plugin_Continue;
	}

	if(damageType & DMG_BULLET && GetPlayerWeaponSlot(victim, CS_SLOT_KNIFE) == GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon")) {
		int weaponID = GetWeaponID(weapon);
		if(
			(g_actChanceToKillOppnntWithKnife[attacker][0] && GetRandomInt(1,g_actChanceToKillOppnntWithKnife[attacker][0]) == 1) ||
			(g_actChanceToKillOppnntWithKnife[attacker][weaponID] && GetRandomInt(1,g_actChanceToKillOppnntWithKnife[attacker][weaponID]) == 1)
		) {
			damage = float(GetClientHealth(victim) * 5);
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

int GetWeaponID(int weaponEnt) {
	CSWeaponID weaponId;

	weaponId = CS_ItemDefIndexToID(GetEntProp(weaponEnt, Prop_Send, "m_iItemDefinitionIndex"));

	if(_:weaponId < 0) {
		return 0;
	} else if(_:weaponId > MAX_WEAPONS || weaponId == CSWeapon_KNIFE_GG || weaponId == CSWeapon_KNIFE_T || weaponId == CSWeapon_KNIFE_GHOST) {
		return _:CSWeapon_KNIFE;
	}

	return _:weaponId;
}