#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Dropping weapons wave", 
	author = "d0naciak", 
	description = "Skill: Dropping weapons wave", 
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
	PrecacheSound("items/exosuit_long_jump.wav");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_droppingWeaponsWave");

	CreateNative("CodD0_SetClientDroppingWpnsWaves", nat_SetClientDroppingWpnsWaves);
	CreateNative("CodD0_GetClientDroppingWpnsWaves", nat_GetClientDroppingWpnsWaves);
	CreateNative("CodD0_UseDroppingWpnsWaves", nat_UseDroppingWpnsWaves);
}

public int nat_SetClientDroppingWpnsWaves(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_wavesNum[client][skillID] = g_wavesNumInRound[client][skillID] = GetNativeCell(3);
	g_range[client][skillID] = view_as<float>(GetNativeCell(4));
}

public int nat_GetClientDroppingWpnsWaves(Handle plugin, int paramsNum) {
	return g_wavesNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseDroppingWpnsWaves(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if (!g_wavesNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej fal!");
		return CodD0_SkillPrep_Fail;
	}

	MakeWave(client, g_range[client][skillID]);
	return (--g_wavesNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

void MakeWave(int client, float range) {
	float position[3], targetPosition[3];

	GetClientAbsOrigin(client, position);
	position[2] += 4.0;

	int colors[] = {59, 11, 108, 180};

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
			/*TR_TraceRayFilterEx(position, targetPosition, MASK_SOLID, RayType_EndPoint, TraceEntityFilterIsInViewcone, client);
			float fr = TR_GetFraction();

			PrintToChatAll("FR: %.1f", fr);

			if(fr == 1.0) {*/
				int weaponEnt = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");

				if(IsValidEntity(weaponEnt)) {
					CS_DropWeapon(i, weaponEnt, true, false);
				}
				
			//}
		}
	}
}

public bool TraceEntityFilterIsInViewcone(int entity, int contentsMask, any client) {
	return (entity!=client);
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_wavesNumInRound[i][j] = g_wavesNum[i][j];
		}
	}
}