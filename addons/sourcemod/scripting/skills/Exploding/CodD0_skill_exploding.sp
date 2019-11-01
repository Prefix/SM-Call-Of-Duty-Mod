#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_exploding_consts>

public Plugin myinfo =  {
	name = "COD d0 Skill: Exploding", 
	author = "d0naciak", 
	description = "Skill: Exploding", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_explodesNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_explodesNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_exploMode[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_exploding");

	CreateNative("CodD0_SetClientExplodes", nat_SetClientExplodes);
	CreateNative("CodD0_GetClientExplodes", nat_GetClientExplodes);
	CreateNative("CodD0_UseExplode", nat_UseExplode);
}

public int nat_SetClientExplodes(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_explodesNum[client][skillID] = g_explodesNumInRound[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));
	g_exploMode[client][skillID] = GetNativeCell(6);
}

public int nat_GetClientExplodes(Handle plugin, int paramsNum) {
	return g_explodesNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseExplode(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if (!g_explodesNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej eksplozji!");
		return CodD0_SkillPrep_Fail;
	}

	float position[3];

	switch (g_exploMode[client][skillID]) {
		case EXPLO_PLAYER: {
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		}

		case EXPLO_AIM: {
			float angles[3], startPos[3], direction[3];

			GetClientEyeAngles(client, angles);
			GetClientEyePosition(client, startPos);
			GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);

			ScaleVector(direction, 99999.0);
			AddVectors(startPos, direction, position);

			TR_TraceRayFilter(startPos, position, MASK_ALL, RayType_EndPoint, TraceEntityFilterAimingTarget, client);
			TR_GetEndPosition(position);
		}
	}

	CodD0_MakeExplosion(client, position, g_damage[client][skillID], g_damagePerInt[client][skillID], 250);

	return (--g_explodesNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public bool TraceEntityFilterAimingTarget(int entity, int contentsMask, any client) {
	return !(entity==client);
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_explodesNumInRound[i][j] = g_explodesNum[i][j];
		}
	}
}