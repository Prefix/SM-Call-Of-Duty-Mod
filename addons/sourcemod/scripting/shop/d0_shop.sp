#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <d0_shop_consts>

public Plugin myinfo =  {
	name = "Shop", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

Database g_sqlConn;
ArrayList g_itemName, g_itemTypeID, g_itemCategoryID, g_itemKey, g_itemDesc, g_itemData, g_plrItemQUValue, g_plrItemIsEquipped;
ArrayList g_itemQUName[d0s_MaxQUs], g_itemQUPrice[d0s_MaxQUs], g_itemQUValue[d0s_MaxQUs], g_itemQUsNum;
ArrayList g_categoryName;
ArrayList g_typeKey, g_typeEquipMode;
Handle g_fwOnTypeLoad_Post, g_fwOnItemCfgLoad_Post, g_fwOnAllItemsCfgLoad_Post, g_fwOnItemUse, g_fwOnItemEquip_Post, g_fwOnItemTakeoff_Post;
bool g_allPluginsLoaded;

//Player data
#define Q_CONN 0
#define Q_ACT 1
bool g_isPlrDataLoaded[MAXPLAYERS + 1][2];
int g_plrLastSelectedCategory[MAXPLAYERS + 1], g_plrLastSelectedItem[MAXPLAYERS + 1];
Handle g_plrTimerNextItemToDestroy[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegConsoleCmd("sm_shop", cmd_Shop, "opens shop with special items");
	RegConsoleCmd("sm_sklep", cmd_Shop, "opens shop with special items");
	RegConsoleCmd("sm_store", cmd_Shop, "opens shop with special items");
	RegServerCmd("sm_reloaditems", cmd_ReloadItems, "reloads items.cfg");

	char error[512];
	g_sqlConn = SQL_Connect("d0_shop", true, error, sizeof(error));
	if (g_sqlConn == INVALID_HANDLE) {
		PrintToServer("Can't connect to database: %s", error);
	} else {
		SQL_LockDatabase(g_sqlConn);

		char query[][] = {
				"CREATE TABLE IF NOT EXISTS d0s_players\
				( \
					playerID int NOT NULL AUTO_INCREMENT, \
					steamID varchar(64) NOT NULL, \
					PRIMARY KEY (playerID), \
					UNIQUE (steamID) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS d0s_types \
				( \
					typeID int NOT NULL AUTO_INCREMENT, \
					typeKey varchar(32) NOT NULL, \
					eqMode int NOT NULL, \
					PRIMARY KEY (typeID), \
					UNIQUE (typeKey) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS d0s_items \
				( \
					itemID int NOT NULL AUTO_INCREMENT, \
					itemKey varchar(32) NOT NULL, \
					typeID int NOT NULL, \
					enabled boolean NOT NULL DEFAULT true, \
					PRIMARY KEY (itemID), \
					UNIQUE (itemKey) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS d0s_playersitems \
				( \
					playerID int NOT NULL, \
					itemID int NOT NULL, \
					quantityUnitValue int NOT NULL, \
					CONSTRAINT playerItemID UNIQUE (playerID, itemID) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS d0s_playerseqitems \
				( \
					playerID int NOT NULL, \
					itemID int NOT NULL, \
					CONSTRAINT playerEqItemID UNIQUE (playerID, itemID) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;"
		};

		bool isErrorExists;
		for(int i = 0; i < sizeof(query); i++) {
			if (!SQL_FastQuery(g_sqlConn, query[i]) && SQL_GetError(g_sqlConn, error, sizeof(error))) {
				PrintToServer("d0 Shop SQL: Error while creating tables: %s", error);
				isErrorExists = true;
			}
		}

		if(!isErrorExists) {
			PrintToServer("d0 Shop SQL: Database is ready to work!");
		}

		SQL_UnlockDatabase(g_sqlConn);
	}

	g_itemName = new ArrayList(64);
	g_itemTypeID = new ArrayList(1);
	g_itemCategoryID = new ArrayList(1);
	g_itemKey = new ArrayList(32);
	g_itemDesc = new ArrayList(256);
	g_itemData = new ArrayList(512);
	g_plrItemQUValue = new ArrayList(MAXPLAYERS+1);
	g_plrItemIsEquipped = new ArrayList(MAXPLAYERS+1);

	for(int i = 0; i < d0s_MaxQUs; i++) {
		g_itemQUName[i] = new ArrayList(128);
		g_itemQUPrice[i] = new ArrayList(1);
		g_itemQUValue[i] = new ArrayList(1);
	}
	g_itemQUsNum = new ArrayList(1);

	g_categoryName = new ArrayList(64);

	g_typeKey = new ArrayList(32);
	g_typeEquipMode = new ArrayList(1);

	g_fwOnTypeLoad_Post = CreateGlobalForward("d0s_OnTypeLoad_Post", ET_Ignore, Param_Cell);
	g_fwOnItemCfgLoad_Post = CreateGlobalForward("d0s_OnItemCfgLoad_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_fwOnAllItemsCfgLoad_Post = CreateGlobalForward("d0s_OnAllItemsCfgLoad_Post", ET_Ignore);
	g_fwOnItemEquip_Post = CreateGlobalForward("d0s_OnItemEquip_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_fwOnItemTakeoff_Post = CreateGlobalForward("d0s_OnItemTakeoff_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_fwOnItemUse = CreateGlobalForward("d0s_OnItemUse", ET_Event, Param_Cell, Param_Cell, Param_Cell);
}

public void OnPluginEnd() {
	SQL_LockDatabase(g_sqlConn);

	char steamID[64];
	for(new i = 1; i <= MaxClients; i++) {
		if(g_isPlrDataLoaded[i][Q_CONN] && GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			SavePlayerData(i, steamID, true);
		}
	}

	SQL_UnlockDatabase(g_sqlConn);
}

public void OnMapStart() {
	char path[256], line[256];

	BuildPath(Path_SM, path, sizeof(path), "configs/d0_shop/downloads.ini");
	File file = OpenFile(path, "r");

	if(file == null) {
		return;
	}

	while(ReadFileLine(file, line, sizeof(line))) {
		TrimString(line);

		if(!strlen(line) || line[0] == ';') {
			continue;
		}

		AddFileToDownloadsTable(line);
	}

	delete file;
}

public void OnAllPluginsLoaded() {
	Call_StartForward(g_fwOnTypeLoad_Post);
	Call_PushCell(-1);
	Call_Finish();

	ReadItems();
	g_allPluginsLoaded = true;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorLen) {
	RegPluginLibrary("d0_shop");

	CreateNative("d0s_RegisterType", nat_RegisterType);
	CreateNative("d0s_UnregisterType", nat_UnregisterType);

	CreateNative("d0s_GetTypeKey", nat_GetTypeKey);
	CreateNative("d0s_GetTypeEQType", nat_GetTypeEQType);
	CreateNative("d0s_GetTypeID", nat_GetTypeID);

	CreateNative("d0s_GetItemKey", nat_GetItemKey);
	CreateNative("d0s_GetItemDesc", nat_GetItemDesc);
	CreateNative("d0s_GetItemTypeID", nat_GetItemTypeID);
	CreateNative("d0s_GetItemID", nat_GetItemID);
	CreateNative("d0s_GetItemData", nat_GetItemData);
	CreateNative("d0s_SetItemData", nat_SetItemData);

	CreateNative("d0s_IsItemEquipped", nat_IsItemEquipped);
	CreateNative("d0s_UseClientItem", nat_UseClientItem);
	CreateNative("d0s_EquipClientItem", nat_EquipClientItem);
	CreateNative("d0s_TakeoffClientItem", nat_TakeoffClientItem);

	CreateNative("d0s_AreItemsLoaded", nat_AreItemsLoaded);
	CreateNative("d0s_GetItemsNum", nat_GetItemsNum);
}

/*
public void OnMapEnd() {
	char steamID[64];
	for(new i = 1; i <= MaxClients; i++) {
		if(GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID)) && g_isPlrDataLoaded[i][Q_CONN]) {
			SavePlayerData(i, steamID, false);
		}
	}
}*/

public void OnClientAuthorized(int client, const char[] authID) {
	ReadPlayerData(client, authID);
}

public void OnClientDisconnect(int client) {
	if(g_plrTimerNextItemToDestroy[client] != null) {
		KillTimer(g_plrTimerNextItemToDestroy[client]);
		g_plrTimerNextItemToDestroy[client] = null;
	}

	char steamID[64];
	if(g_isPlrDataLoaded[client][Q_CONN] && GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		SavePlayerData(client, steamID, false);
	}

	int itemsNum = g_itemName.Length;
	for(int i = 0; i < itemsNum; i++) {
		g_plrItemIsEquipped.Set(i, 0, client);
		g_plrItemQUValue.Set(i, 0, client);
	}

	g_isPlrDataLoaded[client][Q_CONN] = false;
	g_isPlrDataLoaded[client][Q_ACT] = false;
}

public Action cmd_Shop(int client, int args) {
	if(!g_isPlrDataLoaded[client][Q_CONN] || !g_isPlrDataLoaded[client][Q_ACT]) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Trwa przetwarzanie danych, spróbuj ponownie za chwilę.");
		return Plugin_Handled;
	}

	int categoriesNum = g_categoryName.Length;

	if(categoriesNum) {
		Menu menu = new Menu(SelectCategory_Handler, MENU_ACTIONS_ALL);
		char name[64], item[128];

		Format(item, sizeof(item), "► Shop by d0naciak ◄\n► Posiadasz: %d$ ◄", CodD0_GetClientCoins(client));
		menu.SetTitle(item);
		for(int i = 0; i < categoriesNum; i++) {
			g_categoryName.GetString(i, name, sizeof(name));
			menu.AddItem("", name);
		}

		menu.Display(client, MENU_TIME_FOREVER);
	} else {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Nie znaleziono żadnych przedmiotów w sklepie :(");
	}

	return Plugin_Handled;
}

public int SelectCategory_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			g_plrLastSelectedCategory[client] = item;
			SelectItem(client, item);
		}

		case MenuAction_End: {
			if(menu != null) {
				delete menu;
			}
		}
	}
}

void SelectItem(int client, int categoryID) {
	Menu menu = new Menu(SelectItem_Handler, MENU_ACTIONS_ALL);
	char name[64], item[128], itemID[32];
	int itemsNum = g_itemName.Length;

	g_categoryName.GetString(categoryID, name, sizeof(name));
	Format(item, sizeof(item), "☛ %s\n☛ Posiadasz: %d$", name, CodD0_GetClientCoins(client));
	menu.SetTitle(item);

	for(int i = 0; i < itemsNum; i++) {
		if(g_itemCategoryID.Get(i) != categoryID) {
			continue;
		}

		g_itemName.GetString(i, name, sizeof(name));
		IntToString(i, itemID, sizeof(itemID));

		if(g_plrItemIsEquipped.Get(i, client)) {
			Format(item, sizeof(item), "%s [✓]", name);
		} else {
			strcopy(item, sizeof(item), name);
		}

		menu.AddItem(itemID, item);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectItem_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			char info[32];

			menu.GetItem(item, info, sizeof(info));
			int itemID = g_plrLastSelectedItem[client] = StringToInt(info);
			ItemMenu(client, itemID);
		}

		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				cmd_Shop(client, 0);
			}
		}

		case MenuAction_End: {
			if(menu != null) {
				delete menu;
			}
		}
	}
}

void ItemMenu(int client, int itemID) {
	char item[512], data[256];
	int plrQUValue = g_plrItemQUValue.Get(itemID, client);
	int unixTime = GetTime();
	int typeID = g_itemTypeID.Get(itemID);
	int eqMode = g_typeEquipMode.Get(typeID);
	int itemLen;

	Menu menu = new Menu(PlayerItemMenu_Handler, MENU_ACTIONS_ALL);

	g_itemName.GetString(itemID, data, sizeof(data));
	itemLen += Format(item[itemLen], sizeof(item) - itemLen, "☛ Przedmiot: %s\n", data);

	g_itemDesc.GetString(itemID, data, sizeof(data));
	if (strlen(data)) {
		itemLen += Format(item[itemLen], sizeof(item) - itemLen, "☛ Opis: %s\n", data);
	}

	if(eqMode == d0s_EQMode_Use) {
		itemLen += Format(item[itemLen], sizeof(item) - itemLen, "☛ Ilość: %d\n", plrQUValue);

		if(g_itemQUsNum.Get(itemID) == 1) {
			char quName[64];
			g_itemQUName[0].GetString(itemID, quName, sizeof(quName));
			Format(data, sizeof(data), "Kup %s za %d$", quName, g_itemQUPrice[0].Get(itemID));

			menu.AddItem("1-buy_item", data);
		} else {
			menu.AddItem("1-buy_item_menu", "Kup przedmiot");
		}

		if(plrQUValue) {
			menu.AddItem("1-use_item", "Użyj przedmiotu");
		} else {
			menu.AddItem("0-use_item", "Użyj przedmiotu");
		}
	} else {
		if(plrQUValue > unixTime) {
			bool isEquipped = view_as<bool>(g_plrItemIsEquipped.Get(itemID, client));
			FormatTime(data, sizeof(data), "%x - %X", plrQUValue); //add "forever" option
			itemLen += Format(item[itemLen], sizeof(item) - itemLen, "☛ Wygasa: %s\n", data);

			menu.AddItem("0-buy_item", "Kup przedmiot");
			menu.AddItem(isEquipped ? "0-equip_item" : "1-equip_item", "Załóż przedmiot");
			menu.AddItem(isEquipped ? "1-takeoff_item" : "0-takeoff_item", "Zdejmij przedmiot");
		} else {
			if(g_itemQUsNum.Get(itemID) == 1) {
				char quName[64];
				g_itemQUName[0].GetString(itemID, quName, sizeof(quName));
				Format(data, sizeof(data), "Kup %s za %d$", quName, g_itemQUPrice[0].Get(itemID));

				menu.AddItem("1-buy_item", data);
			} else {
				menu.AddItem("1-buy_item_menu", "Kup przedmiot");
			}

			menu.AddItem("0-equip_item", "Załóż przedmiot");
			menu.AddItem("0-takeoff_item", "Zdejmij przedmiot");
		}
	}

	itemLen += Format(item[itemLen], sizeof(item) - itemLen, "\n☛ Posiadasz: %d$", CodD0_GetClientCoins(client));
	menu.SetTitle(item);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PlayerItemMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				SelectItem(client, g_plrLastSelectedCategory[client]);
			}
		}

		case MenuAction_End: {
			if(menu != null) {
				delete menu;
			}
		}

		case MenuAction_DrawItem: {
			char info[4];
			menu.GetItem(item, info, sizeof(info));

			if(info[0] == '0') {
				return ITEMDRAW_DISABLED;
			}
		}

		case MenuAction_Select: {
			char info[32];
			menu.GetItem(item, info, sizeof(info));
			strcopy(info, sizeof(info), info[2]);

			int itemID = g_plrLastSelectedItem[client];
			if(StrEqual(info, "buy_item_menu")) {
				BuyItemMenu(client, itemID);
			} else if (StrEqual(info, "buy_item")) {
				BuyItem(client, itemID, 0);
			}  else if (StrEqual(info, "equip_item")) {
				EquipItem(client, itemID);
				ItemMenu(client, itemID);
			} else if (StrEqual(info, "takeoff_item")) {
				TakeoffItem(client, itemID);
				ItemMenu(client, itemID);
			} else if (StrEqual(info, "use_item")) {
				UseItem(client, itemID);
				ItemMenu(client, itemID);
			}
		}
	}

	return 0;
}

void BuyItemMenu(int client, int itemID) {
	char item[256], data[128];
	int itemQUsNum = g_itemQUsNum.Get(itemID);
	Menu menu = new Menu(BuyItemMenu_Handler, MENU_ACTIONS_ALL);

	g_itemName.GetString(itemID, data, sizeof(data));
	Format(item, sizeof(item), "Kup przedmiot %s:", data);
	menu.SetTitle(item);

	for(int i = 0; i < itemQUsNum; i++) {
		g_itemQUName[i].GetString(itemID, data, sizeof(data));
		Format(item, sizeof(item), "%s za %d$", data, g_itemQUPrice[i].Get(itemID));
		menu.AddItem("", item);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int BuyItemMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ItemMenu(client, g_plrLastSelectedItem[client]);
			}
		}

		case MenuAction_End: {
			if(menu != null) {
				delete menu;
			}
		}

		case MenuAction_DrawItem: {
			int itemID = g_plrLastSelectedItem[client];

			if(CodD0_GetClientCoins(client) < g_itemQUPrice[item].Get(itemID)) {
				return ITEMDRAW_DISABLED;
			}
		}

		case MenuAction_Select: {
			BuyItem(client, g_plrLastSelectedItem[client], item);
		}
	}

	return 0;
}

void BuyItem(int client, int itemID, int quID) {
	int plrCoins = CodD0_GetClientCoins(client), price = g_itemQUPrice[quID].Get(itemID);

	if(plrCoins < price) {
		PrintToChat(client, " \x06\x04[d0:Shop]\x01 Brakuje Ci monet na ten przedmiot!");
	} else {
		char itemKey[32], escapedItemKey[64], steamID[64];

		if(!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
			PrintToChat(client, " \x06\x04[d0:Shop]\x01 Wystąpił problem z autoryzacją.");
		} else {
			char query[512];
			int itemQUValue = g_itemQUValue[quID].Get(itemID);

			CodD0_SetClientCoins(client, plrCoins - price);

			g_itemKey.GetString(itemID, itemKey, sizeof(itemKey));
			g_sqlConn.Escape(itemKey, escapedItemKey, sizeof(escapedItemKey));

			if(g_typeEquipMode.Get(g_itemTypeID.Get(itemID)) == d0s_EQMode_Use) {
				g_plrItemQUValue.Set(itemID, g_plrItemQUValue.Get(itemID, client) + itemQUValue, client);
				Format(query, sizeof(query), "INSERT INTO d0s_playersitems (playerID, itemID, quantityUnitValue) SELECT p.playerID, i.itemID, %d FROM d0s_players AS p, d0s_items AS i WHERE p.steamID='%s' AND i.itemKey='%s' ON DUPLICATE KEY UPDATE quantityUnitValue=quantityUnitValue+%d", itemQUValue, steamID, escapedItemKey, itemQUValue);
			} else {
				itemQUValue += GetTime();
				g_plrItemQUValue.Set(itemID, itemQUValue, client);
				Format(query, sizeof(query), "INSERT INTO d0s_playersitems (playerID, itemID, quantityUnitValue) SELECT p.playerID, i.itemID, %d FROM d0s_players AS p, d0s_items AS i WHERE p.steamID='%s' AND i.itemKey='%s' ON DUPLICATE KEY UPDATE quantityUnitValue=%d", itemQUValue, steamID, escapedItemKey, itemQUValue);
			}

			g_isPlrDataLoaded[client][Q_ACT] = false;

			//LogMessage("%N BuyItem, query %s", client, query);
			g_sqlConn.Query(tquery_GiveClientItem, query, GetClientUserId(client));
		}
	}
}

public void tquery_GiveClientItem(Database db, DBResultSet results, const char[] error, any userID) {
	if (results == null) {
		LogError("tquery_GiveClientItem error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userID);

	if (!client) {
		return;
	}

	int itemID = g_plrLastSelectedItem[client];
	char name[64];

	if(g_typeEquipMode.Get(g_itemTypeID.Get(itemID)) == d0s_EQMode_Use && g_itemQUsNum.Get(itemID) > 1) {
		BuyItemMenu(client, itemID);
	} else {
		ItemMenu(client, itemID);
	}

	g_isPlrDataLoaded[client][Q_ACT] = true;

	g_itemName.GetString(itemID, name, sizeof(name));
	PrintToChat(client, " \x06\x04[d0:Shop]\x01 Kupiłeś(aś)\x05 %s", name);
}

void EquipItem(int client, int itemID) {
	int typeID = g_itemTypeID.Get(itemID), eqMode = g_typeEquipMode.Get(typeID);

	if(eqMode == d0s_EQMode_Equip) {
		int itemsNum = g_itemName.Length;

		for(int i = 0; i < itemsNum; i++) {
			if(typeID != g_itemTypeID.Get(i)) {
				continue;
			}

			if(g_plrItemIsEquipped.Get(i, client)) {
				TakeoffItem(client, i);
				break;
			}
		}
	}

	char itemKey[32];
	g_itemKey.GetString(itemID, itemKey, sizeof(itemKey));

	g_plrItemIsEquipped.Set(itemID, 1, client);
	Call_StartForward(g_fwOnItemEquip_Post);
	Call_PushCell(client);
	Call_PushCell(itemID);
	Call_PushCell(typeID);
	Call_Finish();

	//LogMessage("%N EquipItem %s", client, itemKey);
}

void TakeoffItem(int client, int itemID) {
	int typeID = g_itemTypeID.Get(itemID);

	g_plrItemIsEquipped.Set(itemID, 0, client);
	Call_StartForward(g_fwOnItemTakeoff_Post);
	Call_PushCell(client);
	Call_PushCell(itemID);
	Call_PushCell(typeID);
	Call_Finish();

	//LogMessage("%N TakeoffItem", client);
}

void UseItem(int client, int itemID) {
	int typeID = g_itemTypeID.Get(itemID);
	Action result;

	Call_StartForward(g_fwOnItemUse);
	Call_PushCell(client);
	Call_PushCell(itemID);
	Call_PushCell(typeID);
	Call_Finish(result);

	if(result != Plugin_Handled) {
		g_plrItemQUValue.Set(itemID, g_plrItemQUValue.Get(itemID, client) - 1, client);
		//LogMessage("%N UseItem", client);
	}
}

void DestroyItem(int client, int itemID) {
	if(g_plrItemIsEquipped.Get(itemID, client)) {
		TakeoffItem(client, itemID);
	}

	g_plrItemQUValue.Set(itemID, 0, client);
	//LogMessage("%N DestroyItem", client);
}

void ReadPlayerData(int client, const char[] steamID) {
	if (IsFakeClient(client)) {
		return;
	}

	char query[512];

	g_isPlrDataLoaded[client][Q_CONN] = false;
	g_isPlrDataLoaded[client][Q_ACT] = true;

	Format(query, sizeof(query), "SELECT playerID FROM d0s_players WHERE steamID='%s'", steamID);
	//LogMessage("%N ReadPlayerData %s", client, query);
	//PrintToServer(query);
	g_sqlConn.Query(tquery_SelectPlayerFromDB, query, GetClientUserId(client));
}

public void tquery_SelectPlayerFromDB(Database db, DBResultSet results, const char[] error, any userID) {
	//PrintToServer("START tquery_SelectPlayerFromDB");

	if (results == null) {
		LogError("tquery_SelectPlayerFromDB error: %s", error);
		return;
	}

	//PrintToServer("GET USER ID");
	int client = GetClientOfUserId(userID);

	if(!client) {
		return;
	}

	//PrintToServer("GET STEAM ID");

	char steamID[64], query[512];

	if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		return;
	}

	//PrintToServer("NEXT QUERY");

	if(results.RowCount > 0) {
		Format(query, sizeof(query), "DELETE pi.*, pei.* FROM d0s_playersitems AS pi INNER JOIN d0s_players AS p ON pi.playerID=p.playerID INNER JOIN d0s_items AS i ON pi.itemID=i.itemID INNER JOIN d0s_types AS t ON i.typeID=t.typeID LEFT JOIN d0s_playerseqitems AS pei ON pi.itemID=pei.itemID WHERE p.steamID='%s' AND ((pi.quantityUnitValue<=%d AND t.eqMode!=%d) OR (pi.quantityUnitValue<=0 AND t.eqMode=%d))", steamID, GetTime(), d0s_EQMode_Use, d0s_EQMode_Use);
		//LogMessage("%N tquery_SelectPlayerFromDB %s", client, query);
		//PrintToServer(query);
		g_sqlConn.Query(tquery_RemovePlayerExpiredItems, query, userID);
	} else {
		Format(query, sizeof(query), "INSERT INTO d0s_players (steamID) VALUES ('%s')", steamID);
		//LogMessage("%N tquery_SelectPlayerFromDB %s", client, query);
		//PrintToServer(query);
		g_sqlConn.Query(tquery_InsertPlayerToDB, query, userID);
	}
}

public void tquery_InsertPlayerToDB(Database db, DBResultSet results, const char[] error, any userID) {
	if (results == null) {
		LogError("tquery_InsertPlayerToDB error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userID);

	if(client) {
		g_isPlrDataLoaded[client][Q_CONN] = true;
	}
}

public void tquery_RemovePlayerExpiredItems(Database db, DBResultSet results, const char[] error, any userID) {
	if (results == null) {
		LogError("tquery_RemovePlayerExpiredItems error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userID);

	if(!client) {
		return;
	}

	char steamID[64], query[512];

	if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		return;
	}

	Format(query, sizeof(query), "SELECT t.typeKey, i.itemKey FROM d0s_playerseqitems AS pei INNER JOIN d0s_players AS p ON pei.playerID=p.playerID INNER JOIN d0s_items AS i ON pei.itemID=i.itemID INNER JOIN d0s_types AS t ON i.typeID=t.typeID WHERE p.steamID='%s'", steamID);
	//LogMessage("%N tquery_RemovePlayerExpiredItems %s", client, query);
	g_sqlConn.Query(tquery_ReadPlayerEquippedItems, query, userID);
}

public void tquery_ReadPlayerEquippedItems(Database db, DBResultSet results, const char[] error, any userID) {
	if (results == null) {
		LogError("tquery_ReadPlayerEquippedItems error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userID);

	if(!client) {
		return;
	}

	if(results.RowCount >= 0) {
		char typeKey[32], itemKey[32];
		int typeID, itemID;
		while (results.MoreRows && results.FetchRow()) {
			results.FetchString(0, typeKey, sizeof(typeKey));
			results.FetchString(1, itemKey, sizeof(itemKey));
			typeID = g_typeKey.FindString(typeKey);
			itemID = g_itemKey.FindString(itemKey);

			if(itemID >= 0 && typeID >= 0) {
				g_plrItemIsEquipped.Set(itemID, 1, client);

				Call_StartForward(g_fwOnItemEquip_Post);
				Call_PushCell(client);
				Call_PushCell(itemID);
				Call_PushCell(typeID);
				Call_Finish();

				//LogMessage("%N EquipItem %s", client, itemKey);
			}
		}
	}

	char steamID[64], query[512];

	if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		return;
	}

	Format(query, sizeof(query), "SELECT i.itemKey, t.eqMode, pi.quantityUnitValue FROM d0s_playersitems AS pi INNER JOIN d0s_items AS i ON pi.itemID=i.itemID INNER JOIN d0s_types AS t ON t.typeID=i.typeID INNER JOIN d0s_players AS p ON pi.playerID=p.playerID WHERE p.steamID='%s'", steamID);
	//LogMessage("%N tquery_ReadPlayerEquippedItems %s", client, query);
	g_sqlConn.Query(tquery_ReadPlayerItemsNum, query, userID);
}

public void tquery_ReadPlayerItemsNum(Database db, DBResultSet results, const char[] error, any userID) {
	if (results == null) {
		LogError("tquery_ReadPlayerItemsNum error: %s", error);
		return;
	}

	int client = GetClientOfUserId(userID);

	if(!client) {
		return;
	}

	if(results.RowCount >= 0) {
		char itemKey[32];
		int itemID, eqMode, value, unixTime = GetTime(), expireTime, itemToDestroy, minExpireTime;

		while (results.MoreRows && results.FetchRow()) {
			results.FetchString(0, itemKey, sizeof(itemKey));
			itemID = g_itemKey.FindString(itemKey);
			eqMode = results.FetchInt(1);
			value = results.FetchInt(2);

			if(itemID >= 0) {
				g_plrItemQUValue.Set(itemID, value, client);

				if(eqMode != d0s_EQMode_Use) {
					expireTime = value - unixTime;

					if(expireTime <= 0) {
						DestroyItem(client, itemID);
					} else if(!itemToDestroy || expireTime < minExpireTime) {
						itemToDestroy = itemID;
						minExpireTime = expireTime;
					}
				}
			}
		}

		if(itemToDestroy) {
			DataPack dataPack = new DataPack();
			g_plrTimerNextItemToDestroy[client] = CreateDataTimer(float(minExpireTime+1), timer_DestroyItem, dataPack);

			dataPack.WriteCell(client);
			dataPack.WriteCell(itemToDestroy);
		}
	}

	g_isPlrDataLoaded[client][Q_CONN] = true;
}

public Action timer_DestroyItem(Handle timer, DataPack dataPack) {
	dataPack.Reset();

	int client = dataPack.ReadCell(), itemID = dataPack.ReadCell(), unixTime = GetTime();

	if(g_plrItemQUValue.Get(itemID, client) <= unixTime) {
		DestroyItem(client, itemID);
	}

	int itemsNum = g_itemName.Length, typeID, value, expireTime, minExpireTime, itemToDestroy;

	for(int i = 0; i < itemsNum; i++) {
		typeID = g_itemTypeID.Get(i);

		if (g_typeEquipMode.Get(typeID) != d0s_EQMode_Use || !(value = g_plrItemQUValue.Get(i, client)) || value > unixTime) {
			continue;
		}

		expireTime = value - unixTime;

		if(expireTime <= 0) {
			DestroyItem(client, itemID);
		} else if(!itemToDestroy || expireTime < minExpireTime) {
			itemToDestroy = i;
			minExpireTime = expireTime;
		}
	}

	if(itemToDestroy) {
		dataPack.Reset(true); //check it
		g_plrTimerNextItemToDestroy[client] = CreateDataTimer(float(minExpireTime+1), timer_DestroyItem, dataPack); //dodaj timer

		dataPack.WriteCell(client);
		dataPack.WriteCell(itemToDestroy);
	} else {
		g_plrTimerNextItemToDestroy[client] = null;
	}
}

void SavePlayerData(int client, char[] steamID, bool nonThreaded) {
	char query[2][512], itemKey[32], escapedItemKey[64];
	int itemsNum = g_itemName.Length, value;

	for(int i = 0; i < itemsNum; i++) {
		value = g_plrItemQUValue.Get(i, client);

		g_itemKey.GetString(i, itemKey, sizeof(itemKey));
		g_sqlConn.Escape(itemKey, escapedItemKey, sizeof(escapedItemKey));
		Format(query[0], sizeof(query[]), "UPDATE d0s_playersitems AS pi INNER JOIN d0s_players AS p ON pi.playerID=p.playerID INNER JOIN d0s_items AS i ON pi.itemID=i.itemID SET pi.quantityUnitValue=%d WHERE p.steamID='%s' AND i.itemKey='%s'", value, steamID, escapedItemKey);
	
		if(g_plrItemIsEquipped.Get(i, client)) {
			Format(query[1], sizeof(query[]), "INSERT INTO d0s_playerseqitems SELECT p.playerID, i.itemID FROM d0s_players AS p, d0s_items AS i WHERE p.steamID='%s' AND i.itemKey='%s' ON DUPLICATE KEY UPDATE itemID=VALUES(itemID)", steamID, escapedItemKey);
		} else {
			Format(query[1], sizeof(query[]), "DELETE pei.* FROM d0s_playerseqitems AS pei INNER JOIN d0s_players AS p ON pei.playerID=p.playerID INNER JOIN d0s_items AS i ON pei.itemID=i.itemID WHERE p.steamID='%s' AND i.itemKey='%s'", steamID, escapedItemKey);
		}

		//LogMessage("%N SavePlayerData(0) %s", client, query[0]);
		//LogMessage("%N SavePlayerData(1) %s", client, query[1]);

		if(nonThreaded) {
			if(!SQL_FastQuery(g_sqlConn, query[0]) || !SQL_FastQuery(g_sqlConn, query[1])) {
				char error[512];

				if(SQL_GetError(g_sqlConn, error, sizeof(error))) {
					LogError("tquery_SavePlayerData error: %s", error);
				}
			}
		} else {
			g_sqlConn.Query(tquery_SavePlayerData, query[0], 0);
			g_sqlConn.Query(tquery_SavePlayerData, query[1], 1);
		}
	}
}

public void tquery_SavePlayerData(Database db, DBResultSet results, const char[] error, any queryID) {
	if (results == null) {
		LogError("tquery_SavePlayerData(%d) error: %s", queryID, error);
	}
}

public Action cmd_ReloadItems(int args) {
	ReadItems();
	return Plugin_Handled;
}

void ReadItems() {
	char error[512], steamID[64];

	SQL_LockDatabase(g_sqlConn);

	for(int i = 1; i <= MaxClients; i++) {
		if(g_isPlrDataLoaded[i][Q_CONN] && GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			SavePlayerData(i, steamID, true);
		}
	}

	if (!SQL_FastQuery(g_sqlConn, "UPDATE d0s_items SET enabled = false")) {
		if(SQL_GetError(g_sqlConn, error, sizeof(error))) {
			LogError("ReadItems error: %s", error);
		}
	} else {
		g_itemName.Clear();
		g_itemTypeID.Clear();
		g_itemCategoryID.Clear();
		g_itemKey.Clear();
		g_itemDesc.Clear();
		g_itemData.Clear();
		g_plrItemQUValue.Clear();
		g_plrItemIsEquipped.Clear();

		for(int i = 0; i < d0s_MaxQUs; i++) {
			g_itemQUName[i].Clear();
			g_itemQUPrice[i].Clear();
			g_itemQUValue[i].Clear();
		}
		g_itemQUsNum.Clear();
		g_categoryName.Clear();

		char categoryName[64], itemName[64], itemKey[32], itemType[32], itemDesc[256], query[512];
		char escapedItemKey[64], escapedItemType[64], itemQUName[64];
		int categoryID, typeID, itemID, itemQUsNum, players[MAXPLAYERS+1];
		KeyValues keyValues = new KeyValues("Items");
		keyValues.ImportFromFile("addons/sourcemod/configs/d0_shop/items.cfg");
	 
		if (!keyValues.GotoFirstSubKey()) {
			LogError("Error in addons/sourcemod/configs/d0_shop/items.cfg KeyValues");
			delete keyValues;
			return;
		}

		do {
			keyValues.GetSectionName(categoryName, sizeof(categoryName));
			g_categoryName.PushString(categoryName);

			if (!keyValues.GotoFirstSubKey()) {
				continue;
			}

			do {
				keyValues.GetSectionName(itemName, sizeof(itemName));
				keyValues.GetString("key", itemKey, sizeof(itemKey));
				keyValues.GetString("type", itemType, sizeof(itemType));
				keyValues.GetString("desc", itemDesc, sizeof(itemDesc));

				typeID = g_typeKey.FindString(itemType);
				itemID = g_itemName.PushString(itemName);
				g_itemTypeID.Push(typeID);
				g_itemCategoryID.Push(categoryID);
				g_itemKey.PushString(itemKey);
				g_itemDesc.PushString(itemDesc);
				g_itemData.PushString("");
				g_plrItemQUValue.PushArray(players);
				g_plrItemIsEquipped.PushArray(players);

				Call_StartForward(g_fwOnItemCfgLoad_Post);
				Call_PushCell(typeID);
				Call_PushCell(categoryID);
				Call_PushCell(itemID);
				Call_PushCell(view_as<int>(keyValues));
				Call_Finish();

				g_sqlConn.Escape(itemKey, escapedItemKey, sizeof(escapedItemKey));
				g_sqlConn.Escape(itemType, escapedItemType, sizeof(escapedItemType));
				Format(query, sizeof(query), "INSERT INTO d0s_items (itemKey, typeID) SELECT '%s', typeID FROM d0s_types WHERE typeKey='%s' ON DUPLICATE KEY UPDATE typeID=(SELECT typeID FROM d0s_types WHERE typeKey='%s'), enabled=true", escapedItemKey, escapedItemType, escapedItemType);

				if (!SQL_FastQuery(g_sqlConn, query)) {
					if(SQL_GetError(g_sqlConn, error, sizeof(error))) {
						LogError("ReadItems error: %s", error);
					}

					break;
				}

				if (!keyValues.GotoFirstSubKey()) {
					continue;
				}

				itemQUsNum = 0;

				do {
					keyValues.GetSectionName(itemQUName, sizeof(itemQUName));

					if(itemQUsNum >= d0s_MaxQUs) {
						LogError("Too many item QUs for '%s'. QU '%s' won't be loaded" , itemKey, itemQUName);
						break;
					}

					keyValues.GetSectionName(itemQUName, sizeof(itemQUName));

					g_itemQUName[itemQUsNum].PushString(itemQUName);
					g_itemQUPrice[itemQUsNum].Push(keyValues.GetNum("price"));
					g_itemQUValue[itemQUsNum].Push(keyValues.GetNum("value"));

					itemQUsNum ++;
				} while (keyValues.GotoNextKey());

				g_itemQUsNum.Push(itemQUsNum);
				keyValues.GoBack();
			} while (keyValues.GotoNextKey());

			categoryID ++;
			keyValues.GoBack();
		} while (keyValues.GotoNextKey());

		delete keyValues;
	}

	SQL_UnlockDatabase(g_sqlConn);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			ReadPlayerData(i, steamID);
		}
	}

	Call_StartForward(g_fwOnAllItemsCfgLoad_Post);
	Call_Finish();
}

public int nat_RegisterType(Handle plugin, int paramsNum) {
	char typeKey[32], escapedTypeKey[64], query[512];
	GetNativeString(1, typeKey, sizeof(typeKey));

	if(g_typeKey.FindString(typeKey) >= 0) {
		LogError("d0s_RegisterType: Type '%s' is already registered!", typeKey);
		return -1;
	}

	int eqMode = GetNativeCell(2), typeID;

	typeID = g_typeKey.PushString(typeKey);
	g_typeEquipMode.Push(eqMode);

	g_sqlConn.Escape(typeKey, escapedTypeKey, sizeof(escapedTypeKey));
	Format(query, sizeof(query), "INSERT INTO d0s_types (typeKey, eqMode) VALUES ('%s', %d) ON DUPLICATE KEY UPDATE eqMode=%d", escapedTypeKey, eqMode, eqMode);

	SQL_LockDatabase(g_sqlConn);
	SQL_FastQuery(g_sqlConn, query);
	SQL_UnlockDatabase(g_sqlConn);

	if(g_allPluginsLoaded) {
		ReadItems();
	}

	return typeID;
}

public int nat_UnregisterType(Handle plugin, int paramsNum) {
	int typeID = GetNativeCell(1);

	g_typeKey.Erase(typeID);
	g_typeEquipMode.Erase(typeID);

	int itemsNum = g_itemName.Length, itemTypeID;

	for(int i = 0; i < itemsNum; i++) {
		if((itemTypeID = g_itemTypeID.Get(i)) >= typeID) {
			g_itemTypeID.Set(i, itemTypeID-1);
		}
	}

	if(g_allPluginsLoaded) {
		Call_StartForward(g_fwOnTypeLoad_Post);
		Call_PushCell(typeID);
		Call_Finish();
	}
}

public int nat_GetTypeKey(Handle plugin, int paramsNum) {
	char typeKey[32];

	g_typeKey.GetString(GetNativeCell(1), typeKey, sizeof(typeKey));
	SetNativeString(2, typeKey, GetNativeCell(3));
}

public int nat_GetTypeEQType(Handle plugin, int paramsNum) {
	return g_typeEquipMode.Get(GetNativeCell(1));
}

public int nat_GetTypeID(Handle plugin, int paramsNum) {
	char typeKey[32];

	GetNativeString(1, typeKey, sizeof(typeKey));
	return g_typeKey.FindString(typeKey);
}
	
public int nat_GetItemKey(Handle plugin, int paramsNum) {
	char itemKey[32];

	g_itemKey.GetString(GetNativeCell(1), itemKey, sizeof(itemKey));
	SetNativeString(2, itemKey, GetNativeCell(3));
}

public int nat_GetItemDesc(Handle plugin, int paramsNum) {
	char itemDesc[256];

	g_itemDesc.GetString(GetNativeCell(1), itemDesc, sizeof(itemDesc));
	SetNativeString(2, itemDesc, GetNativeCell(3));
}

public int nat_GetItemTypeID(Handle plugin, int paramsNum) {
	return g_itemTypeID.Get(GetNativeCell(1));
}

public int nat_GetItemID(Handle plugin, int paramsNum) {
	char itemKey[32];

	GetNativeString(1, itemKey, sizeof(itemKey));
	return g_itemKey.FindString(itemKey);
}

public int nat_SetItemData(Handle plugin, int paramsNum) {
	char data[512];

	GetNativeString(2, data, sizeof(data));
	g_itemData.SetString(GetNativeCell(1), data);
}

public int nat_GetItemData(Handle plugin, int paramsNum) {
	char data[512];

	g_itemData.GetString(GetNativeCell(1), data, sizeof(data));
	SetNativeString(2, data, GetNativeCell(3));
}

public int nat_IsItemEquipped(Handle plugin, int paramsNum) {
	return g_plrItemIsEquipped.Get(GetNativeCell(2), GetNativeCell(1));
}

public int nat_UseClientItem(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), itemID = GetNativeCell(2), typeID = g_itemTypeID.Get(itemID);

	if(g_typeEquipMode.Get(typeID) != d0s_EQMode_Use || g_plrItemQUValue.Get(itemID, client) <= 0) {
		return view_as<int>(false);
	}

	UseItem(client, itemID);
	return view_as<int>(true);
}

public int nat_EquipClientItem(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), itemID = GetNativeCell(2), typeID = g_itemTypeID.Get(itemID);

	if(g_typeEquipMode.Get(typeID) == d0s_EQMode_Use) {
		return view_as<int>(false);
	}

	if(g_plrItemIsEquipped.Get(itemID, client)) {
		return view_as<int>(true);
	}

	EquipItem(client, itemID);
	return view_as<int>(true);
}

public int nat_TakeoffClientItem(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), itemID = GetNativeCell(2), typeID = g_itemTypeID.Get(itemID);

	if(g_typeEquipMode.Get(typeID) == d0s_EQMode_Use) {
		return view_as<int>(false);
	}

	if(!g_plrItemIsEquipped.Get(itemID, client)) {
		return view_as<int>(true);
	}

	TakeoffItem(client, itemID);
	return view_as<int>(true);
}

public int nat_AreItemsLoaded(Handle plugin, int paramsNum) {
	return view_as<int>(g_allPluginsLoaded);
}

public int nat_GetItemsNum(Handle plugin, int paramsNum) {
	return g_itemName.Length;
}