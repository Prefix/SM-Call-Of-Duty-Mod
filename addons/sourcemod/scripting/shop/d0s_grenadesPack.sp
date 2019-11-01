#include <sourcemod>
#include <sdktools>
#include <d0_shop>
#include <CodD0_engine>

int g_itemID;
int g_usageCooldown;

int g_plrUsageCooldown[MAXPLAYERS+1];

public Plugin myinfo =  {
	name = "d0 Shop Item: Grenades pack", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	if(d0s_AreItemsLoaded()) {
		g_itemID = d0s_GetItemID("grenades_pack");
	}

	HookEvent("round_start", ev_RoundStart_Post);
}

public void d0s_OnAllItemsCfgLoad_Post() {
	char data[128], explodedData[3][32];

	g_itemID = d0s_GetItemID("grenades_pack");
	d0s_GetItemData(g_itemID, data, sizeof(data));
	ExplodeString(data, "|", explodedData, sizeof(explodedData), sizeof(explodedData[]));

	g_usageCooldown = StringToInt(explodedData[1]);
}

public void OnClientPutInServer(int client) {
	g_plrUsageCooldown[client] = 0;
}

public ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		if(g_plrUsageCooldown[i] > 0) {
			g_plrUsageCooldown[i] --;
		}
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

	if(g_plrUsageCooldown[client] > 0) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Granaty będziesz mógł kupić za\x05 %d rund!", g_plrUsageCooldown[client]);
		return Plugin_Handled;
	} else if(g_plrUsageCooldown[client] < 0) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Granaty możesz kupić\x05 raz na mapę!");
		return Plugin_Handled;
	}

	g_plrUsageCooldown[client] = g_usageCooldown;

	CodD0_GiveClientWeapon(client, CSWeapon_HEGRENADE);
	CodD0_GiveClientWeapon(client, CSWeapon_FLASHBANG);
	CodD0_GiveClientWeapon(client, CSWeapon_FLASHBANG);
	CodD0_GiveClientWeapon(client, CSWeapon_SMOKEGRENADE);
	return Plugin_Continue;
}