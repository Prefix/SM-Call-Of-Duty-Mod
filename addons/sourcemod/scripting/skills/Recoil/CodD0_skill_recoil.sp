#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: No recoil", 
	author = "d0naciak", 
	description = "Skill: No recoil", 
	version = "1.0", 
	url = "d0naciak.pl"
};

float g_recoilMultiplier[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeRecoilMultiplier[MAXPLAYERS+1];
bool g_hooksRegistered[MAXPLAYERS+1];

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_recoilMultiplier[i][j] = 1.0;
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_recoil");

	CreateNative("CodD0_SetClientRecoil", nat_SetClientRecoil);
	CreateNative("CodD0_GetClientRecoil", nat_GetClientRecoil);
}

public int nat_SetClientRecoil(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_recoilMultiplier[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_activeRecoilMultiplier[client] = 1.0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_recoilMultiplier[client][i] < g_activeRecoilMultiplier[client]) {
			g_activeRecoilMultiplier[client] = g_recoilMultiplier[client][i];
		}
	}

	if (g_activeRecoilMultiplier[client] < 1.0) {
		if (!g_hooksRegistered[client]) {
			SDKHook(client, SDKHook_PreThink, ev_Think_Post);
			SDKHook(client, SDKHook_PreThinkPost, ev_Think_Post);
			SDKHook(client, SDKHook_PostThink, ev_Think_Post);
			SDKHook(client, SDKHook_PostThinkPost, ev_Think_Post);
			g_hooksRegistered[client] = true;
		}
	} else if (g_hooksRegistered[client]) {
		SDKUnhook(client, SDKHook_PreThink, ev_Think_Post);
		SDKUnhook(client, SDKHook_PreThinkPost, ev_Think_Post);
		SDKUnhook(client, SDKHook_PostThink, ev_Think_Post);
		SDKUnhook(client, SDKHook_PostThinkPost, ev_Think_Post);
		g_hooksRegistered[client] = false;
	}
}

public int nat_GetClientRecoil(Handle plugin, int paramsNum) {
	return view_as<int>(g_recoilMultiplier[GetNativeCell(1)][GetNativeCell(2)]);
}

public void ev_Think_Post(int client) {
	if (!IsPlayerAlive(client)) {
		return;
	}
	
	int weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEdict(weaponEnt) || weaponEnt == -1) {
		return;
	}
	
	float punchAngle[3], multiplier = g_activeRecoilMultiplier[client];
	SetEntPropFloat(weaponEnt, Prop_Send, "m_fAccuracyPenalty", GetEntPropFloat(weaponEnt, Prop_Send, "m_fAccuracyPenalty") * multiplier);

	GetEntPropVector(client, Prop_Send, "m_aimPunchAngle", punchAngle);
	for(int i = 0; i < 3; i++) {
		punchAngle[i] *= multiplier;
	}
	SetEntPropVector(client, Prop_Send, "m_aimPunchAngle", punchAngle);

	GetEntPropVector(client, Prop_Send, "m_aimPunchAngleVel", punchAngle);
	for(int i = 0; i < 3; i++) {
		punchAngle[i] *= multiplier;
	}
	SetEntPropVector(client, Prop_Send, "m_aimPunchAngleVel", punchAngle);

	GetEntPropVector(client, Prop_Send, "m_viewPunchAngle", punchAngle);
	for(int i = 0; i < 3; i++) {
		punchAngle[i] *= multiplier;
	}
	SetEntPropVector(client, Prop_Send, "m_viewPunchAngle", punchAngle);
}