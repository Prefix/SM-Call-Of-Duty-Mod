#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Mutli weapons", 
	author = "d0naciak", 
	description = "Skill: Mutli weapons", 
	version = "1.0", 
	url = "d0naciak.pl"
};

CSWeaponID g_weapon[MAXPLAYERS+1][2][2];
int g_lastWeaponClip[MAXPLAYERS+1][2];

int g_offset_clip1;
bool g_hooksRegistered[MAXPLAYERS+1];

public void OnPluginStart() {
	if((g_offset_clip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) == -1) {
		SetFailState("Can't find offset: m_iClip1");
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_multiWeapons");

	CreateNative("CodD0_SetClientMultiWeapon", nat_SetClientMultiWeapon);
	CreateNative("CodD0_GetClientMultiWeapon", nat_GetClientMultiWeapon);
	CreateNative("CodD0_ChangeClientWeapon", nat_ChangeClientWeapon);
}

//client, slot, first/second, weaponID
public int nat_SetClientMultiWeapon(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), slot = GetNativeCell(2), whichWeapon = GetNativeCell(3);

	g_weapon[client][slot][whichWeapon] = view_as<CSWeaponID>(GetNativeCell(4));
	g_lastWeaponClip[client][slot] = -1;

	if (g_weapon[client][slot][whichWeapon] != CSWeapon_NONE) {
		if (!g_hooksRegistered[client]) {
			SDKHook(client, SDKHook_WeaponEquip, ev_WeaponEquip);
			g_hooksRegistered[client] = true;
		}
	} else if (g_hooksRegistered[client]) {
		SDKUnhook(client, SDKHook_WeaponEquip, ev_WeaponEquip);
		g_hooksRegistered[client] = false;
	}
}

public int nat_GetClientMultiWeapon(Handle plugin, int paramsNum) {
	return view_as<int>(g_weapon[GetNativeCell(1)][GetNativeCell(2)][GetNativeCell(3)]);
}

public int nat_ChangeClientWeapon(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), slot = GetNativeCell(2), weaponEnt = GetPlayerWeaponSlot(client, slot);

	if(weaponEnt != GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")) {
		return view_as<int>(false);
	}

	char weaponName[64], weaponAlias[32];
	CSWeaponID weaponID = CS_ItemDefIndexToID(GetEntProp(weaponEnt, Prop_Send, "m_iItemDefinitionIndex"));
	int clip = GetEntData(weaponEnt, g_offset_clip1, 4);

	RemovePlayerItem(client, weaponEnt);
	AcceptEntityInput(weaponEnt, "kill");

	if(weaponID == g_weapon[client][slot][0]) {
		CS_WeaponIDToAlias(g_weapon[client][slot][1], weaponAlias, sizeof(weaponAlias));
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponAlias);
	} else {
		CS_WeaponIDToAlias(g_weapon[client][slot][0], weaponAlias, sizeof(weaponAlias));
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponAlias);
	}

	weaponEnt = GivePlayerItem(client, weaponName);
	if(weaponEnt > 0 && g_lastWeaponClip[client][slot] != -1) {
		SetEntData(weaponEnt, g_offset_clip1, g_lastWeaponClip[client][slot], 4, true);
	}
	g_lastWeaponClip[client][slot] = clip;

	return view_as<int>(true);
}

public Action ev_WeaponEquip(int client, int weaponEnt) {
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}

	for(int i = 0; i < 2; i++) {
		if(g_weapon[client][i][0] == CSWeapon_NONE || GetPlayerWeaponSlot(client, i) <= 0) {
			continue;
		}

		CSWeaponID weaponID = CS_ItemDefIndexToID(GetEntProp(weaponEnt, Prop_Send, "m_iItemDefinitionIndex"));

		if(weaponID == g_weapon[client][i][0] || weaponID == g_weapon[client][i][1]) {
			g_lastWeaponClip[client][i] = -1;
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}