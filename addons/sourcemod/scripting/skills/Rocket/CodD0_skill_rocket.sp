#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004
#define MAXENTITIES 2048

public Plugin myinfo =  {
	name = "COD d0 Skill: Rocket", 
	author = "d0naciak", 
	description = "Skill: Rocket", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_rocketsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_rocketsNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_rocket_skillID[MAXENTITIES+1];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);

	int maxEntities = GetMaxEntities();
	if (maxEntities > MAXENTITIES) {
		SetFailState("Change MAXENTITIES constance (curent: %d, needed: %d)", MAXENTITIES, maxEntities);
	}
}

public void OnMapStart() {
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.sw.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.phy");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.vvd");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.mdl");

	PrecacheModel("models/weapons/W_missile_closed.mdl");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_rocket");

	CreateNative("CodD0_SetClientRockets", nat_SetClientRockets);
	CreateNative("CodD0_GetClientRockets", nat_GetClientRockets);
	CreateNative("CodD0_FireRocket", nat_FireRocket);
}

public int nat_SetClientRockets(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_rocketsNum[client][skillID] = g_rocketsNumInRound[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));
}

public int nat_GetClientRockets(Handle plugin, int paramsNum) {
	return g_rocketsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_FireRocket(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_rocketsNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej rakiet!");
		return CodD0_SkillPrep_Fail;
	}

	CreateRocket(client, skillID);
	return (--g_rocketsNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_rocketsNumInRound[i][j] = g_rocketsNum[i][j];
		}
	}
}

void CreateRocket(int client, int skillID) {
	int entity = CreateEntityByName("hegrenade_projectile");

	if (entity == -1) {
		return;
	}
	
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	
	float OwnerAng[3];
	GetClientEyeAngles(client, OwnerAng);
	
	float OwnerPos[3];
	GetClientEyePosition(client, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, entity);
	
	float InitialPos[3];
	TR_GetEndPosition(InitialPos);
	
	float InitialVec[3];
	MakeVectorFromPoints(OwnerPos, InitialPos, InitialVec);
	
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, 2000.0);
	
	float InitialAng[3];
	GetVectorAngles(InitialVec, InitialAng);

	DispatchSpawn(entity);
	ActivateEntity(entity);
	SetEntityModel(entity, "models/weapons/W_missile_closed.mdl");
	SetEntityMoveType(entity, MOVETYPE_FLY);

	float mins[] = { -1.0, -1.0, 0.0 };
	float maxs[] = { 1.0, 1.0, 2.0 };
	SetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

	TeleportEntity(entity, OwnerPos, InitialAng, InitialVec);
	g_rocket_skillID[entity] = skillID;

	SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
}

public void OnStartTouchPost(int entity, int other) {
	if ((GetEntProp(other, Prop_Data, "m_nSolidType") == SOLID_NONE) || GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID) {
		return;
	}

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"), skillID = g_rocket_skillID[entity];
	float position[3];
	
	if(client <= 0 || client > MAXPLAYERS) {
		return;
	}
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	CodD0_MakeExplosion(client, position, g_damage[client][skillID], g_damagePerInt[client][skillID], 450);

	SDKUnhook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
	AcceptEntityInput(entity, "Kill");
}

public bool DontHitOwnerOrNade(int entity, int contentsMask, any data) {
	int NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hOwnerEntity");
	return ((entity != data) && (entity != NadeOwner));
}