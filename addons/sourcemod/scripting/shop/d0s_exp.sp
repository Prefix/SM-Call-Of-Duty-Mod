#include <sourcemod>
#include <sdktools>
#include <d0_shop>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: COD Experience", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeID;
public void OnPluginStart() {
	g_typeID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeID = d0s_RegisterType("exp", d0s_EQMode_Use);
	}
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeID == -1) {
		g_typeID = d0s_RegisterType("exp", d0s_EQMode_Use);
	} else if(typeID != g_typeID) {
		g_typeID = d0s_GetTypeID("exp");
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID != g_typeID) {
		return;
	}

	char data[32];
	kv.GetString("value", data, sizeof(data));
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

	if(!CodD0_GetClientClass(client)) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Musisz pierw wybrać jakąś klasę!");
		return Plugin_Handled;
	}

	char value[32];
	d0s_GetItemData(itemID, value, sizeof(value));

	CodD0_SetClientExp(client, CodD0_GetClientExp(client) + StringToInt(value));
	return Plugin_Continue;
}