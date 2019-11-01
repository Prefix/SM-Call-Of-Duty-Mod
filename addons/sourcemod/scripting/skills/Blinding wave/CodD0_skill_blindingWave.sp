#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Blinding wave", 
	author = "d0naciak", 
	description = "Skill: Blinding wave", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_spriteID;
int g_wavesNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_wavesNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_range[MAXPLAYERS+1][CodD0_SkillSlot_Max];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
}

public void OnMapStart() {
	g_spriteID = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_blindingWave");

	CreateNative("CodD0_SetClientBlindingWaves", nat_SetClientBlindingWaves);
	CreateNative("CodD0_GetClientBlindingWaves", nat_GetClientBlindingWaves);
	CreateNative("CodD0_UseBlindingWaves", nat_UseBlindingWave);
}

public int nat_SetClientBlindingWaves(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_wavesNum[client][skillID] = g_wavesNumInRound[client][skillID] = GetNativeCell(3);
	g_range[client][skillID] = view_as<float>(GetNativeCell(4));
}

public int nat_GetClientBlindingWaves(Handle plugin, int paramsNum) {
	return g_wavesNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseBlindingWave(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if (!g_wavesNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej fal!");
		return CodD0_SkillPrep_Fail;
	}

	FlashOpponents(client, g_range[client][skillID]);
	return (--g_wavesNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

void FlashOpponents(int client, float range) {
	float position[3], targetPosition[3];

	GetClientAbsOrigin(client, position);
	position[2] += 4.0;

	int colors[] = {255, 255, 255, 180};

	TE_SetupBeamRingPoint(position, range * 0.3, 32.0, g_spriteID, 0, 0, 0, 0.8 * 0.3, 4.0, 1.0, colors, 128, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(position, range * 0.6, 32.0, g_spriteID, 0, 0, 0, 0.8 * 0.6, 4.0, 1.0, colors, 128, 0);
	TE_SendToAll();

	TE_SetupBeamRingPoint(position, range, 32.0, g_spriteID, 0, 0, 0, 0.8, 4.0, 1.0, colors, 128, 0);
	TE_SendToAll();
	
	EmitSoundToAll("items/exosuit_long_jump.wav", client, 0, 0, 0, 0.5, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) == GetClientTeam(client)) {
			continue;
		}

		GetClientAbsOrigin(i, targetPosition);

		if(GetVectorDistance(position, targetPosition) <= range) {
			//TR_TraceRayFilterEx(position, targetPosition, MASK_SOLID, RayType_EndPoint, TraceEntityFilterIsInViewcone, client);
			//if(TR_GetFraction() == 1.0) {
			Fade(i, 750, 300, 0x0001, {255, 255, 255, 255});
			//}
		}
	}
}

public bool TraceEntityFilterIsInViewcone(int entity, int contentsMask, any client) {
	return (entity!=client);
}

void Fade(int client, int duration, int hold_time, int flags, const int colors[4]) {
	Handle message = StartMessageOne("Fade", client, 1);
	PbSetInt(message, "duration", duration);
	PbSetInt(message, "hold_time", hold_time);
	PbSetInt(message, "flags", flags);
	PbSetColor(message, "clr", colors);
	EndMessage();
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_wavesNumInRound[i][j] = g_wavesNum[i][j];
		}
	}
}