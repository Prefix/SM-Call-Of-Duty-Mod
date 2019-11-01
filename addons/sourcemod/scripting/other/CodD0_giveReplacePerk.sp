#include <sourcemod>
#include <clientprefs>
#include <CodD0_engine>

public Plugin myinfo = 
{
	name = "CODMOD: Oddaj & Wymień perk",
	author = "d0naciak",
	description = "Pozwala na oddawanie i wymianę perków",
	version = "1.0",
	url = "-"
}

bool g_bGraczMozeSieWymieniac[MAXPLAYERS + 1];
bool g_bBlokadaWymianyPerkow[MAXPLAYERS + 1];
Handle g_hCiasteczkoBlokadaWymiany;

public void OnPluginStart() {
	RegConsoleCmd("sm_daj", cmd_DajPerk, "give perk to selected player");
	RegConsoleCmd("sm_oddaj", cmd_DajPerk, "give perk to selected player");
	RegConsoleCmd("sm_wymien", cmd_WymienPerk, "replace perks with selected player");
	RegConsoleCmd("sm_zamien", cmd_WymienPerk, "replace perks with selected player");
	RegConsoleCmd("sm_wymiana", cmd_WymienPerk, "replace perks with selected player");
	RegConsoleCmd("sm_zamiana", cmd_WymienPerk, "replace perks with selected player");
	RegConsoleCmd("sm_bwymiane", cmd_BlokujWymianePerkow, "blocks trading with players");

	g_hCiasteczkoBlokadaWymiany = RegClientCookie("cod_blokadawymianyperkow", "Blokada wymiany perków", CookieAccess_Private);
	SetCookieMenuItem(cookie_WymianaPerkow, 0, "Blokada wymiany perków");
	//SetCookiePrefabMenu(g_hCiasteczkoBlokadaWymiany, CookieMenu_OnOff_Int, "Blokada wymiany perków", cookie_WymianaPerkow);

	HookEvent("round_start", event_StartRundyPost);

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !AreClientCookiesCached(i)) {
			continue;
		}

		OnClientCookiesCached(i);
		g_bGraczMozeSieWymieniac[i] = true;
	}
}

public void OnClientConnected(int cId) {
	g_bGraczMozeSieWymieniac[cId] = true;
}

public void OnClientCookiesCached(int cId) {
	char szWartosc[8];

	GetClientCookie(cId, g_hCiasteczkoBlokadaWymiany, szWartosc, sizeof(szWartosc));
	g_bBlokadaWymianyPerkow[cId] = StrEqual(szWartosc, "1");
}

public void cookie_WymianaPerkow(int cId, CookieMenuAction cAction, any info, char[] buffer, int iLen) {
	if(cAction == CookieMenuAction_SelectOption) {
		BlokujWymianePerkow(cId);
		ShowCookieMenu(cId);
	}
}

public event_StartRundyPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		g_bGraczMozeSieWymieniac[i] = true;
	}
}

public Action cmd_DajPerk(int cId, int iArgs) {
	if(!g_bGraczMozeSieWymieniac[cId]) {
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Następna wymiana będzie możliwa w kolejnej rundzie.");
		return Plugin_Handled;
	}

	if(!CodD0_GetClientPerk(cId)) {
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Musisz posiadać jakiś perk.");
		return Plugin_Handled;
	}

	Menu mMenu = new Menu(DajPerk_Handler, MENU_ACTIONS_ALL);
	mMenu.SetTitle("Komu chcesz przekazać perk?");
	
	char szNick[64], szUserId[8];

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || CodD0_GetClientPerk(i) || g_bBlokadaWymianyPerkow[i] || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
			continue;
		}

		GetClientName(i, szNick, sizeof(szNick));
		IntToString(GetClientUserId(i), szUserId, sizeof(szUserId));

		mMenu.AddItem(szUserId, szNick);
	}

	if(strlen(szNick) > 0) {
		mMenu.Display(cId, 300);
	} else {
		delete mMenu;
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Nie znaleziono gracza, który spełniałby kryteria.");
	}
	
	return Plugin_Handled;
}

public int DajPerk_Handler(Menu mMenu, MenuAction mAction, int iParam1, int iParam2) {
	switch (mAction) {
		case MenuAction_End: {
			delete mMenu;
		}
		
		case MenuAction_Select: {
			int cId = iParam1;

			char szInfo[8];
			mMenu.GetItem(iParam2, szInfo, sizeof(szInfo));
			int cTarget = GetClientOfUserId(StringToInt(szInfo));

			if(!cTarget) {
				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Gracz rozłączył się z serwerem.");
				cmd_DajPerk(cId, 0);
			} else {
				int iPerkId = CodD0_GetClientPerk(cId);

				if(!iPerkId) {
					PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Nie posiadasz żadnego perku.");
					cmd_DajPerk(cId, 0);
				} else {
					if(CodD0_GetClientPerk(cTarget)) {
						PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Gracz już posiada jakiś perk.");
						cmd_DajPerk(cId, 0);
					} else {
						if(!g_bGraczMozeSieWymieniac[cTarget]) {
							PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Ten gracz będzie mógł otrzymać perk dopiero w następnej rundzie.");
							cmd_DajPerk(cId, 0);
						} else {
							char szNick[2][64];

							GetClientName(cId, szNick[0], sizeof(szNick[]));
							GetClientName(cTarget, szNick[1], sizeof(szNick[]));

							int iWartoscPerku = CodD0_GetClientPerkValue(cId);
							CodD0_SetClientPerk(cId, 0, 0, false);
							CodD0_SetClientPerk(cTarget, iPerkId, iWartoscPerku, true);

							g_bGraczMozeSieWymieniac[cId] = false;
							g_bGraczMozeSieWymieniac[cTarget] = false;

							PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Przekazałeś perk\x0E %s", szNick[1]);
							PrintToChat(cTarget, " \x06\x04[COD:Wymiana]\x01 Otrzymałeś perk od\x0E %s", szNick[0]);
						}
					}
				}
			}
		}
	}
}


public Action cmd_WymienPerk(int cId, int iArgs) {
	if(!g_bGraczMozeSieWymieniac[cId]) {
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Następna wymiana będzie możliwa w kolejnej rundzie.");
		return Plugin_Handled;
	}

	if(!CodD0_GetClientPerk(cId)) {
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Musisz posiadać jakiś perk.");
		return Plugin_Handled;
	}

	Menu mMenu = new Menu(WymienPerk_Handler, MENU_ACTIONS_ALL);
	mMenu.SetTitle("Z kim chcesz się zamienić perkiem?");
	
	char szNick[64], szDane[16], szNazwaPerku[32], szItem[128];
	int iPerkId;

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !(iPerkId = CodD0_GetClientPerk(i)) || !g_bGraczMozeSieWymieniac[i] || g_bBlokadaWymianyPerkow[i] || i == cId || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
			continue;
		}

		GetClientName(i, szNick, sizeof(szNick));
		CodD0_GetPerkName(iPerkId, szNazwaPerku, 31);
		Format(szDane, sizeof(szDane), "%d_%d", GetClientUserId(i), iPerkId);
		Format(szItem, sizeof(szItem), "%s [%s]", szNick, szNazwaPerku);

		mMenu.AddItem(szDane, szItem);
	}
	
	if(strlen(szNick) > 0) {
		mMenu.Display(cId, 300);
	} else {
		delete mMenu;
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Nie znaleziono gracza, który spełniałby kryteria.");
	}

	return Plugin_Handled;
}

public int WymienPerk_Handler(Menu mMenu, MenuAction mAction, int iParam1, int iParam2) {
	switch (mAction) {
		case MenuAction_End: {
			delete mMenu;
		}
		
		case MenuAction_Select: {
			int cId = iParam1;

			char szInfo[32], szDane[2][8];
			mMenu.GetItem(iParam2, szInfo, sizeof(szInfo));
			ExplodeString(szInfo, "_", szDane, sizeof(szDane), sizeof(szDane[]));

			int cTarget = GetClientOfUserId(StringToInt(szDane[0]));

			if(!cTarget) {
				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Gracz rozłączył się z serwerem.");
				cmd_WymienPerk(cId, 0);
			} else {
				int iPerkId[2];

				iPerkId[0] = CodD0_GetClientPerk(cId);

				if(!iPerkId[0]) {
					PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Nie posiadasz żadnego perku.");
				} else {
					iPerkId[1] = StringToInt(szDane[1]);

					if(CodD0_GetClientPerk(cTarget) != iPerkId[1]) {
						PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Gracz zmienił perk.");
						cmd_WymienPerk(cId, 0);
					} else {
						if(!g_bGraczMozeSieWymieniac[cTarget]) {
							PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Ten gracz będzie mógł wymienić perk dopiero w następnej rundzie.");
							cmd_WymienPerk(cId, 0);
						} else {
							char szNick[64], szNazwaPerku[32];

							GetClientName(cId, szNick, sizeof(szNick));
							CodD0_GetPerkName(iPerkId[0], szNazwaPerku, sizeof(szNazwaPerku));

							Menu mPotwierdzWymianeMenu = new Menu(PotwierdzWymiane_Handler, MENU_ACTIONS_ALL);
							mPotwierdzWymianeMenu.SetTitle("Czy chcesz zamienić swój perk na %s (od %s)", szNazwaPerku, szNick);

							Format(szInfo, sizeof(szInfo), "%d_%d_%d", GetClientUserId(cId), iPerkId[0], iPerkId[1]);

							mPotwierdzWymianeMenu.AddItem("#", "#");
							mPotwierdzWymianeMenu.AddItem("#", "#");
							mPotwierdzWymianeMenu.AddItem("#", "#");
							mPotwierdzWymianeMenu.AddItem("#", "#");
							mPotwierdzWymianeMenu.AddItem(szInfo, "Tak");

							mPotwierdzWymianeMenu.Display(cTarget, 300);
						}
					}
				}
			}
		}
	}
}


public int PotwierdzWymiane_Handler(Menu mMenu, MenuAction mAction, int iParam1, int iParam2) {
	switch (mAction) {
		case MenuAction_End: {
			delete mMenu;
		}

		case MenuAction_DrawItem: {
			char szInfo[32];
			mMenu.GetItem(iParam2, szInfo, sizeof(szInfo));

			if(szInfo[0] == '#') {
				return ITEMDRAW_DISABLED;
			}
		}
		
		case MenuAction_Select: {
			int cId = iParam1;

			char szInfo[32];
			mMenu.GetItem(iParam2, szInfo, sizeof(szInfo));

			char szDane[3][8];
			ExplodeString(szInfo, "_", szDane, sizeof(szDane), sizeof(szDane[]));

			int cTarget = GetClientOfUserId(StringToInt(szDane[0]));
			int iPerkId[2];

			iPerkId[0] = StringToInt(szDane[2]);
			iPerkId[1] = StringToInt(szDane[1]);

			if(!cTarget) {
				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Gracz rozłączył się z serwerem.");
			} else if(CodD0_GetClientPerk(cId) != iPerkId[0] || CodD0_GetClientPerk(cTarget) != iPerkId[1]) {
				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Perki, które posiadacie są inne niż te, które mieliście wcześniej.");
				PrintToChat(cTarget, " \x06\x04[COD:Wymiana]\x01 Perki, które posiadacie są inne niż te, które mieliście wcześniej.");
				cmd_WymienPerk(cTarget, 0);
			} else if(!g_bGraczMozeSieWymieniac[cId] || !g_bGraczMozeSieWymieniac[cTarget]) {
				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Jeden z graczy dokonał już wymiany w tej rundzie.");
				//PrintToChat(cTarget, " \x06\x04[COD:Wymiana]\x01 Jeden z graczy dokonał już wymiany w tej rundzie.");
				cmd_WymienPerk(cTarget, 0);
			} else {
				char szNick[2][64];

				GetClientName(cId, szNick[0], sizeof(szNick[]));
				GetClientName(cTarget, szNick[1], sizeof(szNick[]));

				int iWartoscPerku[2];

				iWartoscPerku[0] = CodD0_GetClientPerkValue(cId);
				iWartoscPerku[1] = CodD0_GetClientPerkValue(cTarget);

				CodD0_SetClientPerk(cId, iPerkId[1], iWartoscPerku[1], true);
				CodD0_SetClientPerk(cTarget, iPerkId[0], iWartoscPerku[0], true);

				g_bGraczMozeSieWymieniac[cId] = false;
				g_bGraczMozeSieWymieniac[cTarget] = false;

				PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Wymieniłeś się perkiem z\x0E %s", szNick[1]);
				PrintToChat(cTarget, " \x06\x04[COD:Wymiana]\x01 Wymieniłeś się perkiem z\x0E %s", szNick[0]);
			}
		}
	}

	return 0;
}

public Action cmd_BlokujWymianePerkow(int cId, int iArgs) {
	if(!AreClientCookiesCached(cId)) {
		PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Trwa wczytywanie ciasteczek...");
		return Plugin_Handled;
	}

	BlokujWymianePerkow(cId);
	return Plugin_Handled;
}

void BlokujWymianePerkow(cId) {
	g_bBlokadaWymianyPerkow[cId] = !g_bBlokadaWymianyPerkow[cId];

	SetClientCookie(cId, g_hCiasteczkoBlokadaWymiany, g_bBlokadaWymianyPerkow[cId] ? "1" : "0");
	PrintToChat(cId, " \x06\x04[COD:Wymiana]\x01 Blokada wymiany perków:\x05 %s", g_bBlokadaWymianyPerkow[cId] ? "włączona" : "wyłączona");
}