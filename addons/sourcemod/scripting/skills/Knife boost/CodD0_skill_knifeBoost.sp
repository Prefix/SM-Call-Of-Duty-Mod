#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Knife boost", 
	author = "d0naciak", 
	description = "Skill: Knife boost", 
	version = "1.0", 
	url = "d0naciak.pl"
};

float g_speed[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actSpeed[MAXPLAYERS+1];
bool g_hooksRegistered[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_knifeBoost");

	CreateNative("CodD0_SetClientKnifeBoost", nat_SetClientKnifeBoost);
	CreateNative("CodD0_GetClientKnifeBoost", nat_GetClientKnifeBoost);
}

public int nat_SetClientKnifeBoost(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_speed[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_actSpeed[client] = 1.0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_speed[client][i] > g_actSpeed[client]) {
			g_actSpeed[client] = g_speed[client][i];
		}
	}

	if (g_actSpeed[client] > 1.0) {
		if (!g_hooksRegistered[client]) {
			SDKHook(client, SDKHook_WeaponSwitchPost, ev_WeaponSwitch_Post);
			g_hooksRegistered[client] = true;
		}
	} else if (g_hooksRegistered[client]) {
		SDKUnhook(client, SDKHook_WeaponSwitchPost, ev_WeaponSwitch_Post);

		if(IsClientInGame(client)) {
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		}

		g_hooksRegistered[client] = false;
	}
}

public int nat_GetClientKnifeBoost(Handle plugin, int paramsNum) {
	return view_as<int>(g_speed[GetNativeCell(1)][GetNativeCell(2)]);
}


public ev_WeaponSwitch_Post(int client, int weaponEnt) {
	if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weaponEnt) {
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_actSpeed[client]);
	} else {
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 + float(CodD0_GetClientBonusStatsPoints(client, SPEED_PTS)) * 0.0005);
	}
}