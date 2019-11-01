#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

#define HIT_HEAD 1

public Plugin myinfo =  {
	name = "COD d0 Skill: Bonuses for damage", 
	author = "d0naciak", 
	description = "Skill: Bonuses for damage", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_healthForHeadshot[MAXPLAYERS+1];
float g_healthPerDmgMultiplier[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actHealthPerDmgMultiplier[MAXPLAYERS+1];

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
	RegPluginLibrary("CodD0_skill_bonusesForDamage");

	CreateNative("CodD0_SetClientHealthForHeadShot", nat_SetClientHealthForHeadShot);
	CreateNative("CodD0_GetClientHealthForHeadShot", nat_GetClientHealthForHeadShot);

	CreateNative("CodD0_SetClientHealthPerDmgMulti", nat_SetClientHealthPerDmgMulti);
	CreateNative("CodD0_GetClientHealthPerDmgMulti", nat_GetClientHealthPerDmgMulti);
}

public int nat_SetClientHealthForHeadShot(Handle plugin, int paramsNum) {
	g_healthForHeadshot[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_GetClientHealthForHeadShot(Handle plugin, int paramsNum) {
	return g_healthForHeadshot[GetNativeCell(1)];
}

public int nat_SetClientHealthPerDmgMulti(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_healthPerDmgMultiplier[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_actHealthPerDmgMultiplier[client] = 0.0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_healthPerDmgMultiplier[client][i] > g_actHealthPerDmgMultiplier[client]) {
			g_actHealthPerDmgMultiplier[client] = g_healthPerDmgMultiplier[client][i];
		}
	}
}

public int nat_GetClientHealthPerDmgMulti(Handle plugin, int paramsNum) {
	return view_as<int>(g_healthPerDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)]);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKHook(client, SDKHook_TraceAttackPost, ev_TraceAttack_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamagePost, ev_OnTakeDamage_Post);
	SDKUnhook(client, SDKHook_TraceAttackPost, ev_TraceAttack_Post);
}

public void ev_OnTakeDamage_Post(int victim, int attacker, int ent, float damage, int damageType, int weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}

	if(damageType & DMG_BULLET && g_actHealthPerDmgMultiplier[attacker]) {
		SetEntityHealth(attacker, GetLower(GetClientHealth(attacker) + RoundFloat(g_actHealthPerDmgMultiplier[attacker] * damage), 100 + CodD0_GetAllClientStatsPoints(attacker, HEALTH_PTS)));
	}
}

public void ev_TraceAttack_Post(int victim, int attacker, int ent, float damage, int damageType, int ammoType, int hitbox, int hitgroup) {
	if(!attacker || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return;
	}
	
	if(damageType & DMG_BULLET && hitgroup == HIT_HEAD) {
		if (g_healthForHeadshot[attacker]) {
			SetEntityHealth(attacker, GetLower(GetClientHealth(attacker) + g_healthForHeadshot[attacker], 100 + CodD0_GetAllClientStatsPoints(attacker, HEALTH_PTS)));
		}
	}
}

int GetLower(int val1, int val2) {
	if(val1 < val2) {
		return val1;
	}

	return val2;
}