#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

#define MAXENTITIES 2048

public Plugin myinfo =  {
	name = "COD d0 Skill: Mine", 
	author = "d0naciak", 
	description = "Skill: Rocket", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_minesNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_minesNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_mine_skillID[MAXENTITIES+1];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);

	int maxEntities = GetMaxEntities();
	if (maxEntities > MAXENTITIES) {
		SetFailState("Change MAXENTITIES constance (curent: %d, needed: %d)", MAXENTITIES, maxEntities);
	}
}

public void OnMapStart() {
	AddFileToDownloadsTable("models/d0naciak/mine/mine.mdl");
	AddFileToDownloadsTable("models/d0naciak/mine/mine.phy");
	AddFileToDownloadsTable("models/d0naciak/mine/mine.vvd");
	AddFileToDownloadsTable("models/d0naciak/mine/mine.dx90.vtx");
	AddFileToDownloadsTable("materials/models/d0naciak/mine/mine.vmt");
	AddFileToDownloadsTable("materials/models/d0naciak/mine/mine.vtf");
	AddFileToDownloadsTable("materials/models/d0naciak/mine/mine_exp.vtf");
	AddFileToDownloadsTable("materials/models/d0naciak/mine/mine_normal.vtf");

	PrecacheModel("models/d0naciak/mine/mine.mdl");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_mine");

	CreateNative("CodD0_SetClientMines", nat_SetClientMines);
	CreateNative("CodD0_GetClientMines", nat_GetClientMines);
	CreateNative("CodD0_PlantMine", nat_PlantMine);
}

public int nat_SetClientMines(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_minesNum[client][skillID] = g_minesNumInRound[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));

	if(!g_minesNum[client][skillID]) {
		int entity =  FindEntityByClassname(-1, "prop_physics_override"), entity2;
		
		while(entity > 0) {
			entity2 = FindEntityByClassname(entity, "prop_physics_override");

			if(client == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) {
				char name[32];
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				
				if(StrEqual(name, "cm_mine") && g_mine_skillID[entity] == skillID) {
					RemoveEdict(entity);
				}
			}
			
			entity = entity2;
		}
	}
}

public int nat_GetClientMines(Handle plugin, int paramsNum) {
	return g_minesNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_PlantMine(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_minesNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej rakiet!");
		return CodD0_SkillPrep_Fail;
	}

	PlantMine(client, skillID);
	return (--g_minesNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_minesNumInRound[i][j] = g_minesNum[i][j];
		}
	}
}

void PlantMine(int client, int skillID) {
	float fAngles[3] = { 90.0, 0.0, 0.0 }, fEndPos[3], fStartPos[3], fDirection[3];

	GetClientEyePosition(client, fStartPos);
	GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fDirection, 99999.0);
	AddVectors(fStartPos, fDirection, fEndPos);
	TR_TraceRayFilter(fStartPos, fEndPos, MASK_ALL, RayType_EndPoint, TraceEntityFilterAimingTarget, client);
	TR_GetEndPosition(fEndPos);

	int entity = CreateEntityByName("prop_physics_override");
	SetEntityModel(entity, "models/d0naciak/mine/mine.mdl");
	SetEntProp(entity, Prop_Send, "m_nSkin", 0);
	DispatchKeyValue(entity, "targetname", "cm_mine");
	
	if(DispatchSpawn(entity)) {
		SetEntProp(entity, Prop_Send, "m_usSolidFlags",  152)
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11)
	}

	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 5.0);  
	
	AcceptEntityInput(entity, "DisableMotion");
	SetEntityMoveType(entity, MOVETYPE_NONE);
	TeleportEntity(entity, fEndPos, NULL_VECTOR, NULL_VECTOR)
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 255, 255, 255, 25);
	
	SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
	g_mine_skillID[entity] = skillID;
}

public void OnStartTouchPost(int entity, int victim) {
	if(!(1 <= victim <= MAXPLAYERS) || !IsPlayerAlive(victim))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(!(1 <= client <= MAXPLAYERS) || GetClientTeam(client) == GetClientTeam(victim)) {
		return;
	}

	int skillID = g_mine_skillID[entity];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	CodD0_MakeExplosion(client, position, g_damage[client][skillID], g_damagePerInt[client][skillID], 250);
	
	SDKUnhook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
	RemoveEdict(entity);
}

public bool TraceEntityFilterAimingTarget(int entity, int contentMask, any client) {
	return !(entity >= 1 && entity <= MAXPLAYERS);
}