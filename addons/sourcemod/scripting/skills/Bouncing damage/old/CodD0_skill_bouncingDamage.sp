#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Bouncing damage", 
	author = "d0naciak", 
	description = "Skill: Bouncing damage", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToBounceBullet[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToBounceBullet[MAXPLAYERS+1];
bool g_hooks[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_bouncingDamage");

	CreateNative("CodD0_SetClientChanceToBounceBullet", nat_SetClientChanceToBounceBullet);
	CreateNative("CodD0_GetClientChanceToBounceBullet", nat_GetClientChanceToBounceBullet);
}

public int nat_SetClientChanceToBounceBullet(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToBounceBullet[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToBounceBullet[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToBounceBullet[client][i] && (!g_activeChanceToBounceBullet[client] || g_chanceToBounceBullet[client][i] < g_activeChanceToBounceBullet[client])) {
			g_activeChanceToBounceBullet[client] = g_chanceToBounceBullet[client][i];
		}
	}

	if (!g_hooks[client]) {
		if(g_activeChanceToBounceBullet[client]) {
			SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
			g_hooks[client] = true;
		}
	} else {
		if(!g_activeChanceToBounceBullet[client]) {
			SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
			g_hooks[client] = false;
		}
	}
}

public int nat_GetClientChanceToBounceBullet(Handle plugin, int paramsNum) {
	return g_chanceToBounceBullet[GetNativeCell(1)][GetNativeCell(2)];
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return Plugin_Continue;
	}

	if (damageType & DMG_BULLET && GetRandomInt(1,g_activeChanceToBounceBullet[victim]) == 1) {
		if (!g_activeChanceToBounceBullet[attacker]) {
			SDKHooks_TakeDamage(attacker, victim, victim, damage, (1<<1), -1, NULL_VECTOR, NULL_VECTOR);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}