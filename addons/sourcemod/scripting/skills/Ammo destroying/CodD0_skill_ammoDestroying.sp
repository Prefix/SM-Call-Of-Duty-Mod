#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Ammo destroying", 
	author = "d0naciak", 
	description = "Skill: Ammo destroying", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_chanceToDestroyClip[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToDestroyClip[MAXPLAYERS+1];
int g_numsOfClipDestroyers[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_numsOfClipDestroyersInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_offset_clip1;

public void OnPluginStart() {
	HookEvent("round_poststart", ev_RoundPostStart_Post);
	if((g_offset_clip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) == -1) {
		SetFailState("Can't find offset: m_iClip1");
	}

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
	RegPluginLibrary("CodD0_skill_ammoDestroying");

	CreateNative("CodD0_SetClientChanceToDestroyClip", nat_SetClientChanceToDestroyClip);
	CreateNative("CodD0_GetClientChanceToDestroyClip", nat_GetClientChanceToDestroyClip);

	CreateNative("CodD0_SetClientClipDestroyers", nat_SetClientClipDestroyers);
	CreateNative("CodD0_GetClientClipDestroyers", nat_GetClientClipDestroyers);
	CreateNative("CodD0_UseClipDestroyer", nat_UseClipDestroyer);
}

public int nat_SetClientChanceToDestroyClip(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToDestroyClip[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToDestroyClip[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToDestroyClip[client][i] && (!g_activeChanceToDestroyClip[client] || g_chanceToDestroyClip[client][i] < g_activeChanceToDestroyClip[client])) {
			g_activeChanceToDestroyClip[client] = g_chanceToDestroyClip[client][i];
		}
	}
}

public int nat_GetClientChanceToDestroyClip(Handle plugin, int paramsNum) {
	return g_chanceToDestroyClip[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientClipDestroyers(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);
	g_numsOfClipDestroyers[client][skillID] = g_numsOfClipDestroyersInRound[client][skillID] = GetNativeCell(3);
}

public int nat_GetClientClipDestroyers(Handle plugin, int paramsNum) {
	return g_numsOfClipDestroyers[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseClipDestroyer(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), target = GetClientAimTarget(client, true);

	if (!g_numsOfClipDestroyersInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej niszczenia amunicji!");
		return CodD0_SkillPrep_Fail;
	}

	if (target <= 0 || !IsPlayerAlive(target) || GetClientTeam(client) == GetClientTeam(target)) {
		return CodD0_SkillPrep_Fail;
	}

	if (!RemoveAmmo(target)) {
		return CodD0_SkillPrep_Fail;
	}

	return --g_numsOfClipDestroyersInRound[client][skillID] ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
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

	if(damageType & DMG_BULLET && g_activeChanceToDestroyClip[attacker] && GetRandomInt(1,g_activeChanceToDestroyClip[attacker]) == 1) {
		RemoveAmmo(victim);
	}
}

public void ev_RoundPostStart_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_numsOfClipDestroyers[i][j] = g_numsOfClipDestroyersInRound[i][j];
		}
	}
}

bool RemoveAmmo(int client) {
	int weaponEnt = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(!IsValidEntity(weaponEnt)) {
		return false;
	}

	int clip = GetEntData(weaponEnt, g_offset_clip1, 4);

	if(clip > 100 || clip <= 0) {
		return false;
	}

	SetEntData(weaponEnt, g_offset_clip1, 0, 4, true);
	return true;
}