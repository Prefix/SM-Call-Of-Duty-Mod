#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <csgocolors>
#include <CodD0_engine>

#define IsClientVip(%1) CheckCommandAccess(%1,"sm_accesstovip",ADMFLAG_CUSTOM1)
public Plugin myinfo = 
{
	name = "VIP",
	author = "d0naciak",
	description = "Adds special priorities to player",
	version = "1.0",
	url = "d0naciak.pl"
}

bool g_bBonusStatGraczaWczytany[MAXPLAYERS+1];
int g_iExpZaZabojstwo, g_iExpZaZabojstwoHS, g_iExpZaAsyste, g_iExpZaZemste, 
	g_iExpZaPodlozeniePaki, g_iExpZaRozbrojeniePaki, g_iExpZaHosta, 
	g_iExpZaWygranaRunde,
	g_iMonetyZaZabojstwo, g_iMonetyZaZabojstwoHS, g_iMonetyZaAsyste, 
	g_iMonetyZaZemste, g_iMonetyZaPodlozeniePaki, g_iMonetyZaRozbrojeniePaki, 
	g_iMonetyZaHosta, g_iMonetyZaWygranaRunde;

int g_offset_activeWeapon, g_offset_primaryAmmoType, g_offset_ammo;
public void OnPluginStart() {

	g_offset_ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_offset_activeWeapon = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	g_offset_primaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

	if (g_offset_ammo == -1 || g_offset_activeWeapon == -1 || g_offset_primaryAmmoType == -1) {
		SetFailState("Failed to retrieve entity member offsets");
	}

	HookEvent("player_team", event_WybralDruzynePost);
	HookEvent("player_spawn", event_OdrodzeniePost);
	HookEvent("player_death", event_SmiercPost);
	HookEvent("bomb_planted", event_BombaPodlozonaPost);
	HookEvent("bomb_defused", event_BombaRozbrojonaPost);
	HookEvent("hostage_rescued", event_HostUratowanyPost);
	HookEvent("round_end", event_KoniecRundyPost);
	HookEvent("weapon_fire", event_AtakBroniPost);

	RegConsoleCmd("sm_vip", cmd_OpisVipa, "shows vip's description");
}

public void OnConfigsExecuted() {
	g_iExpZaZabojstwo = RoundFloat(GetConVarFloat(FindConVar("cod_killxp")) * 0.5);
	g_iExpZaZabojstwoHS = RoundFloat(GetConVarFloat(FindConVar("cod_hsxp")) * 0.5);
	g_iExpZaAsyste = RoundFloat(GetConVarFloat(FindConVar("cod_assistxp")) * 0.5);
	g_iExpZaZemste = RoundFloat(GetConVarFloat(FindConVar("cod_revengexp")) * 0.5);
	g_iExpZaPodlozeniePaki = RoundFloat(GetConVarFloat(FindConVar("cod_plantbombxp")) * 0.5);
	g_iExpZaRozbrojeniePaki = RoundFloat(GetConVarFloat(FindConVar("cod_defusebombxp")) * 0.5);
	g_iExpZaHosta = RoundFloat(GetConVarFloat(FindConVar("cod_rescuehostagexp")) * 0.5);
	g_iExpZaWygranaRunde = RoundFloat(GetConVarFloat(FindConVar("cod_winroundxp")) * 0.5);

	g_iMonetyZaZabojstwo = RoundFloat(GetConVarFloat(FindConVar("cod_killcoins")) * 0.5);
	g_iMonetyZaZabojstwoHS = RoundFloat(GetConVarFloat(FindConVar("cod_hscoins")) * 0.5);
	g_iMonetyZaAsyste = RoundFloat(GetConVarFloat(FindConVar("cod_assistcoins")) * 0.5)
	g_iMonetyZaZemste = RoundFloat(GetConVarFloat(FindConVar("cod_revengecoins")) * 0.5);
	g_iMonetyZaPodlozeniePaki = RoundFloat(GetConVarFloat(FindConVar("cod_plantbombcoins")) * 0.5);
	g_iMonetyZaRozbrojeniePaki = RoundFloat(GetConVarFloat(FindConVar("cod_defusebombcoins")) * 0.5);
	g_iMonetyZaHosta = RoundFloat(GetConVarFloat(FindConVar("cod_rescuehostagcoins")) * 0.5);
	g_iMonetyZaWygranaRunde = RoundFloat(GetConVarFloat(FindConVar("cod_winroundcoins")) * 0.5);
}

public void OnClientPutInServer(int cId) {
	SDKHook(cId, SDKHook_OnTakeDamage, event_Obrazenia);
	g_bBonusStatGraczaWczytany[cId] = false;
}

public void OnClientDisconnect(int cId) {
	SDKUnhook(cId, SDKHook_OnTakeDamage, event_Obrazenia);
}

public void event_WybralDruzynePost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int cId = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!IsClientVip(cId) || g_bBonusStatGraczaWczytany[cId]) {
		return;
	}

	CodD0_SetClientBonusStatsPoints(cId, HEALTH_PTS, CodD0_GetClientBonusStatsPoints(cId, HEALTH_PTS) + 25);
	CodD0_SetClientBonusStatsPoints(cId, INT_PTS, CodD0_GetClientBonusStatsPoints(cId, INT_PTS) + 25);
	CodD0_SetClientBonusStatsPoints(cId, STAMINA_PTS, CodD0_GetClientBonusStatsPoints(cId, STAMINA_PTS) + 25);
	CodD0_SetClientBonusStatsPoints(cId, SPEED_PTS, CodD0_GetClientBonusStatsPoints(cId, SPEED_PTS) + 25);

	/*char szNick[64];

	GetClientName(cId, szNick, sizeof(szNick));
	SetHudTextParams(0.02, 0.4, 3.0, 14, 152, 174, 0, 2, 1.0, 0.05, 0.05);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			ShowHudText(i, -1, "VIP %s dołączył do gry!", szNick);
		}
	}*/

	g_bBonusStatGraczaWczytany[cId] = true;
}

public void event_OdrodzeniePost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int cId = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!IsClientVip(cId)) {
		return;
	}

	if(GetClientTeam(cId) == 3) {
		GivePlayerItem(cId, "item_defuser");
	}
}

public void event_SmiercPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	if(!IsXClientsInGame(5)) {
		return;
	}

	int cVic = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int cKil = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (!cKil || !IsClientInGame(cKil) || GetClientTeam(cKil) == GetClientTeam(cVic)) {
		return;
	}
	
	int cAss = GetClientOfUserId(GetEventInt(hEvent, "assister"));
	
	if (cAss && IsClientInGame(cAss) && CodD0_GetClientClass(cAss) || !IsClientVip(cAss)) {
		CodD0_SetClientExp(cAss, CodD0_GetClientExp(cAss) + g_iExpZaAsyste);
		CodD0_SetClientCoins(cAss, CodD0_GetClientCoins(cAss) + g_iMonetyZaAsyste);

		CPrintToChat(cAss, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} asyste", g_iExpZaAsyste, g_iMonetyZaAsyste);
	}
	
	if (!CodD0_GetClientClass(cKil) || !IsClientVip(cKil)) {
		return;
	}
	
	int iSumaXp = g_iExpZaZabojstwo, iSumaMonet = g_iMonetyZaZabojstwo;
	
	if (GetEventBool(hEvent, "headshot")) {
		iSumaXp += g_iExpZaZabojstwoHS;
		iSumaMonet += g_iMonetyZaZabojstwoHS;
	}
	
	if (GetEventInt(hEvent, "revenge")) {
		iSumaXp += g_iExpZaZemste;
		iSumaMonet += g_iMonetyZaZemste;
	}

	CodD0_SetClientExp(cKil, CodD0_GetClientExp(cKil) + iSumaXp);
	CodD0_SetClientCoins(cKil, CodD0_GetClientCoins(cKil) + iSumaMonet);

	CPrintToChat(cKil, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} zabójstwo", iSumaXp, iSumaMonet);
}

public void event_BombaPodlozonaPost(Handle hEvent, const char[] szNam, bool bDontBroadcast) {
	if(!IsXClientsInGame(5)) {
		return;
	}

	new cId = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!cId || !IsClientInGame(cId) || !CodD0_GetClientClass(cId) || !IsClientVip(cId)) {
		return;
	}

	CodD0_SetClientExp(cId, CodD0_GetClientExp(cId) + g_iExpZaPodlozeniePaki);
	CodD0_SetClientCoins(cId, CodD0_GetClientCoins(cId) + g_iMonetyZaPodlozeniePaki);

	CPrintToChat(cId, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} podłożenie paki", g_iExpZaPodlozeniePaki, g_iMonetyZaPodlozeniePaki);
}

public void event_BombaRozbrojonaPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	if(!IsXClientsInGame(5)) {
		return;
	}

	new cId = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!cId || !IsClientInGame(cId) || !CodD0_GetClientClass(cId) || !IsClientVip(cId)) {
		return;
	}

	CodD0_SetClientExp(cId, CodD0_GetClientExp(cId) + g_iExpZaRozbrojeniePaki);
	CodD0_SetClientCoins(cId, CodD0_GetClientCoins(cId) + g_iMonetyZaRozbrojeniePaki);

	CPrintToChat(cId, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} rozbrojenie paki", g_iExpZaRozbrojeniePaki, g_iMonetyZaRozbrojeniePaki);
}

public void event_HostUratowanyPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	if(!IsXClientsInGame(5)) {
		return;
	}

	new cId = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(!cId || !IsClientInGame(cId) || !CodD0_GetClientClass(cId) || !IsClientVip(cId)) {
		return;
	}

	CodD0_SetClientExp(cId, CodD0_GetClientExp(cId) + g_iExpZaHosta);
	CodD0_SetClientCoins(cId, CodD0_GetClientCoins(cId) + g_iMonetyZaHosta);

	CPrintToChat(cId, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} uratowanie zakładnika", g_iExpZaHosta, g_iMonetyZaHosta);
}

public void event_KoniecRundyPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	if(!IsXClientsInGame(5)) {
		return;
	}

	new iTeam = GetEventInt(hEvent, "winner");

	for(new cId = 1; cId <= MaxClients; cId++) {
		if(!IsClientInGame(cId) || !IsClientVip(cId)) {
			continue;
		}

		if(CodD0_GetClientClass(cId) && iTeam == GetClientTeam(cId)) {
			CodD0_SetClientExp(cId, CodD0_GetClientExp(cId) + g_iExpZaWygranaRunde);
			CodD0_SetClientCoins(cId, CodD0_GetClientCoins(cId) + g_iMonetyZaWygranaRunde);

			CPrintToChat(cId, "{purple}VIP: {yellow}+%dXP, +%d${normal} za{green} wygranie rundy", g_iExpZaWygranaRunde, g_iMonetyZaWygranaRunde);
		}
	}
}

public void event_AtakBroniPost(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client && IsPlayerAlive(client) && IsClientVip(client)) {
		int entity = GetEntDataEnt2(client, g_offset_activeWeapon);

		if (IsValidEdict(entity) && (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == entity || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == entity)) {
			int ammoType = GetEntData(entity, g_offset_primaryAmmoType);

			if (ammoType > 0) {
				SetEntData(client, g_offset_ammo + ammoType * 4, 200, 4, true);
			}
		}
	}
}

public Action event_Obrazenia(int cVic, int &cKil, int &iEnt, float &fObrazenia, int &iDmgType, int &iWeapon, const float fDmgForce[3], const float fDmgPos[3], int iDmgCustom)
{
	if(!cKil && iDmgType & DMG_FALL && IsClientVip(cVic)) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
/*
public void OnGameFrame() {
	static int iSkoki[MAXPLAYERS+1], iLastButtons[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && IsClientVip(i)) {
			int iFlags = GetEntityFlags(i), iButtons = GetClientButtons(i);
		
			if(iFlags & FL_ONGROUND) {
				iSkoki[i] = 2;
			} else if (!(iLastButtons[i] & IN_JUMP) && (iButtons & IN_JUMP) && iSkoki[i]) {
				iSkoki[i] --;
				
				decl Float:fVel[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", fVel);
				
				fVel[2] = 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, fVel);
			}
			
			iLastButtons[i] = iButtons;
		}
	}
}*/

public Action cmd_OpisVipa(int cId, int iArgs) {
	Menu mMenu = new Menu(OpisVipa_Handler, MENU_ACTIONS_ALL);
	
	mMenu.SetTitle("➫ Co posiada VIP?\n\n \
		✬ +50%% do zdobywanych monet\n \
		✬ +50%% do zdobywanego doświadczenia\n \
		✬ +25 do każdej statystyki\n \
		✬ nie traci obrażeń od upadków\n \
		✬ darmowy defuser co rundę\n \
		✬ nieskończona ilość magazynków\n\n \
		Aby zakupić VIP'a, użyj komendy !sklepsms \
		");
	
	mMenu.AddItem("", "");
	mMenu.Display(cId, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}


public int OpisVipa_Handler(Menu mMenu, MenuAction mAction, int iParam1, int iParam2) {
	if (mAction == MenuAction_End) {
		delete mMenu;
	}

	if (mAction == MenuAction_DrawItem) {
		return ITEMDRAW_SPACER;
	}

	return 0;
}

int IsXClientsInGame(int iIle) {
	int iIlosc;

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			if(++iIlosc >= iIle) {
				return 1;
			}

		}
	}

	return 0;
}