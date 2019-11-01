#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Long jump", 
	author = "d0naciak", 
	description = "Long jump manager", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_longJumpPower[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_longJumpsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_longJumpsNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_longJumpIntMultiplier[MAXPLAYERS+1][CodD0_SkillSlot_Max];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_longJump");

	CreateNative("CodD0_SetClientLongJumps", nat_SetClientLongJumps);
	CreateNative("CodD0_GetClientLongJumps", nat_GetClientLongJumps);
	CreateNative("CodD0_UseClientLongJump", nat_UseClientLongJump);
}

public int nat_SetClientLongJumps(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_longJumpsNum[client][skillID] = g_longJumpsNumInRound[client][skillID] = GetNativeCell(3);
	g_longJumpPower[client][skillID] = GetNativeCell(4);
	g_longJumpIntMultiplier[client][skillID] = view_as<float>(GetNativeCell(5));

	/*for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_longJumpPower[client][i] > g_actLongJumpPower[client]) {
			g_actLongJumpPower[client] = g_longJumpPower[client][i];
			g_actlongJumpIntMultiplier[client] = g_longJumpIntMultiplier[client][i];
		}
	}*/
}

public int nat_GetClientLongJumps(Handle plugin, int paramsNum) {
	return g_longJumpsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseClientLongJump(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_longJumpsNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej LongJump'ów!");
		return CodD0_SkillPrep_Fail;
	}

	int power = g_longJumpPower[client][skillID] + RoundFloat(float(CodD0_GetClientUsableIntelligence(client)) * g_longJumpIntMultiplier[client][skillID]);
	float angles[3], velocity[3];

	GetClientEyeAngles(client, angles);

	angles[0] *= -1.0; 
	angles[0] = DegToRad(angles[0]); 
	angles[1] = DegToRad(angles[1]); 

	velocity[0] = Cosine(angles[0]) * Cosine(angles[1]) * power;
	velocity[1] = Cosine(angles[0]) * Sine(angles[1]) * power;
	velocity[2] = 265.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

	return (--g_longJumpsNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_longJumpsNumInRound[i][j] = g_longJumpsNum[i][j];
		}
	}
}