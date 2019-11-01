#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Chance to throw up", 
	author = "d0naciak", 
	description = "Skill: Chance to throw up", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToThrowUp[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeSkill[MAXPLAYERS+1];
float g_power[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_intMultiplier[MAXPLAYERS+1][CodD0_SkillSlot_Max];

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
	RegPluginLibrary("CodD0_skill_chanceToThrowUp");

	CreateNative("CodD0_SetClientChanceToThrowUp", nat_SetClientChanceToThrowUp);
	CreateNative("CodD0_GetClientChanceToThrowUp", nat_GetClientChanceToThrowUp);
}

public int nat_SetClientChanceToThrowUp(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), actSkillID = -1;

	g_chanceToThrowUp[client][skillID] = GetNativeCell(3);
	g_power[client][skillID] = view_as<float>(GetNativeCell(4));
	g_intMultiplier[client][skillID] = view_as<float>(GetNativeCell(5));

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToThrowUp[client][i] && (actSkillID == -1 || g_chanceToThrowUp[client][i] < g_chanceToThrowUp[client][actSkillID])) {
			actSkillID = i;
		}
	}

	g_activeSkill[client] = actSkillID;
}

public int nat_GetClientChanceToThrowUp(Handle plugin, int paramsNum) {
	return g_chanceToThrowUp[GetNativeCell(1)][GetNativeCell(2)];
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

	if (damageType & DMG_BULLET && g_activeSkill[attacker] != -1) {
		int skillID = g_activeSkill[attacker];

		if (GetRandomInt(1, g_chanceToThrowUp[attacker][skillID]) == 1) {
			float velocity[3];

			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", velocity);
			velocity[2] = g_power[attacker][skillID] + float(CodD0_GetClientUsableIntelligence(attacker)) * g_intMultiplier[attacker][skillID];
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
		}
	}
}