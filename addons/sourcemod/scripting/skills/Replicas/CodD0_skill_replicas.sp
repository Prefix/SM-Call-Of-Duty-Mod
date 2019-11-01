#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

#define MAXENTITIES 2048

public Plugin myinfo =	{
	name = "COD d0 Skill: Replicas", 
	author = "d0naciak", 
	description = "Skill: Replicas", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_offset_thrower;

int g_replicasNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_replicasNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_replica_skillID[MAXENTITIES+1];
bool g_replica_blockTakingDamage[MAXENTITIES+1];

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);

	int maxEntities = GetMaxEntities();
	if (maxEntities > MAXENTITIES) {
		SetFailState("Change MAXENTITIES constance (curent: %d, needed: %d)", MAXENTITIES, maxEntities);
	}

	g_offset_thrower = FindSendPropInfo("CBaseGrenade", "m_hThrower");
	if (g_offset_thrower == -1) {
		SetFailState("Can't find m_hThrower offset");
	}

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientDisconnect(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_replicas");

	CreateNative("CodD0_SetClientReplicas", nat_SetClientReplicas);
	CreateNative("CodD0_GetClientReplicas", nat_GetClientReplicas);
	CreateNative("CodD0_PlaceReplica", nat_PlaceReplica);
}

public int nat_SetClientReplicas(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_replicasNum[client][skillID] = g_replicasNumInRound[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));

	if(!g_replicasNum[client][skillID]) {
		int entity = FindEntityByClassname(-1, "hegrenade_projectile"), entity2;
		
		while(entity > 0) {
			entity2 = FindEntityByClassname(entity, "hegrenade_projectile");

			if(client == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) {
				if(g_replica_skillID[entity] == skillID) {
					RemoveEdict(entity);
				}
			}
			
			entity = entity2;
		}
	}
}

public int nat_GetClientReplicas(Handle plugin, int paramsNum) {
	return g_replicasNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_PlaceReplica(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(!g_replicasNumInRound[client][skillID]) {
		PrintCenterText(client, "Nie posiadasz więcej replik!");
		return CodD0_SkillPrep_Fail;
	}

	if(!PlaceReplica(client, skillID)) {
		return CodD0_SkillPrep_Fail;
	}

	return (--g_replicasNumInRound[client][skillID]) ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_replicasNumInRound[i][j] = g_replicasNum[i][j];
		}
	}
}

bool PlaceReplica(int client, int skillID) {
	int replica = CreateEntityByName("hegrenade_projectile");
	float vec[3], angleVec[3];

	GetReplicaPosition(client, vec);
	GetClientEyeAngles(client, angleVec);
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	vOrigin[0] += 100.0;

	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] += 50.0; // above

	if (!DispatchSpawn(replica)) {
		PrintCenterText(client, "Nie mogę postawić repliki :(");
		return false;
	}

	char modelBuffer[256];
	GetClientModel(client, modelBuffer, sizeof(modelBuffer));
	SetEntityModel(replica, modelBuffer);
	SetEntProp(replica, Prop_Send, "m_usSolidFlags", 152);
	SetEntProp(replica, Prop_Send, "m_CollisionGroup", 11);
	SetEntProp(replica, Prop_Data,"m_iHealth", 200);
	SetEntProp(replica, Prop_Data, "m_takedamage", 2);
	SetEntityMoveType(replica, MOVETYPE_NONE);
	SetEntDataEnt2(replica, g_offset_thrower, client);
	SetEntPropEnt(replica, Prop_Send, "m_hOwnerEntity", client);
	angleVec[0] = 0.0;
	vec[2] = vOrigin[2] - 64.0;
	TeleportEntity(replica, vec, angleVec, NULL_VECTOR);
	SDKHook(replica, SDKHook_OnTakeDamage, ev_ReplicaOnTakeDamage);
	g_replica_skillID[replica] = skillID;
	return true;
}

public Action ev_ReplicaOnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if (!attacker || attacker > MAXPLAYERS || !((damagetype & DMG_BULLET) && !(damagetype & DMG_SLASH))) {
		return Plugin_Continue;
	}

	//EmitSoundToClient(attacker, "*/valkiria_cod/Replikant_OnShot.mp3");

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(GetClientTeam(client) != GetClientTeam(attacker)) {
		damage = 0.0;
		return Plugin_Changed;
	} else if(IsPlayerAlive(attacker)) {
		if(damagetype & DMG_SLASH) {
			g_replica_blockTakingDamage[entity] = true;
			damage = 999.0;
			return Plugin_Changed;
		} else {
			int skillID = g_replica_skillID[entity];
			CodD0_InflictDamage(client, client, attacker, g_damage[client][skillID], g_damagePerInt[client][skillID], 0, -1);
		}
	}

	return Plugin_Continue;
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker)) {
		return Plugin_Continue;
	}

	if(g_replica_blockTakingDamage[ent]) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void GetReplicaPosition(int client, float vec[3]) {
	float vOrigin[3], vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace)) {
		float endPos[3];
		TR_GetEndPosition(endPos, trace);

		float reversedVector[3];
		SubtractVectors(endPos, vOrigin, reversedVector);
		NormalizeVector(reversedVector, reversedVector);
		ScaleVector(reversedVector, 50.0);
		AddVectors(vOrigin, reversedVector, vec);
		// vec[1] = vOrigin[1];
		CloseHandle(trace);
		return;
	}

	CloseHandle(trace);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return entity > MaxClients;
}

public void OnEntityDestroyed(int entity) {
	if(entity > 0) {
		g_replica_skillID[entity] = -1;
		g_replica_blockTakingDamage[entity] = false;
	}
}