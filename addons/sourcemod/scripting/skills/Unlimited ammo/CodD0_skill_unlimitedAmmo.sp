#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Unlimited ammo", 
	author = "d0naciak", 
	description = "Skill: Unlimited ammo", 
	version = "1.0", 
	url = "d0naciak.pl"
};

bool g_unlimitedAmmo[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeUnlimitedAmmo[MAXPLAYERS+1];
int g_offset_clip1;

public void OnPluginStart() {
	HookEvent("weapon_fire", ev_WeaponFire_Post);
	if((g_offset_clip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) == -1) {
		SetFailState("Can't find offset: m_iClip1");
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_unlimitedAmmo");

	CreateNative("CodD0_SetClientUnlimitedAmmo", nat_SetClientUnlimitedAmmo);
	CreateNative("CodD0_GetClientUnlimitedAmmo", nat_GetClientUnlimitedAmmo);
	CreateNative("CodD0_GetClientActUnlimitedAmmo", nat_GetClientActUnlimitedAmmo);
}

public int nat_SetClientUnlimitedAmmo(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_unlimitedAmmo[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeUnlimitedAmmo[client] = false;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_unlimitedAmmo[client][i]) {
			g_activeUnlimitedAmmo[client] = true;
			break;
		}
	}
}

public int nat_GetClientUnlimitedAmmo(Handle plugin, int paramsNum) {
	return g_unlimitedAmmo[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_GetClientActUnlimitedAmmo(Handle plugin, int paramsNum) {
	return g_activeUnlimitedAmmo[GetNativeCell(1)];
}

public void ev_WeaponFire_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !g_activeUnlimitedAmmo[client]) {
		return;
	}

	int weaponEnt = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(!IsValidEntity(weaponEnt) || GetEntData(weaponEnt, g_offset_clip1) <= 1) {
		return;
	}

	char weaponName[32];
	GetEntPropString(weaponEnt, Prop_Data, "m_iClassname", weaponName, sizeof(weaponName));
	strcopy(weaponName, sizeof(weaponName), weaponName[7]);

	if(StrContains(weaponName, "nade") != -1 || StrEqual(weaponName, "flashbang") || StrEqual(weaponName, "decoy") || StrEqual(weaponName, "molotov") || StrEqual(weaponName, "healthshot")) {
		return;
	}
	
	SetEntData(weaponEnt, g_offset_clip1, 102, 4, true);
}