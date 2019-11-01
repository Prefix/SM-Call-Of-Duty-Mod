#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_unlimitedAmmo>

#define MAX_WEAPONS (view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES))

public Plugin myinfo =  {
	name = "COD d0 Skill: Bonuses for frags", 
	author = "d0naciak", 
	description = "Skill: Bonuses for frags", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_offset_clip1;
int g_weaponMaxClip[MAX_WEAPONS + 1]

int g_healthForFrag[MAXPLAYERS+1];
int g_expForFrag[MAXPLAYERS+1];
int g_coinsForFrag[MAXPLAYERS+1];
int g_ammoForFrag[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("player_death", ev_PlayerDeath_Post);
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

public void OnMapStart() {
	CreateTimer(0.1, timer_Reset);
}

public Action timer_Reset(Handle timer) {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			g_healthForFrag[i] = 0;
			g_expForFrag[i] = 0;
			g_coinsForFrag[i] = 0;
			g_ammoForFrag[i] = 0;
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_bonusesForFrags");

	CreateNative("CodD0_SetClientHealthForFrag", nat_SetClientHealthForFrag);
	CreateNative("CodD0_GetClientHealthForFrag", nat_GetClientHealthForFrag);

	CreateNative("CodD0_SetClientExpForFrag", nat_SetClientExpForFrag);
	CreateNative("CodD0_GetClientExpForFrag", nat_GetClientExpForFrag);

	CreateNative("CodD0_SetClientCoinsForFrag", nat_SetClientCoinsForFrag);
	CreateNative("CodD0_GetClientCoinsForFrag", nat_GetClientCoinsForFrag);

	CreateNative("CodD0_SetClientAmmoForFrag", nat_SetClientAmmoForFrag);
	CreateNative("CodD0_GetClientAmmoForFrag", nat_GetClientAmmoForFrag);
}

public int nat_SetClientHealthForFrag(Handle plugin, int paramsNum) {
	g_healthForFrag[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_GetClientHealthForFrag(Handle plugin, int paramsNum) {
	return g_healthForFrag[GetNativeCell(1)];
}

public int nat_SetClientExpForFrag(Handle plugin, int paramsNum) {
	g_expForFrag[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_GetClientExpForFrag(Handle plugin, int paramsNum) {
	return g_expForFrag[GetNativeCell(1)];
}

public int nat_SetClientCoinsForFrag(Handle plugin, int paramsNum) {
	g_coinsForFrag[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_GetClientCoinsForFrag(Handle plugin, int paramsNum) {
	return g_coinsForFrag[GetNativeCell(1)];
}

public int nat_SetClientAmmoForFrag(Handle plugin, int paramsNum) {
	g_ammoForFrag[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_GetClientAmmoForFrag(Handle plugin, int paramsNum) {
	return g_ammoForFrag[GetNativeCell(1)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquipPost, ev_WeaponEquip_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_WeaponEquipPost, ev_WeaponEquip_Post);
}

public void ev_WeaponEquip_Post(int client, int entity) { 
	int weaponID = GetWeaponID(entity);

	if(weaponID && !g_weaponMaxClip[weaponID]) {
		g_weaponMaxClip[weaponID] = GetEntData(entity, g_offset_clip1);

		PrintToServer("USTAW %d ammo dla broni o ID %d", g_weaponMaxClip[weaponID], weaponID);
	}
} 

public ev_PlayerDeath_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!client || !attacker || GetClientTeam(client) == GetClientTeam(attacker)) {
		return;
	}

	if(g_healthForFrag[attacker]) {
		SetEntityHealth(attacker, GetLower(GetClientHealth(attacker) + g_healthForFrag[attacker], 100 + CodD0_GetAllClientStatsPoints(attacker, HEALTH_PTS)));
	}

	if(g_expForFrag[attacker]) {
		CodD0_SetClientExp(attacker, CodD0_GetClientExp(attacker) + g_expForFrag[attacker]);
		PrintToChat(attacker, " \x06\x0E BONUS\x05 +%dXP\x01 za\x04 fraga", g_expForFrag[attacker]);
	}

	if(g_coinsForFrag[attacker]) {
		CodD0_SetClientCoins(attacker, CodD0_GetClientCoins(attacker) + g_coinsForFrag[attacker]);
		PrintToChat(attacker, " \x06\x0E BONUS\x05 +%d$\x01 za\x04 fraga", g_coinsForFrag[attacker]);
	}

	if(g_ammoForFrag[attacker] && !CodD0_GetClientActUnlimitedAmmo(attacker)) {
		int weaponEnt = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");

		if(IsValidEntity(weaponEnt) && (weaponEnt == GetPlayerWeaponSlot(attacker, CS_SLOT_PRIMARY) || weaponEnt == GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY))) {
			PrintToServer("%N +%d ammo za fraga dla broni %d", attacker, GetLower(g_weaponMaxClip[GetWeaponID(weaponEnt)], GetEntData(weaponEnt, g_offset_clip1) + g_ammoForFrag[attacker]), GetWeaponID(weaponEnt));
			SetEntData(weaponEnt, g_offset_clip1, GetLower(g_weaponMaxClip[GetWeaponID(weaponEnt)], GetEntData(weaponEnt, g_offset_clip1) + g_ammoForFrag[attacker]), 4, true);
		}
	}
}

int GetLower(int val1, int val2) {
	if(val1 < val2) {
		return val1;
	}

	return val2;
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