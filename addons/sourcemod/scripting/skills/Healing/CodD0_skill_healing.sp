#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Healing", 
	author = "d0naciak", 
	description = "Skill: Healing", 
	version = "1.0", 
	url = "d0naciak.pl"
};

//duck healing
float g_duckHealingTime[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_duckHealingPoints[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_duckHealingPointsPerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_duckHealingSkillID[MAXPLAYERS+1];
Handle g_timerDuckHealing[MAXPLAYERS+1];

public void OnMapEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		g_timerDuckHealing[i] = null;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_healing");

	CreateNative("CodD0_SetClientDuckHealing", nat_SetClientDuckHealing);
	CreateNative("CodD0_GetClientDuckHealing", nat_GetClientDuckHealing);
}

public int nat_SetClientDuckHealing(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), actSkillID;

	g_duckHealingPoints[client][skillID] = GetNativeCell(3);
	g_duckHealingPointsPerInt[client][skillID] = view_as<float>(GetNativeCell(4));
	g_duckHealingTime[client][skillID] = view_as<float>(GetNativeCell(5));

	actSkillID = g_duckHealingSkillID[client] = -1;
	if(g_timerDuckHealing[client] != null) {
		KillTimer(g_timerDuckHealing[client]);
		g_timerDuckHealing[client] = null;
	}

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_duckHealingPoints[client][i] && (actSkillID == -1 || g_duckHealingPoints[client][i] > g_duckHealingPoints[client][actSkillID])) {
			actSkillID = i;
		}
	}

	if(actSkillID != -1) {
		g_duckHealingSkillID[client] = actSkillID;
	}
}

public int nat_GetClientDuckHealing(Handle plugin, int paramsNum) {
	return g_duckHealingPoints[GetNativeCell(1)][GetNativeCell(2)];
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon) {
	if(!IsPlayerAlive(client) || g_duckHealingSkillID[client] == -1) {
		return Plugin_Continue;
	}

	if(buttons & IN_DUCK && g_timerDuckHealing[client] == null)  {
		float velo[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velo);

		if(GetVectorLength(velo) < 1.0) {
			int skillID = g_duckHealingSkillID[client];
			g_timerDuckHealing[client] = CreateTimer(g_duckHealingTime[client][skillID], timer_Healing, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}

	return Plugin_Continue;
}

public Action timer_Healing(Handle timer, any client) {
	if(!IsPlayerAlive(client) || !(GetClientButtons(client) & IN_DUCK)) {
		g_timerDuckHealing[client] = null;
		return Plugin_Stop;
	}

	float velo[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velo);

	if(GetVectorLength(velo) >= 1.0) {
		g_timerDuckHealing[client] = null;
		return Plugin_Stop;
	}

	int actSkillID = g_duckHealingSkillID[client];
	SetEntityHealth(client, GetLower(GetClientHealth(client) + g_duckHealingPoints[client][actSkillID] + RoundFloat(float(CodD0_GetClientUsableIntelligence(client)) * g_duckHealingPointsPerInt[client][actSkillID]), 100 + CodD0_GetAllClientStatsPoints(client, HEALTH_PTS)));
	return Plugin_Continue;
}

int GetLower(int iVal1, int iVal2) {
	if(iVal1 < iVal2) {
		return iVal1;
	}

	return iVal2;
}

