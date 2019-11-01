#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Visiblity", 
	author = "d0naciak", 
	description = "Visibility manager", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_visibility[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeVisibility[MAXPLAYERS+1];
int g_visibilityOnKnife[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeVisibilityOnKnife[MAXPLAYERS+1];
bool g_hooks[MAXPLAYERS+1], g_hooksOnKnife[MAXPLAYERS+1], g_isInvisible[MAXPLAYERS+1];

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_visibility[i][j] = 255;
			g_visibilityOnKnife[i][j] = 255;
		}

		g_activeVisibility[i] = 255;
		g_activeVisibilityOnKnife[i] = 255;
	}
}

public void OnConfigsExecuted() {
	static ConVar cvDisImmuAlpha;

	if (cvDisImmuAlpha == null) {
		cvDisImmuAlpha = FindConVar("sv_disable_immunity_alpha");
	}

	SetConVarInt(cvDisImmuAlpha, 1);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_visibility");

	CreateNative("CodD0_SetClientVisibility", nat_SetClientVisibility);
	CreateNative("CodD0_GetClientVisibility", nat_GetClientVisibility);

	CreateNative("CodD0_SetClientVisibilityOnKnife", nat_SetClientVisibilityOnKnife);
	CreateNative("CodD0_GetClientVisibilityOnKnife", nat_GetClientVisibilityOnKnife);
}

public void OnClientConnected(int client) {
	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		g_visibility[client][i] = 255;
		g_visibilityOnKnife[client][i] = 255;
	}

	g_activeVisibility[client] = 255;
	g_activeVisibilityOnKnife[client] = 255;
}

public int nat_SetClientVisibility(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_visibility[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeVisibility[client] = 255;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_activeVisibility[client] > g_visibility[client][i]) {
			g_activeVisibility[client] = g_visibility[client][i];
		}
	}

	if (!g_hooks[client]) {
		if(g_activeVisibility[client] < 255) {
			SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooks[client] = true;
		}
	} else {
		if(g_activeVisibility[client] >= 255) {
			SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooks[client] = false;
		}
	}

	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		SetRendering(client, GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") ? true : false);
	}
}

public int nat_GetClientVisibility(Handle plugin, int paramsNum) {
	return g_visibility[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientVisibilityOnKnife(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_visibilityOnKnife[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeVisibilityOnKnife[client] = 255;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_activeVisibilityOnKnife[client] > g_visibilityOnKnife[client][i]) {
			g_activeVisibilityOnKnife[client] = g_visibilityOnKnife[client][i];
		}
	}

	if (!g_hooksOnKnife[client]) {
		if(g_activeVisibilityOnKnife[client] < 255) {
			SDKHook(client, SDKHook_WeaponSwitchPost, ev_WeaponSwitch_Post);
			SDKHook(client, SDKHook_PostThinkPost, ev_OnPostThink_Post);
			g_hooksOnKnife[client] = true;
		}
	} else {
		if(g_activeVisibilityOnKnife[client] >= 255) {
			SDKUnhook(client, SDKHook_WeaponSwitchPost, ev_WeaponSwitch_Post);
			SDKUnhook(client, SDKHook_PostThinkPost, ev_OnPostThink_Post);
			g_hooksOnKnife[client] = false;
			g_isInvisible[client] = false;
		}
	}

	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		SetRendering(client, GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") ? true : false);
	}
}

public int nat_GetClientVisibilityOnKnife(Handle plugin, int paramsNum) {
	return g_visibilityOnKnife[GetNativeCell(1)][GetNativeCell(2)];
}

public void ev_Spawn_Post(int client) {
	if(IsPlayerAlive(client)) {
		SetRendering(client, GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") ? true : false);
	}
}

public void ev_WeaponSwitch_Post(int client, int weaponEnt) {
	if (!IsValidEntity(weaponEnt)) {
		return;
	}

	if(GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weaponEnt) {
		SetRendering(client, true);
		int worldModel = GetEntPropEnt(weaponEnt, Prop_Send, "m_hWeaponWorldModel"); 

		if(worldModel > 0) {
			SetEntProp(worldModel, Prop_Send, "m_nModelIndex", -1);
		}

		g_isInvisible[client] = true;
	} else {
		SetRendering(client, false);
		g_isInvisible[client] = false;
	}
}

public void ev_OnPostThink_Post(int client) {
	if(!g_isInvisible[client]) {
		return;
	}

	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

void SetRendering(int client, bool hasKnife) {
	int visibility = g_activeVisibility[client];

	if(hasKnife && g_activeVisibilityOnKnife[client] < g_activeVisibility[client]) {
		visibility = g_activeVisibilityOnKnife[client];
	}

	if(visibility < 255) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, visibility);
	} else {
		SetEntityRenderMode(client, RENDER_NORMAL);
	}
}