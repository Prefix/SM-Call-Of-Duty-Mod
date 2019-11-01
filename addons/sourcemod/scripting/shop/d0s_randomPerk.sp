#include <sourcemod>
#include <sdktools>
#include <d0_shop>
#include <CodD0_engine>

int g_itemID;
int g_maxUsages;

int g_plrUsagesInRound[MAXPLAYERS+1];

public Plugin myinfo =  {
	name = "d0 Shop Item: Random perk", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	if(d0s_AreItemsLoaded()) {
		g_itemID = d0s_GetItemID("random_perk");
	}

	HookEvent("round_start", ev_RoundStart_Post);
}

public void d0s_OnAllItemsCfgLoad_Post() {
	char data[128], explodedData[3][32];

	g_itemID = d0s_GetItemID("random_perk");
	d0s_GetItemData(g_itemID, data, sizeof(data));
	ExplodeString(data, "|", explodedData, sizeof(explodedData), sizeof(explodedData[]));

	g_maxUsages = StringToInt(explodedData[0]);
}

public void OnClientPutInServer(int client) {
	g_plrUsagesInRound[client] = 0;
}

public ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		g_plrUsagesInRound[i] = 0;
	}
}

public Action d0s_OnItemUse(int client, int itemID, int typeID) {
	if(itemID != g_itemID) {
		return Plugin_Continue;
	}

	if(!CodD0_GetClientClass(client)) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Musisz pierw wybrać jakąś klasę!");
		return Plugin_Handled;
	}

	if(g_plrUsagesInRound[client] >= g_maxUsages && g_maxUsages) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Możesz kupić max. %d szt. perków na rundę!", g_maxUsages);
		return Plugin_Handled;
	}

	g_plrUsagesInRound[client] ++;
	CodD0_SetClientPerk(client, -1, -1, true);
	return Plugin_Continue;
}