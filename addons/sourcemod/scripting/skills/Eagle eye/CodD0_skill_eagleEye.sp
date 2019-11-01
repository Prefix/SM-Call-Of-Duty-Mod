#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

#define EF_BONEMERGE				(1 << 0)
#define EF_NOSHADOW				 (1 << 4)
#define EF_NORECEIVESHADOW		  (1 << 6)

public Plugin myinfo =  {
	name = "COD d0 Skill: Eagle eye", 
	author = "d0naciak", 
	description = "Skill: Eagle eye", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_eyesNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_eyesNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_time[MAXPLAYERS+1][CodD0_SkillSlot_Max];

Handle g_eyeTimer[MAXPLAYERS+1];
int g_playerGlowID[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
	HookEvent("player_death", ev_PlayerDeath_Post);

	for (int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientDisconnect(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_eagleEye");

	CreateNative("CodD0_SetClientEagleEye", nat_SetClientEagleEye);
	CreateNative("CodD0_GetClientEagleEye", nat_GetClientEagleEye);
	CreateNative("CodD0_UseEagleEye", nat_UseEagleEye);
}

public int nat_SetClientEagleEye(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_eyesNum[client][skillID] = g_eyesNumInRound[client][skillID] = GetNativeCell(3);
	g_time[client][skillID] = view_as<float>(GetNativeCell(4));
}

public int nat_GetClientEagleEye(Handle plugin, int paramsNum) {
	return g_eyesNum[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
	
	if(g_playerGlowID[client]) {
		RemoveGlow(EntRefToEntIndex(g_playerGlowID[client]));
	}

	if(g_eyeTimer[client] != null) {
		KillTimer(g_eyeTimer[client]);
		g_eyeTimer[client] = null;
	}
}

public void ev_Spawn_Post(int client) {
	if (!IsPlayerAlive(client)) {
		return;
	}

	if(g_eyeTimer[client] != null) {
		KillTimer(g_eyeTimer[client]);
		g_eyeTimer[client] = null;
	}

	if(g_playerGlowID[client]) {
		RemoveGlow(EntRefToEntIndex(g_playerGlowID[client]));
	}

	g_playerGlowID[client] = EntIndexToEntRef(AttachGlowToPlayer(client, {255, 0, 0, 255}));
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_eyesNumInRound[i][j] = g_eyesNum[i][j];
		}
	}
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && g_playerGlowID[client]) {
		RemoveGlow(EntRefToEntIndex(g_playerGlowID[client]));
	}
}



public int nat_UseEagleEye(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_eyesNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz już więcej sokolich oczu!");
		return CodD0_SkillPrep_Fail;
	}

	if(g_eyeTimer[client] != null) {
		KillTimer(g_eyeTimer[client]);
		g_eyeTimer[client] = null;

		PrintCenterText(client, "Oko sokoła zostało DEZAKTYWOWANE.");

		return CodD0_SkillPrep_Fail;
	}

	g_eyeTimer[client] = CreateTimer(g_time[client][skillID], timer_EndOfEagleEye, client);
	PrintCenterText(client, "Oko sokoła zostało AKTYWOWANE");

	return --g_eyesNumInRound[client][skillID] > 0 ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public Action timer_EndOfEagleEye(Handle timer, any client) {
	g_eyeTimer[client] = null;

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && g_playerGlowID[i]) {
			RemoveGlow(EntRefToEntIndex(g_playerGlowID[i]));
			g_playerGlowID[i] = EntIndexToEntRef(AttachGlowToPlayer(i, {255, 0, 0, 255}));
		}
	}

	PrintCenterText(client, "Oko sokoła zostało DEZAKTYWOWANE.");
}

int AttachGlowToPlayer(int client, const int iColors[4]) {
	int entity = CreateEntityByName("prop_dynamic_glow");

	if(entity == -1) {
		return -1;
	}

	char szModel[256];

	GetClientModel(client, szModel, sizeof(szModel));

	DispatchKeyValue(entity, "model", szModel);
	DispatchKeyValue(entity, "solid", "0");
	DispatchKeyValue(entity, "fademindist", "1");
	DispatchKeyValue(entity, "fademaxdist", "1");
	DispatchKeyValue(entity, "fadescale", "2.0");
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(entity);
	SetEntityRenderMode(entity, RENDER_GLOW);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client, entity);
	SetVariantString("primary");
	AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
	SetVariantString("OnUser1 !self:Kill::0.1:-1");
	AcceptEntityInput(entity, "AddOutput");

	static int iOffset;

	if (!iOffset && (iOffset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1) {
		AcceptEntityInput(entity, "FireUser1");
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return -1;
	}

	// Enable glow for custom skin
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 999999.0);

	// So now setup given glow colors for the skin
	for(int i=0;i<3;i++) {
		SetEntData(entity, iOffset + i, iColors[i], _, true); 
	}

	SDKHookEx(entity, SDKHook_SetTransmit, ev_SetTransmit);
	return entity;
}
    
public Action ev_SetTransmit(int entity, int client) {
    if(g_eyeTimer[client] == null/* || g_playerGlowID[client] == EntIndexToEntRef(entity)*/) {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void RemoveGlow(int entity) {
	if(entity != INVALID_ENT_REFERENCE) {
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", false);
		AcceptEntityInput(entity, "FireUser1");
	}
}