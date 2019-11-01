#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Blinding", 
	author = "d0naciak", 
	description = "Skill: Blinding", 
	version = "1.0", 
	url = "d0naciak.pl"
};

bool g_noFlash[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeNoFlash[MAXPLAYERS+1];
int g_chanceToBlind[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeChanceToBlind[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("player_blind", ev_PlayerBlind, EventHookMode_Pre);

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
	RegPluginLibrary("CodD0_skill_blinding");

	CreateNative("CodD0_SetClientNoFlash", nat_SetClientNoFlash);
	CreateNative("CodD0_GetClientNoFlash", nat_GetClientNoFlash);

	CreateNative("CodD0_SetClientChanceToBlind", nat_SetClientChanceToBlind);
	CreateNative("CodD0_GetClientChanceToBlind", nat_GetClientChanceToBlind);
}

public int nat_SetClientNoFlash(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_noFlash[client][GetNativeCell(2)] = GetNativeCell(3);

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_noFlash[client][i]) {
			g_activeNoFlash[client] = true;
			return;
		}
	}

	g_activeNoFlash[client] = false;
}

public int nat_GetClientNoFlash(Handle plugin, int paramsNum) {
	return g_noFlash[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientChanceToBlind(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_chanceToBlind[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeChanceToBlind[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_chanceToBlind[client][i] && (!g_activeChanceToBlind[client] || g_chanceToBlind[client][i] < g_activeChanceToBlind[client])) {
			g_activeChanceToBlind[client] = g_chanceToBlind[client][i];
		}
	}
}

public int nat_GetClientChanceToBlind(Handle plugin, int paramsNum) {
	return g_chanceToBlind[GetNativeCell(1)][GetNativeCell(2)];
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

	if(damageType & DMG_BULLET && g_activeChanceToBlind[attacker] && GetRandomInt(1,g_activeChanceToBlind[attacker]) == 1) {
		Fade(victim, 750, 300, 0x0001, {255, 255, 255, 255});
	}
}

public Action ev_PlayerBlind(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !g_activeNoFlash[client] || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	return Plugin_Continue;
}


void Fade(client, duration, hold_time, flags, const colors[4]) {
	Handle message = StartMessageOne("Fade", client, 1);
	PbSetInt(message, "duration", duration);
	PbSetInt(message, "hold_time", hold_time);
	PbSetInt(message, "flags", flags);
	PbSetColor(message, "clr", colors);
	EndMessage();
}