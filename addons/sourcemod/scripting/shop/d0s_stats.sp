#include <sourcemod>
#include <sdktools>
#include <d0_shop>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: COD Stats", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeID;
bool g_clientBoughtStatBonus[MAXPLAYERS + 1][5];

public void OnPluginStart() {
	g_typeID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeID = d0s_RegisterType("stats", d0s_EQMode_Use);
	}
}

public void OnMapStart() {
	for(int i = 1; i <= MaxClients; i++) {
		OnClientPutInServer(i); 
	}
}

public void OnClientPutInServer(int client) {
	for(int i = 1; i <= 4; i++) {
		g_clientBoughtStatBonus[client][i] = false;
	}
	
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeID == -1) {
		g_typeID = d0s_RegisterType("stats", d0s_EQMode_Use);
	} else if(typeID != g_typeID) {
		g_typeID = d0s_GetTypeID("stats");
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID != g_typeID) {
		return;
	}

	char data[64], name[32];
	int statID, value;

	kv.GetString("name", name, sizeof(name));
	value = kv.GetNum("value");

	if(StrEqual(name, "intelligence")) {
		statID = INT_PTS;
	} else if(StrEqual(name, "health")) {
		statID = HEALTH_PTS;
	} else if(StrEqual(name, "stamina")) {
		statID = STAMINA_PTS;
	} else if(StrEqual(name, "speed")) {
		statID = SPEED_PTS;
	}

	Format(data, sizeof(data), "%d|%d", statID, value);
	d0s_SetItemData(itemID, data);
}

public void OnPluginEnd() {
	if(g_typeID >= 0) {
		d0s_UnregisterType(g_typeID);
	}
}

public Action d0s_OnItemUse(int client, int itemID, int typeID) {
	if(typeID != g_typeID) {
		return Plugin_Continue;
	}

	char data[64], explodedData[2][32];

	d0s_GetItemData(itemID, data, sizeof(data));
	ExplodeString(data, "|", explodedData, sizeof(explodedData), sizeof(explodedData[]));
	int statID = StringToInt(explodedData[0]);

	if(g_clientBoughtStatBonus[client][statID]) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Na mapę można kupić maksymalnie jeden bonus dla statystyki!");
		return Plugin_Handled;
	}


	CodD0_SetClientBonusStatsPoints(client, statID, CodD0_GetClientBonusStatsPoints(client, statID) + StringToInt(explodedData[1]));
	g_clientBoughtStatBonus[client][statID] = true;

	return Plugin_Continue;
}