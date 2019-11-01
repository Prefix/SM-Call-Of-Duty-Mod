#include <sourcemod>
#include <CodD0_engine>
#include <sdktools>

public Plugin myinfo =  {
	name = "COD: Market", 
	author = "d0naciak", 
	description = "Market with perks", 
	version = "1.0", 
	url = "d0naciak.pl"
};

//Engine data
Handle g_sqlConn;
ConVar g_cvMaxAuctions;

//Players data
int g_perkPrice[MAXPLAYERS+1];
bool g_playerDataLoaded[MAXPLAYERS+1];

public void OnPluginStart() {
	RegConsoleCmd("sm_rynek", cmd_Market);
	RegConsoleCmd("sm_rynek_cena", cmd_SetPrice);

	g_cvMaxAuctions = CreateConVar("cod_market_maxauctions", "3", "Max auctions per player");

	char error[512];
	g_sqlConn = SQL_Connect("CodMod_Market", true, error, sizeof(error));
	if(g_sqlConn == null) {
		SetFailState("Can't connect to MySQL server! Error: %s", error);
	}

	AutoExecConfig(true, "codmod_market");
	//OnMapStart();
}

public void OnConfigsExecuted() {
	char error[512], steamID[64];
	char createTablesQuery[][] = {
		"CREATE TABLE IF NOT EXISTS codd0market_players ( \
			playerID int NOT NULL AUTO_INCREMENT, \
			steamID varchar(64) NOT NULL, \
			name varchar(64) NOT NULL, \
			PRIMARY KEY (playerID), \
			UNIQUE (steamID) \
		);",

		"CREATE TABLE IF NOT EXISTS codd0market_auctions ( \
			auctionID int NOT NULL AUTO_INCREMENT, \
			playerID int NOT NULL, \
			perkName varchar(64) NOT NULL, \
			perkValue int DEFAULT 0, \
			price int NOT NULL, \
			PRIMARY KEY (auctionID) \
		);"
	}


	SQL_LockDatabase(g_sqlConn);
	if(!SQL_FastQuery(g_sqlConn, "DROP TABLE IF EXISTS auctions")/* || !SQL_FastQuery(g_sqlConn, "DROP TABLE IF EXISTS codd0market_players")*/ || !SQL_FastQuery(g_sqlConn, createTablesQuery[0]) || !SQL_FastQuery(g_sqlConn, createTablesQuery[1])) {
		SQL_GetError(g_sqlConn, error, sizeof(error));
		PrintToServer("Wystąbił błąd podczas tworzenia tabel! %s", error);
	}
	SQL_UnlockDatabase(g_sqlConn);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			ReadPlayerData(i, steamID);
		}
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	ReadPlayerData(client, auth);
}

void ReadPlayerData(int client, const char[] steamID) {
	char query[512];

	g_playerDataLoaded[client] = false;

	Format(query, sizeof(query), "SELECT COUNT(*) FROM codd0market_players WHERE steamID='%s'", steamID);
	SQL_TQuery(g_sqlConn, CheckIfPlayerExists_Handler, query, GetClientUserId(client));
}

public void CheckIfPlayerExists_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! CheckIfPlayerExists_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client || !SQL_MoreRows(result) || !SQL_FetchRow(result)) {
			return;
		}

		if(!SQL_FetchInt(result, 0)) {
			char query[512], steamID[64], name[64], escapedName[192];

			GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
			GetClientName(client, name, sizeof(name));
			SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));

			Format(query, sizeof(query), "INSERT INTO codd0market_players (steamID, name) VALUES ('%s', '%s')", steamID, escapedName);
			SQL_TQuery(g_sqlConn, InsertPlayerToDB_Handler, query, GetClientUserId(client));
		} else {
			char query[512], steamID[64], name[64], escapedName[192];

			GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
			GetClientName(client, name, sizeof(name));
			SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));

			Format(query, sizeof(query), "UPDATE codd0market_players SET name='%s' WHERE steamID='%s'", escapedName, steamID);
			SQL_TQuery(g_sqlConn, UpdatePlayerData_Handler, query, GetClientUserId(client));
		}
	}
}

public void InsertPlayerToDB_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! InsertPlayerToDB_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(client) {
			g_playerDataLoaded[client] = true;
		}
	}
}

public void UpdatePlayerData_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! UpdatePlayerData_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(client) {
			g_playerDataLoaded[client] = true;
		}
	}
}

public Action cmd_Market(int client, int args) {
	if(!g_playerDataLoaded[client]) {
		PrintToChat(client, " \x06\x04[RYNEK]\x01 Twoje dane nie zostały jeszcze wczytane.");
		return Plugin_Handled;
	}

	Menu menu = new Menu(MarketMenu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Rynek perków");

	menu.AddItem("", "★ Wystaw perk na rynek ★");
	menu.AddItem("", "★ Sprawdź rynek ★");

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MarketMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			switch(item) {
				case 0: {
					SellPerk(client);
				}

				case 1: {
					ShowAuctions(client);
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

void SellPerk(int client) {
	char query[512], steamID[64];

	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	Format(query, sizeof(query), "SELECT COUNT(*) FROM codd0market_auctions AS a INNER JOIN codd0market_players AS p ON a.playerID=p.playerID WHERE steamID='%s'", steamID);
	SQL_TQuery(g_sqlConn, GetPlayerAuctionsNum_Handler, query, GetClientUserId(client));
}

public void GetPlayerAuctionsNum_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! GetPlayerAuctionsNum_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client) {
			return;
		}

		if(SQL_MoreRows(result) && SQL_FetchRow(result)) {
			int limit = GetConVarInt(g_cvMaxAuctions), plrAuctionsNum = SQL_FetchInt(result, 0);

			if(plrAuctionsNum >= limit) {
				PrintToChat(client, " \x06\x04[RYNEK]\x01 Nie możesz już wystawić więcej przedmiotów\x0E (max. %d!)", limit);
			} else {
				g_perkPrice[client] = 0;
				SellPerk_FillData(client);
			}
		} else {
			PrintToChat(client, " \x06\x04[RYNEK]\x01 Błąd połączenia z bazą danych! Skontaktuj się z właścicielem serwera.");
		}
	}
}

void SellPerk_FillData(int client) {
	g_perkPrice[client] = 0;
	SellPerk_FillDataMenu(client);
}

void SellPerk_FillDataMenu(int client) {
	Menu menu = new Menu(SellPerk_FillDataMenu_Handler, MENU_ACTIONS_ALL);

	char perkName[64], perkDesc[256], perkValue[16];
	int perkID = CodD0_GetClientPerk(client);

	IntToString(CodD0_GetClientPerkValue(client), perkValue, sizeof(perkValue));
	CodD0_GetPerkName(perkID, perkName, sizeof(perkName));
	CodD0_GetPerkDesc(perkID, perkDesc, sizeof(perkDesc));
	ReplaceString(perkDesc, sizeof(perkDesc), "LW", perkValue);

	menu.SetTitle("➫ Wystaw perk:\n♦ Nazwa: %s\n♦ Opis: %s\n♦ Cena: %d", perkName, perkDesc, g_perkPrice[client]);

	menu.AddItem("", "★ Zmień cenę perku ★");
	menu.AddItem("", "★ Wystaw perk na rynek ★");

	menu.Display(client, MENU_TIME_FOREVER);
}

public Action cmd_SetPrice(int client, int args) {
	int price;
	char sPrice[32];

	GetCmdArg(1, sPrice, sizeof(sPrice));
	StripQuotes(sPrice);
	TrimString(sPrice);
	price = StringToInt(sPrice);

	if(price <= 0) {
		PrintToChat(client, " \x06\x04[RYNEK]\x01 Cena musi być większa od zera!");
	} else {
		g_perkPrice[client] = price;
		SellPerk_FillDataMenu(client);
	}

	return Plugin_Handled;
}

public int SellPerk_FillDataMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			switch(item) {
				case 0: {
					PrintToChat(client, " \x06\x04[RYNEK]\x01 Użyj komendy\x0E !rynek_cena XXX\x01, gdzie zamiast XXX wpisz cenę.");
					PrintToChat(client, " \x06\x04[RYNEK]\x01 Przykład:\x0E !rynek_cena 69");
				}

				case 1: {
					int perkID = CodD0_GetClientPerk(client);

					if(!perkID) {
						PrintToChat(client, " \x06\x04[RYNEK]\x01 Nie posiadasz żadnego perku!");
					} else {
						char query[512], perkName[64], steamID[64], escapedPerkName[192];
						DataPack dataPack = new DataPack();

						CodD0_SetClientPerk(client, 0, 0, false);

						dataPack.WriteCell(GetClientUserId(client));
						dataPack.WriteCell(perkID);

						GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
						CodD0_GetPerkName(perkID, perkName, sizeof(perkName));
						SQL_EscapeString(g_sqlConn, perkName, escapedPerkName, sizeof(escapedPerkName));

						Format(query, sizeof(query), "INSERT INTO codd0market_auctions (playerID, perkName, perkValue, price) SELECT playerID, '%s', %d, %d FROM codd0market_players WHERE steamID='%s'", escapedPerkName, CodD0_GetClientPerkValue(client), g_perkPrice[client], steamID);
						SQL_TQuery(g_sqlConn, InsertAuction_Handler, query, dataPack);
					}
				}
			}
		}
	}
}

public void InsertAuction_Handler(Handle sqlConn, Handle result, const char[] error, any data) {
	if (result == null) {
		LogError("MySQL Error! InsertAuction_Handler: %s", error);
	} else {
		DataPack dataPack = view_as<DataPack>(data);

		dataPack.Reset();
		int client = GetClientOfUserId(dataPack.ReadCell());

		if(!client) {
			return;
		}

		int perkID = dataPack.ReadCell();
		char perkName[64], name[64];

		CodD0_GetPerkName(perkID, perkName, sizeof(perkName));
		GetClientName(client, name, sizeof(name));

		PrintToChatAll(" \x06\x04[RYNEK]\x01 Gracz\x0E %s\x01 wystawił perk\x06 %s\x01 za\x0E %d$", name, perkName, g_perkPrice[client]);
		g_perkPrice[client] = 0;
	}
}

void ShowAuctions(int client) {
	SQL_TQuery(g_sqlConn, ShowAuctions_Handler, "SELECT auctionID, perkName, price FROM codd0market_auctions ORDER BY perkName, price DESC", GetClientUserId(client));
}


public void ShowAuctions_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! ShowAuctions_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client) {
			return;
		}

		if(SQL_GetRowCount(result) > 0) {
			Menu menu = new Menu(CheckAuction_Handler, MENU_ACTIONS_ALL);
			char item[128], perkName[64], auctionID[16];

			menu.SetTitle("➫ Lista aukcji");

			while(SQL_MoreRows(result)) {
				if(SQL_FetchRow(result)) {
					SQL_FetchString(result, 0, auctionID, sizeof(auctionID));
					SQL_FetchString(result, 1, perkName, sizeof(perkName));

					Format(item, sizeof(item), "★ %s [%d$] ★", perkName, SQL_FetchInt(result, 2));

					menu.AddItem(auctionID, item);
				}
			}

			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		} else {
			PrintToChat(client, " \x06\x04[RYNEK]\x01 Nie znaleziono żadnych perków!");
		}
	}
}

public int CheckAuction_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_End: {
			delete menu;
		}

		case MenuAction_Cancel: {
			if(item == MenuCancel_ExitBack) {
				cmd_Market(client, 0);
			}
		}

		case MenuAction_Select: {
			char auctionID[16], query[256];

			menu.GetItem(item, auctionID, sizeof(auctionID));
			Format(query, sizeof(query), "SELECT %s, a.perkName, a.perkValue, a.price, p.name FROM codd0market_auctions AS a INNER JOIN codd0market_players AS p ON a.playerID=p.playerID WHERE auctionID=%s", auctionID, auctionID);
			SQL_TQuery(g_sqlConn, ShowInfoAboutAuction_Handler, query, GetClientUserId(client));
		}
	}
}

public void ShowInfoAboutAuction_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! ShowInfoAboutAuction_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client) {
			return;
		}

		if(SQL_GetRowCount(result) > 0 && SQL_MoreRows(result) && SQL_FetchRow(result)) {
			Menu menu = new Menu(CheckAuctionMenu_Handler, MENU_ACTIONS_ALL);
			char perkName[64], perkDesc[256], perkValue[16], auctionID[16], name[64];
			int perkID;

			SQL_FetchString(result, 0, auctionID, sizeof(auctionID));
			SQL_FetchString(result, 1, perkName, sizeof(perkName));
			SQL_FetchString(result, 2, perkValue, sizeof(perkValue));
			SQL_FetchString(result, 4, name, sizeof(name));
			perkID = CodD0_GetPerkID(perkName);
			CodD0_GetPerkDesc(perkID, perkDesc, sizeof(perkDesc));
			ReplaceString(perkDesc, sizeof(perkDesc), "LW", perkValue);

			menu.SetTitle("♦ Perk: %s\n♦ Opis: %s\n♦ Cena: %d$\n♦ Wystawił: %s", perkName, perkDesc, SQL_FetchInt(result, 3), name);

			menu.AddItem(auctionID, "★ Kup perk ★");

			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		} else {
			PrintToChat(client, " \x06\x04[RYNEK]\x01 Błąd połączenia z bazą danych! Skontaktuj się z właścicielem serwera.");
		}
	}
}

public int CheckAuctionMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_End: {
			delete menu;
		}

		case MenuAction_Cancel: {
			if(item == MenuCancel_ExitBack) {
				ShowAuctions(client);
			}
		}

		case MenuAction_Select: {
			char auctionID[16], query[256];

			menu.GetItem(item, auctionID, sizeof(auctionID));
			Format(query, sizeof(query), "SELECT a.auctionID, a.perkName, a.perkValue, a.price, p.steamID FROM codd0market_auctions AS a INNER JOIN codd0market_players AS p ON a.playerID=p.playerID WHERE auctionID=%s ", auctionID);
			SQL_TQuery(g_sqlConn, BuyPerk_ChechIfExists_Handler, query, GetClientUserId(client));
		}
	}
}

public void BuyPerk_ChechIfExists_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! BuyPerk_ChechIfExists_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client) {
			return;
		}

		if(SQL_GetRowCount(result) > 0 && SQL_MoreRows(result) && SQL_FetchRow(result)) {
			int price = SQL_FetchInt(result, 3), plrCoins = CodD0_GetClientCoins(client);

			if(price > plrCoins) {
				PrintToChat(client, " \x06\x04[RYNEK]\x01 Nie stać Cię na ten perk!");
			} else {
				char perkName[64], steamID[64], query[256];
				int perkID, sellerID;

				SQL_FetchString(result, 1, perkName, sizeof(perkName));
				SQL_FetchString(result, 4, steamID, sizeof(steamID));
				perkID = CodD0_GetPerkID(perkName);
				sellerID = GetTargetBySID(steamID);

				if(sellerID) {
					CodD0_SetClientCoins(sellerID, CodD0_GetClientCoins(sellerID) + price);
					PrintToChat(client, " \x06\x04[RYNEK]\x01 Twój perk\x0E %s\x01 został właśnie sprzedany za\x0E %d$", perkName, price);
				}

				CodD0_SetClientPerk(client, perkID, SQL_FetchInt(result, 2), false);
				CodD0_SetClientCoins(client, plrCoins - price);

				PrintToChat(client, " \x06\x04[RYNEK]\x01 Perk został kupiony! :)");

				Format(query, sizeof(query), "DELETE FROM codd0market_auctions WHERE auctionID=%d", SQL_FetchInt(result, 0));
				SQL_TQuery(g_sqlConn, BuyPerk_RemoveAuction_Handler, query);
			}
		} else {
			PrintToChat(client, " \x06\x04[RYNEK]\x01 Błąd połączenia z bazą danych! Skontaktuj się z właścicielem serwera.");
		}
	}
}

public void BuyPerk_RemoveAuction_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! BuyPerk_RemoveAuction_Handler: %s", error);
	}
}

int GetTargetBySID(const char[] steamID) {
	char plrSteamID[64];

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, plrSteamID, sizeof(plrSteamID)) && StrEqual(steamID, plrSteamID)) {
			return i;
		}
	}

	return 0;
}