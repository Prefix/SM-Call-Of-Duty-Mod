#include <sourcemod>
#include <sdktools>
#include <d0_shop>
#include <CodD0_engine>

int g_offset_activeWeapon, g_offset_primaryAmmoType, g_offset_ammo;

int g_itemID;
int g_usageCooldown;

int g_plrUsageCooldown[MAXPLAYERS+1];
bool g_hasUnlimitedAmmo[MAXPLAYERS+1];

public Plugin myinfo =  {
	name = "d0 Shop Item: Unlimited ammo", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	g_offset_ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_offset_activeWeapon = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	g_offset_primaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

	if (g_offset_ammo == -1 || g_offset_activeWeapon == -1 || g_offset_primaryAmmoType == -1) {
		SetFailState("Failed to retrieve entity member offsets");
	}

	if(d0s_AreItemsLoaded()) {
		g_itemID = d0s_GetItemID("unlimited_ammo");
	}

	HookEvent("weapon_fire", ev_WeaponFire_Post);
}

public void d0s_OnAllItemsCfgLoad_Post() {
	char data[128], explodedData[3][32];

	g_itemID = d0s_GetItemID("unlimited_ammo");
	d0s_GetItemData(g_itemID, data, sizeof(data));
	ExplodeString(data, "|", explodedData, sizeof(explodedData), sizeof(explodedData[]));

	g_usageCooldown = StringToInt(explodedData[1]);
}

public void OnClientPutInServer(int client) {
	g_plrUsageCooldown[client] = 0;
	g_hasUnlimitedAmmo[client] = false;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		if(g_plrUsageCooldown[i] > 0) {
			g_plrUsageCooldown[i] --;
		} else if(!g_plrUsageCooldown[i]) {
			g_hasUnlimitedAmmo[i] = false;
		}
	}
}

public void ev_WeaponFire_Post(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client && IsPlayerAlive(client) && g_hasUnlimitedAmmo[client]) {
		int entity = GetEntDataEnt2(client, g_offset_activeWeapon);

		if (IsValidEdict(entity) && (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == entity || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == entity)) {
			int ammoType = GetEntData(entity, g_offset_primaryAmmoType);

			if (ammoType > 0) {
				SetEntData(client, g_offset_ammo + ammoType * 4, 200, 4, true);
			}
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
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Zestaw będziesz mógł kupić za\x05 %d rund!", g_plrUsageCooldown[client]);
		return Plugin_Handled;
	} else if(g_plrUsageCooldown[client] < 0) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Zestaw możesz kupić\x05 raz na mapę!");
		return Plugin_Handled;
	}

	g_plrUsageCooldown[client] = g_usageCooldown;
	g_hasUnlimitedAmmo[client] = true;

	return Plugin_Continue;
}