#include <sourcemod>
#include <sdktools>
#include <d0_shop>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: Extra", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeID;
public void OnPluginStart() {
	g_typeID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeID = d0s_RegisterType("extra", d0s_EQMode_Use);
	}
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeID == -1) {
		g_typeID = d0s_RegisterType("extra", d0s_EQMode_Use);
	} else if(typeID != g_typeID) {
		g_typeID = d0s_GetTypeID("extra");
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID != g_typeID) {
		return;
	}

	char data[128], explodedData[3][32];
	kv.GetString("max_usages", explodedData[0], sizeof(explodedData[]));
	kv.GetString("usages_cooldown", explodedData[1], sizeof(explodedData[]));
	kv.GetString("team", explodedData[2], sizeof(explodedData[]));

	Format(data, sizeof(data), "%d|%d|%d", StringToInt(explodedData[0]), StringToInt(explodedData[1]), StringToInt(explodedData[2]));
	d0s_SetItemData(itemID, data);
}

public void OnPluginEnd() {
	if(g_typeID >= 0) {
		d0s_UnregisterType(g_typeID);
	}
}