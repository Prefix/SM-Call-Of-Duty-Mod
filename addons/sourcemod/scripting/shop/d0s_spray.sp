#include <sourcemod>
#include <sdktools>
#include <d0_shop>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: Spray", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeID;

int g_playerSprayID[MAXPLAYERS+1];
float g_sprayCooldown[MAXPLAYERS+1];

public void OnPluginStart() {
	g_typeID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeID = d0s_RegisterType("spray", d0s_EQMode_Equip);
	}

	RegConsoleCmd("sm_spray", cmd_MakeSpray);
}

public void OnMapStart() {
	int itemsNum = d0s_GetItemsNum(), typeID, modelID;
	char data[256], explodedData[2][128];

	for(int i = 0; i < itemsNum; i++) {
		typeID = d0s_GetItemTypeID(i);

		if(typeID != g_typeID) {
			continue;
		}
		
		d0s_GetItemData(i, data, sizeof(data));
		ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

		modelID = PrecacheDecal(explodedData[0], true);
		Format(data, sizeof(data), "%s||%d", explodedData[0], modelID);

		d0s_SetItemData(i, data);
	}

	AddFileToDownloadsTable("sound/player/sprayer.mp3");
	PrecacheSound("*/player/sprayer.mp3");
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeID == -1) {
		g_typeID = d0s_RegisterType("spray", d0s_EQMode_Equip);
	} else if(typeID != g_typeID) {
		g_typeID = d0s_GetTypeID("spray");
	}
}

public void OnPluginEnd() {
	if(g_typeID >= 0) {
		d0s_UnregisterType(g_typeID);
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID != g_typeID) {
		return;
	}

	char data[256], sprayFileName[128];

	kv.GetString("file", sprayFileName, sizeof(sprayFileName));
	Format(data, sizeof(data), "%s||MDL_ID", sprayFileName);

	d0s_SetItemData(itemID, data);
}

public void d0s_OnItemEquip_Post(int client, int itemID, int typeID) {
	if(typeID != g_typeID) {	
		return;
	}

	char data[256], explodedData[2][128];

	d0s_GetItemData(itemID, data, sizeof(data));
	ExplodeString(data, "||", explodedData, sizeof(explodedData), sizeof(explodedData[]));

	g_playerSprayID[client] = StringToInt(explodedData[1]);

	if(IsClientInGame(client)) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Aby maźnąć spraya użyj komendy\x0E !spray");
	}
}

public void d0s_OnItemTakeoff_Post(int client, int itemID, int typeID) {
	if(typeID != g_typeID) {	
		return;
	}

	g_playerSprayID[client] = 0;
}

public void OnClientConnected(int client) {
	g_playerSprayID[client] = 0;
	g_sprayCooldown[client] = 0.0;
}

public Action cmd_MakeSpray(int client, int args) {
	if (!IsPlayerAlive(client)) {
		return Plugin_Handled;
	}

	if (!g_playerSprayID[client]) {
		PrintCenterText(client, "Nie masz ustawionego żadnego spraya!");
		return Plugin_Handled;
	}

	float aimOrigin[3];

	if (!GetAimOrigin(client, aimOrigin, 64.0)) {
		PrintCenterText(client, "Jesteś za daleko ściany!");
		return Plugin_Handled;
	}

	float gameTime = GetGameTime();
	if (g_sprayCooldown[client] > gameTime) {
		PrintCenterText(client, "Sprayu można używać raz na 30 sec.!");
		return Plugin_Handled;
	}

	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", aimOrigin);
	TE_WriteNum("m_nIndex", g_playerSprayID[client]);
	TE_SendToAll();

	EmitSoundToAll("*/player/sprayer.mp3", client, 0, 0, 0, 0.5, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	g_sprayCooldown[client] = gameTime + 30.0;
	return Plugin_Handled;
}

bool GetAimOrigin(int client, float aimOrigin[3], float maxDistance = 99999.0) {
	float angles[3], origin[3];

	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, origin);

	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if (!TR_DidHit(trace)) {
		delete trace;
		return false;
	}

	TR_GetEndPosition(aimOrigin, trace);
	delete trace;

	if (GetVectorDistance(origin, aimOrigin) > maxDistance) {
		return false;
	}

	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return entity > MaxClients;
}