#include <sourcemod>
#include <sdktools>
#include <d0_shop>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: Trail & Aura", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeTrailID, g_typeAuraID;

char g_playerParticleName[MAXPLAYERS+1][64];
int g_playerParticleID[MAXPLAYERS+1];

char g_playerTrailModel[MAXPLAYERS+1][128];
int g_playerTrailModelID[MAXPLAYERS+1];
int g_playerTrailID[MAXPLAYERS+1];
Handle g_playerTrailTimer[MAXPLAYERS+1];
bool g_playerStoppedMoving[MAXPLAYERS+1];
float g_lastStoppageTime[MAXPLAYERS+1];

/*
float g_lastPosition[MAXPLAYERS+1][3], g_clientCounters[MAXPLAYERS+1];
bool g_spawnTrails[MAXPLAYERS+1];
*/

public void OnPluginStart() {
	g_typeTrailID = -1;
	g_typeAuraID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeTrailID = d0s_RegisterType("trail", d0s_EQMode_Equip);
		g_typeAuraID = d0s_RegisterType("aura", d0s_EQMode_Equip);
	}
	
	HookEvent("player_spawn", ev_PlayerSpawn_Post);
	HookEvent("player_death", ev_PlayerDeath_Post);
	//HookEvent("round_end", ev_RoundEnd_Post);
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeTrailID == -1) {
		g_typeTrailID = d0s_RegisterType("trail", d0s_EQMode_Equip);
		g_typeAuraID = d0s_RegisterType("aura", d0s_EQMode_Equip);
	}

	if(typeID != g_typeTrailID) {
		g_typeTrailID = d0s_GetTypeID("trail");
	}

	if(typeID != g_typeAuraID) {
		g_typeAuraID = d0s_GetTypeID("aura");
	}
}

public void OnPluginEnd() {
	if(g_typeTrailID >= 0) {
		d0s_UnregisterType(g_typeTrailID);
		d0s_UnregisterType(g_typeAuraID);
	}
}

public void OnMapStart() {
	int itemsNum = d0s_GetItemsNum(), typeID, modelID;
	char data[256], explodedData[2][128];

	for(int i = 0; i < itemsNum; i++) {
		typeID = d0s_GetItemTypeID(i);

		if(typeID == g_typeTrailID) {
			d0s_GetItemData(i, data, sizeof(data));
			ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

			AddFileToDownloadsTable(explodedData[0]);
			modelID = PrecacheModel(explodedData[0], true);

			Format(data, sizeof(data), "%s||%d", explodedData[0], modelID);
			d0s_SetItemData(i, data);
		} else if(typeID == g_typeAuraID) {
			d0s_GetItemData(i, data, sizeof(data));
			ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

			AddFileToDownloadsTable(explodedData[0]);
			PrecacheGeneric(explodedData[0], true);

			PrecacheEffect("ParticleEffect");
			PrecacheParticleEffect(explodedData[1]);
		}
	}

	for(int i = 1; i <= MaxClients; i++) {
		g_playerTrailTimer[i] = null;
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID == g_typeTrailID) {
		char data[256], file[128];
		kv.GetString("file", file, sizeof(file));

		Format(data, sizeof(data), "%s||MDL_ID", file);
		d0s_SetItemData(itemID, data);
	} else if(typeID == g_typeAuraID) {
		char data[256], file[128], name[32];
		kv.GetString("file", file, sizeof(file));
		kv.GetString("particle_name", name, sizeof(name));

		Format(data, sizeof(data), "%s||%s", file, name);
		d0s_SetItemData(itemID, data);
	}
}

public void OnClientDisconnect(int client) {
	RemoveTrail(client, true);
	RemoveParticle(client, true);
}

public void d0s_OnItemEquip_Post(int client, int itemID, int typeID) {
	int unequipID = -1;

	if(typeID == g_typeTrailID) {
		char data[256], explodedData[2][128];
		d0s_GetItemData(itemID, data, sizeof(data));
		ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

		g_playerTrailModel[client] = explodedData[0];
		int modelID = g_playerTrailModelID[client] = StringToInt(explodedData[1]);

		if(IsClientInGame(client) && IsPlayerAlive(client)) {
			CreateTrail(client, explodedData[0], modelID);
		}

		unequipID = g_typeAuraID;
	} else if(typeID == g_typeAuraID) {
		char data[256], explodedData[2][64];
		d0s_GetItemData(itemID, data, sizeof(data));
		ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

		g_playerParticleName[client] = explodedData[1];

		if(IsClientInGame(client) && IsPlayerAlive(client)) {
			CreateParticle(client, explodedData[1]);
		}

		unequipID = g_typeTrailID;
	}

	if(unequipID >= 0) {
		int itemsNum = d0s_GetItemsNum();

		for(int i = 0; i < itemsNum; i++) {
			if(d0s_GetItemTypeID(i) == unequipID && d0s_IsItemEquipped(client, i)) {
				d0s_TakeoffClientItem(client, i);
				break;
			}
		}
	}
}

public void d0s_OnItemTakeoff_Post(int client, int itemID, int typeID) {
	if(typeID == g_typeTrailID) {
		char data[256], explodedData[2][128];
		d0s_GetItemData(itemID, data, sizeof(data));
		ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

		if(g_playerTrailModelID[client] == StringToInt(explodedData[1])) {
			RemoveTrail(client, true);
		}
	} else if(typeID == g_typeAuraID) {
		char data[256], explodedData[2][128];
		d0s_GetItemData(itemID, data, sizeof(data));
		ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

		if(StrEqual(g_playerParticleName[client], explodedData[1])) {
			RemoveParticle(client, true);
		}
	}
}

public void ev_PlayerSpawn_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client || !IsPlayerAlive(client)) {
		return;
	}

	CreateTimer(1.0, timer_SpawnDelay, GetClientUserId(client));
}

public Action timer_SpawnDelay(Handle timer, any userID) {
	int client = GetClientOfUserId(userID);

	if(!client || !IsPlayerAlive(client)) {
		return;
	}

	if(g_playerTrailModelID[client]) {
		RemoveTrail(client, false);
		CreateTrail(client, g_playerTrailModel[client], g_playerTrailModelID[client]);
	} else if(strlen(g_playerParticleName[client])) {
		RemoveParticle(client, false);
		CreateParticle(client, g_playerParticleName[client]);
	}
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!client) {
		return;
	}

	RemoveTrail(client, false);
	RemoveParticle(client, false);
}


public void ev_RoundEnd_Post(Handle event, const char[] name, bool dontBroadcast) {
	for (int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client)) {
			RemoveTrail(client, false);
			RemoveParticle(client, false);
		}
	}
}

void CreateParticle(int client, const char particle[64]) {
	int ent = CreateEntityByName("info_particle_system");
	
	float particleOrigin[3];
	GetClientAbsOrigin(client, particleOrigin);
	particleOrigin[2] += 5.0;

	DispatchKeyValue(ent, "start_active", "1");
	DispatchKeyValue(ent, "effect_name", particle);
	DispatchSpawn(ent);
	
	TeleportEntity(ent, particleOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);

	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");

	g_playerParticleID[client] = EntIndexToEntRef(ent);
}

void CreateTrail(int client, char model[128], int modelID) {
	char clientName[MAX_NAME_LENGTH];
	float position[3];

	GetClientName(client, clientName, sizeof(clientName));
	GetClientAbsOrigin(client, position);

	int ent = CreateEntityByName("env_spritetrail");

	DispatchKeyValue(client, "targetname", clientName);
	DispatchKeyValue(ent, "parentname", clientName);

	DispatchKeyValueFloat(ent, "lifetime", 1.0);
	DispatchKeyValueFloat(ent, "endwidth", 6.0);
	DispatchKeyValueFloat(ent, "startwidth", 16.0);
	DispatchKeyValue(ent, "spritename", model);
	DispatchKeyValue(ent, "renderamt", "255");
	DispatchKeyValue(ent, "rendercolor", "255 255 255 255");
	DispatchKeyValue(ent, "rendermode", "10");

	DispatchSpawn(ent);
	position[2] += 10.0; //Beam clips into the floor without this

	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(clientName);
	AcceptEntityInput(ent, "SetParent"); 
	SetEntPropFloat(ent, Prop_Send, "m_flTextureRes", 0.05);

	TE_SetupBeamFollow(ent, modelID, 0, 1.0, 16.0, 6.0, 1, {255, 255, 255, 255});
	TE_SendToAll();

	g_playerTrailID[client] = EntIndexToEntRef(ent);
	g_playerTrailTimer[client] = CreateTimer(0.1, timer_RenderBeam, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	g_lastStoppageTime[client] = 0.0;
	g_playerStoppedMoving[client] = false;
}

public Action timer_RenderBeam(Handle timer, any client) {
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	if(GetVectorLength(velocity) <= 0.0) {
		if(!g_playerStoppedMoving[client]) {
			g_playerStoppedMoving[client] = true;
			g_lastStoppageTime[client] = GetGameTime();
		}
	} else if(g_playerStoppedMoving[client] && (GetGameTime() - g_lastStoppageTime[client]) >= 1.2) {
		/*int ent = EntRefToEntIndex(g_playerTrailID[client]);
	
		if(ent && ent != INVALID_ENT_REFERENCE) {
			
			//PrintToChatAll("BEAM FOLOOW!")
			//TE_SetupBeamFollow(ent, g_playerTrailModelID[client], 0, 1.0, 16.0, 6.0, 1, {255, 255, 255, 255});
			//TE_SendToAll();
		}*/

		RemoveTrail(client, false);
		CreateTrail(client, g_playerTrailModel[client], g_playerTrailModelID[client]);

		g_playerStoppedMoving[client] = false;
	}

	return Plugin_Continue;
}

void RemoveTrail(int client, bool clearData) {
	int ent = EntRefToEntIndex(g_playerTrailID[client]);
	
	if(ent && ent != INVALID_ENT_REFERENCE) {
		//SDKUnhook(ent, SDKHook_SetTransmit, ev_SetTransmit);
		RemoveEdict(ent);
	}

	if(g_playerTrailTimer[client] != null) {
		KillTimer(g_playerTrailTimer[client]);
		g_playerTrailTimer[client] = null;
	}

	if(clearData) {
		g_playerTrailID[client] = 0;
		g_playerTrailModel[client] = "";
		g_playerTrailModelID[client] = 0;
	}
}

void RemoveParticle(int client, bool clearData) {
	int ent = EntRefToEntIndex(g_playerParticleID[client]);
	
	if(ent && ent != INVALID_ENT_REFERENCE) {
		AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
	}

	if(clearData) {
		g_playerParticleID[client] = 0;
		g_playerParticleName[client] = "";
	}
}

stock void PrecacheParticleEffect(const char[] name) {
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, name);
	LockStringTables(save);
}

stock void PrecacheEffect(const char[] name) {
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("EffectDispatch");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, name);
	LockStringTables(save);
}