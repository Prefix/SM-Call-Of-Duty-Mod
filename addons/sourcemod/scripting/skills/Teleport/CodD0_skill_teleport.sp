#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Teleport", 
	author = "d0naciak", 
	description = "Skill: Teleport", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_teleportsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_teleportsNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_range[MAXPLAYERS+1][CodD0_SkillSlot_Max];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_teleport");

	CreateNative("CodD0_SetClientTeleports", nat_SetClientTeleports);
	CreateNative("CodD0_GetClientTeleports", nat_GetClientTeleports);
	CreateNative("CodD0_UseTeleport", nat_UseTeleport);
}

public int nat_SetClientTeleports(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_teleportsNum[client][skillID] = g_teleportsNumInRound[client][skillID] = GetNativeCell(3);
	g_range[client][skillID] = view_as<float>(GetNativeCell(4));
}

public int nat_GetClientTeleports(Handle plugin, int paramsNum) {
	return g_teleportsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseTeleport(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_teleportsNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej teleportów!");
		return CodD0_SkillPrep_Fail;
	}

	if(!TeleportToAim(client, g_range[client][skillID])) {
		PrintCenterText(client, "Nie możesz się tam dostać!");
		return CodD0_SkillPrep_Fail;
	}

	return (--g_teleportsNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_teleportsNumInRound[i][j] = g_teleportsNum[i][j];
		}
	}
}

bool TeleportToAim(int cId, float fMaxDistance) {
	float fStartPos[3], fEndPos[3], fAngles[3], fMins[3], fMaxs[3], fDistance;

	GetClientEyePosition(cId, fStartPos);
	GetClientEyeAngles(cId, fAngles);

	TR_TraceRayFilter(fStartPos, fAngles, MASK_ALL, RayType_Infinite, TraceEntityFilterAimingTarget, cId);
	TR_GetEndPosition(fEndPos);

	fDistance = GetVectorDistance(fStartPos, fEndPos);
	if(fDistance > fMaxDistance) {
		float fMulti = fMaxDistance / fDistance;

		for (int i = 0; i < 3; i++) {
			fEndPos[i] = fStartPos[i] + (fEndPos[i] - fStartPos[i]) * fMulti;
		}
	}

	GetClientMins(cId, fMins);
	GetClientMaxs(cId, fMaxs);
	
	TR_TraceHullFilter(fEndPos, fEndPos, fMins, fMaxs, MASK_ALL, TraceEntityFilterSolid);
	if(TR_DidHit() || TR_PointOutsideWorld(fEndPos)) {
		if(!FindFreeSpace(fEndPos, fMins, fMaxs)) {
			return false;
		}
	}

	TR_TraceRayFilter(fStartPos, fEndPos, MASK_ALL, RayType_EndPoint, TraceEntityPlayerFilter);
	if(TR_GetFraction() != 1.0) {
		return false;
	}

	TeleportEntity(cId, fEndPos, NULL_VECTOR, NULL_VECTOR);
	return true;
}

public bool TraceEntityFilterAimingTarget(int iEntity, int iContentsMask, any cId) {
	return !(iEntity==cId);
}

public bool TraceEntityFilterSolid(int entity, int mask) {
	return entity > 1;
}

public bool TraceEntityPlayerFilter(int entity, int mask) {
	return !(1 <= entity <= MaxClients);
}

bool FindFreeSpace(float originalpos[3], const float mins[3], const float maxs[3]) {
	//float absincarray[]={0.0,24.0,-24.0,48.0,-48.0,72.0,-72.0};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller
	float absincarray[]={0.0,12.0,-12.0,24.0,-24.0,36.0,-36.0,48.0,-48.0,60.0,-60.0,72.0,-72.0,84.0,-84.0,96.0,-96.0};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller
	int absincarraysize=sizeof(absincarray);

	for(int x=0;x<absincarraysize;x++){
		for(int y=0;y<absincarraysize;y++){
			for(int z=0;z<absincarraysize;z++){
				float pos[3]={0.0,0.0,0.0};

				pos[0] = originalpos[0] + absincarray[x];
				pos[1] = originalpos[1] + absincarray[y];
				pos[2] = originalpos[2] + absincarray[z];
						
				TR_TraceHullFilter(pos,pos,mins,maxs,MASK_ALL,TraceEntityFilterSolid);
				if(!TR_DidHit() && !TR_PointOutsideWorld(pos)) {
					originalpos[0]=pos[0];
					originalpos[1]=pos[1];
					originalpos[2]=pos[2];
					return true;
				}
			}
		}
	}

	return false;
} 