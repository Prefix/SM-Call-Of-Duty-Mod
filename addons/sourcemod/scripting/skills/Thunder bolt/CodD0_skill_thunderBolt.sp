#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Thunder bolt", 
	author = "d0naciak", 
	description = "Skill: Thunder bolt", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_thunderBoltsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_thunderBoltsNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];

int g_lastTarget[MAXPLAYERS+1], g_spriteSmoke, g_spriteLightning;

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
}

public void OnMapStart() {
	PrecacheSound("ambient/explosions/explode_9.wav", true);
	g_spriteSmoke = PrecacheModel("sprites/steam1.vmt");
	g_spriteLightning = PrecacheModel("sprites/physbeam.vmt");
}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_thunderBolt");

	CreateNative("CodD0_SetClientThunderBolt", nat_SetClientThunderBolt);
	CreateNative("CodD0_GetClientThunderBolt", nat_GetClientThunderBolt);
	CreateNative("CodD0_UseThunderBolt", nat_UseThunderBolt);
}

public int nat_SetClientThunderBolt(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_thunderBoltsNum[client][skillID] = g_thunderBoltsNumInRound[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));
}

public int nat_GetClientThunderBolt(Handle plugin, int paramsNum) {
	return g_thunderBoltsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseThunderBolt(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_thunderBoltsNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej piorunów!");
		return CodD0_SkillPrep_Fail;
	}


	int target = GetClientAimTarget(client, false);
	if(target <= 0 || target > MAXPLAYERS || GetClientTeam(client) == GetClientTeam(target)) {
		return CodD0_SkillPrep_Fail;
	}

	float origin[2][3];

	GetClientEyePosition(client, origin[0]);
	GetClientEyePosition(target, origin[1]);
	g_lastTarget[client] = target;

	TR_TraceRayFilter(origin[0], origin[1], MASK_SOLID, RayType_EndPoint, FilterData, client);
	if(TR_GetFraction() < 1.0) {
		return 0;
	}

	Lightning(client, target);
	return (--g_thunderBoltsNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_thunderBoltsNumInRound[i][j] = g_thunderBoltsNum[i][j];
		}
	}
}

void Lightning(int client, int target) {
	// define where the lightning strike ends
	float clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26.0; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	// define where the lightning strike starts
	float startpos[3];
	GetClientAbsOrigin(client, startpos);
	startpos[2] -= 26.0; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	// define the color of the strike
	int color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
	float dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, clientpos, g_spriteLightning, 0, 0, 0, 1.6, 32.0, 32.0, 1, 1.0, color, 16);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	TE_SetupSmoke(clientpos, g_spriteSmoke, 5.0, 10);
	TE_SendToAll();
	
	EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, client, SNDLEVEL_RAIDSIREN);
	CodD0_InflictDamage(client, client, target, 50.0, 0.2, DMG_SHOCK, -1);
}

public bool FilterData(int entity, int contentsMask, any data) {
	return (entity != data && g_lastTarget[data] != entity);
}
