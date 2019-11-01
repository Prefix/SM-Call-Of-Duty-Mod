#include <sourcemod>
#include <CodD0_engine>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =  {
	name = "COD: Clans", 
	author = "d0naciak", 
	description = "", 
	version = "1.0", 
	url = "d0naciak.pl"
};

#define MAX_CLANNAME_LENGTH 64
#define GetMaxClanMembers(%1) (GetConVarInt(g_cvStartMembersLimit)+%1*GetConVarInt(g_cvStatMultiplier[MEMBERS]))

//Clans data
int g_clanID[MAXPLAYERS+1];
int g_clanExp[MAXPLAYERS+1];
int g_clanCoins[MAXPLAYERS+1];
int g_clanLevel[MAXPLAYERS+1];
char g_clanName[MAXPLAYERS+1][MAX_CLANNAME_LENGTH];

#define WARSTAT_LOSES 0
#define WARSTAT_WINS 1
#define WARSTAT_DRAWS 2
int g_clanWar_oppnntClanID[MAXPLAYERS+1];
int g_clanWar_oppnntOnlineClanID[MAXPLAYERS+1];
char g_clanWar_oppnntClanName[MAXPLAYERS+1][MAX_CLANNAME_LENGTH];
int g_clanWar_frags[MAXPLAYERS+1][2];
int g_clanWar_endTime[MAXPLAYERS+1];
Handle g_clanWar_timer[MAXPLAYERS+1];
int g_clanWar_stats[MAXPLAYERS+1][3];
bool g_clanWar_block[MAXPLAYERS+1];

#define TO_ASSIGN 0
#define VITALITY 1
#define DAMAGE 2
#define STAMINA 3
#define SPEED 4
#define WEALTH 5
#define EXP 6
#define MEMBERS 7
#define MAXSTATS 8

//enum ClanStat { TO_ASSIGN = 0, VITALITY = 1, DAMAGE, STAMINA, SPEED, WEALTH, EXP, MAXSTATS };
int g_clanStats[MAXPLAYERS+1][MAXSTATS];

int g_playerBonusHealth[MAXPLAYERS+1];
int g_playerBonusSpeed[MAXPLAYERS+1];

//Players data
#define QUERY_CONNECT 0
#define QUERY_ANOTHER 1
#define MAXQUERIES 2
//enum ClanQuery { QUERY_CONNECT = 0, QUERY_ANOTHER, MAXQUERIES };
bool g_isPlayerDataProcessing[MAXPLAYERS+1][MAXQUERIES];

#define MEMBER 0
#define ASSISTANT 1
#define OWNER 2
//enum ClanRank { MEMBER = 0, ASSISTANT, OWNER };
int g_plrOnlineClanID[MAXPLAYERS+1];
int g_plrClanRankID[MAXPLAYERS+1];

int g_lastOfferedClanID[MAXPLAYERS+1];

//SM Data
Handle g_sqlConn;
ConVar g_cvRequiredLevel;
ConVar g_cvRequireCoins;
ConVar g_cvPaymentsSumForPermMember;
ConVar g_cvStartMembersLimit;
ConVar g_cvWarTime;
ConVar g_cvWonWarCoinsBaseAward;
ConVar g_cvWonWarCoinsAwardPerFrag;
ConVar g_cvLostWarCoinsBaseAward;
ConVar g_cvLostWarCoinsAwardPerFrag;
ConVar g_cvStatUpgradePrice[MAXSTATS];
ConVar g_cvStatMultiplier[MAXSTATS];
ConVar g_cvMaxStat[MAXSTATS];

bool g_pluginIsUnloading;
int g_warTime;
Handle g_warHud;

public void OnPluginStart() {
	HookEvent("player_death", ev_PlayerDeath_Post);

	RegConsoleCmd("sm_klany", cmd_Clans);
	RegConsoleCmd("sm_klan", cmd_Clans);
	RegConsoleCmd("sm_clans", cmd_Clans);
	RegConsoleCmd("sm_clan", cmd_Clans);
	RegConsoleCmd("sm_klan_nazwa", cmd_CreateClan);
	RegConsoleCmd("sm_clan_name", cmd_CreateClan);

	g_cvRequiredLevel = CreateConVar("cod_clans_reqlvl", "25", "Required level to create clan");
	g_cvRequireCoins = CreateConVar("cod_clans_reqcoins", "250", "Required coins to create clan");

	g_cvPaymentsSumForPermMember = CreateConVar("cod_clans_paymentssumforpermmember", "250", "After paying setted count of coins, player can't be removed from clan by anyone else than him");
	g_cvStartMembersLimit = CreateConVar("cod_clansstartmemberslimit", "4", "How many members can be in clan on the start?");	
	
	g_cvWarTime = CreateConVar("cod_wartime", "300", "Time of clan war?");
	g_cvWonWarCoinsBaseAward = CreateConVar("cod_wonwarcoinsbaseaward", "20", "Base coins award for winning war");
	g_cvWonWarCoinsAwardPerFrag = CreateConVar("cod_wonwarcoinsawardperfrag", "0.1", "Coins award per frag for winning war");
	g_cvLostWarCoinsBaseAward = CreateConVar("cod_lostwarcoinsbaseaward", "5", "Base coins award for losing war");
	g_cvLostWarCoinsAwardPerFrag = CreateConVar("cod_lostwarcoinsawardperfrag", "0.05", "Coins award per frag for losing war");

	g_cvStatUpgradePrice[VITALITY] = CreateConVar("cod_clans_vitalityprice", "100", "Price to level up vitality stat");
	g_cvStatUpgradePrice[DAMAGE] = CreateConVar("cod_clans_damageprice", "100", "Price to level up damage stat");
	g_cvStatUpgradePrice[STAMINA] = CreateConVar("cod_clans_staminaprice", "100", "Price to level up stamina stat");
	g_cvStatUpgradePrice[SPEED] = CreateConVar("cod_clans_speedprice", "100", "Price to level up speed stat");
	g_cvStatUpgradePrice[WEALTH] = CreateConVar("cod_clans_wealthprice", "100", "Price to level up wealth stat");
	g_cvStatUpgradePrice[EXP] = CreateConVar("cod_clans_expprice", "100", "Price to level up experience stat");
	g_cvStatUpgradePrice[MEMBERS] = CreateConVar("cod_clans_membersprice", "100", "Price to level up members stat");
	g_cvStatMultiplier[VITALITY] = CreateConVar("cod_clans_vitalitymultiplier", "4.0", "How many HP per point will get players in a clan?");
	g_cvStatMultiplier[DAMAGE] = CreateConVar("cod_clans_damagemultiplier", "0.6", "How many damage per point will players in clan take more?");
	g_cvStatMultiplier[STAMINA] = CreateConVar("cod_clans_staminamultiplier", "0.6", "How many damage per point will players in clan get less?");
	g_cvStatMultiplier[SPEED] = CreateConVar("cod_clans_speedmultiplier", "4.0", "How many speed per point will get players in a clan?");
	g_cvStatMultiplier[WEALTH] = CreateConVar("cod_clans_wealthmultiplier", "0.3", "How many coins per point will get players in a clan for killing?");
	g_cvStatMultiplier[EXP] = CreateConVar("cod_clans_expmultiplier", "20", "How many experience per point will get players in a clan for killing?");
	g_cvStatMultiplier[MEMBERS] = CreateConVar("cod_clans_membersmultiplier", "1", "How many members per point will be able to be in the clan?");
	g_cvMaxStat[VITALITY] = CreateConVar("cod_clans_maxvitality", "10", "Max. value of vitality stat that clan can reach");
	g_cvMaxStat[DAMAGE] = CreateConVar("cod_clans_maxdamage", "10", "Max. value of damage stat that clan can reach");
	g_cvMaxStat[STAMINA] = CreateConVar("cod_clans_maxstamina", "10", "Max. value of stamina stat that clan can reach");
	g_cvMaxStat[SPEED] = CreateConVar("cod_clans_maxspeed", "10", "Max. value of speed stat that clan can reach");
	g_cvMaxStat[WEALTH] = CreateConVar("cod_clans_maxwealth", "10", "Max. value of wealth stat that clan can reach");
	g_cvMaxStat[EXP] = CreateConVar("cod_clans_maxexp", "10", "Max. value of experience stat that clan can reach");
	g_cvMaxStat[MEMBERS] = CreateConVar("cod_clans_maxmembers", "10", "Max. value of members stat that clan can reach");
	
	AutoExecConfig(true, "codmod_clans");
	g_clanName[0] = "Brak";

	char error[512];
	char query[][] = {
		"CREATE TABLE IF NOT EXISTS codd0clans_player ( \
			playerID int NOT NULL AUTO_INCREMENT, \
			steamID varchar(64) NOT NULL, \
			name varchar(64) NOT NULL, \
			clanID int NOT NULL DEFAULT 0, \
			clanRankID int NOT NULL DEFAULT 0, \
			paymentsSum int NOT NULL DEFAULT 0, \
			PRIMARY KEY (playerID), \
			UNIQUE (steamID) \
		) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

		"CREATE TABLE IF NOT EXISTS codd0clans_clans ( \
			clanID int NOT NULL AUTO_INCREMENT, \
			name varchar(64) NOT NULL, \
			experience int NOT NULL DEFAULT 0, \
			coins int NOT NULL DEFAULT 0, \
			opponentClanID int NOT NULL DEFAULT 0, \
			fragsOnWar int NOT NULL DEFAULT 0, \
			warEndTime int NOT NULL DEFAULT 0, \
			warBlock boolean NOT NULL DEFAULT false, \
			lostWars int NOT NULL DEFAULT 0, \
			wonWars int NOT NULL DEFAULT 0, \
			drawedWars int NOT NULL DEFAULT 0, \
			statVitality int NOT NULL DEFAULT 0, \
			statDamage int NOT NULL DEFAULT 0, \
			statStamina int NOT NULL DEFAULT 0, \
			statSpeed int NOT NULL DEFAULT 0, \
			statWealth int NOT NULL DEFAULT 0, \
			statExperience int NOT NULL DEFAULT 0, \
			statMembers int NOT NULL DEFAULT 0, \
			PRIMARY KEY (clanID) \
		) ENGINE = InnoDB DEFAULT CHARSET = utf8;"
	};
	g_sqlConn = SQL_Connect("CodMod_clans", true, error, sizeof(error));

	if (g_sqlConn == null) {
		PrintToServer("CodMod Clans SQL: Can't connect to DB! Error: %s", error);
		SetFailState("Can't connect to DB");
		return;
	} else {
		SQL_LockDatabase(g_sqlConn);

		if (SQL_FastQuery(g_sqlConn, query[0]) && SQL_FastQuery(g_sqlConn, query[1])) {
			PrintToServer("CodMod Clans SQL: Tables has been created :)");
		} else {
			if (SQL_GetError(g_sqlConn, error, sizeof(error))) {
				PrintToServer("CodMod Clans SQL: Problem while creating tables! Error: %s", error);
			}
		}

		SQL_UnlockDatabase(g_sqlConn);
	}

	char steamID[64];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			OnClientAuthorized(i, steamID);
		}

		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}

	g_warHud = CreateHudSynchronizer();
}

public void OnMapStart() {
	for(int i = 1; i <= MaxClients; i++) {
		g_clanWar_oppnntClanID[i] = 0;
		g_clanWar_oppnntOnlineClanID[i] = 0;
		g_clanWar_timer[i] = null;
	}

	char query[512];

	Format(query, sizeof(query), "UPDATE codd0clans_clans SET opponentClanID=0, fragsOnWar=0, warEndTime=0");
	SQL_TQuery(g_sqlConn, UpdateClanDataAfterWar_Handler, query, 0, DBPrio_High);
}

public void OnConfigsExecuted() {
	g_warTime = GetConVarInt(g_cvWarTime);
}

public void OnPluginEnd() {
	g_pluginIsUnloading = true;

	SQL_LockDatabase(g_sqlConn);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientDisconnect(i);
		}
	}
	SQL_UnlockDatabase(g_sqlConn);

	delete g_sqlConn;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	CreateNative("CodD0_GetClientClanName", nat_GetClientClanname);
}

public int nat_GetClientClanname(Handle plugin, int paramsNum) {
	SetNativeString(2, g_clanName[g_plrOnlineClanID[GetNativeCell(1)]], GetNativeCell(3));
}

public void OnClientAuthorized(int client, const char[] auth) {
	char query[512];

	g_isPlayerDataProcessing[client][QUERY_CONNECT] = true;
	g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;
	g_plrOnlineClanID[client] = 0;
	g_plrClanRankID[client] = 0;
	g_playerBonusHealth[client] = 0;
	g_playerBonusSpeed[client] = 0;

	Format(query, sizeof(query), "SELECT clanID, clanRankID FROM codd0clans_player WHERE steamID='%s'", auth);
	SQL_TQuery(g_sqlConn, ReadPlayerData_Handler, query, GetClientUserId(client));
}

public void ReadPlayerData_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! ReadPlayerData_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if (!client) {
			return;
		}

		if (SQL_GetRowCount(result) > 0 && SQL_MoreRows(result) && SQL_FetchRow(result)) {
			if (ReadPlayerClanData(client, SQL_FetchInt(result, 0))) {
				g_isPlayerDataProcessing[client][QUERY_CONNECT] = false;
			}

			g_plrClanRankID[client] = SQL_FetchInt(result, 1);
		} else {
			g_isPlayerDataProcessing[client][QUERY_CONNECT] = false;
		}
	}
}


public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

	if (g_plrOnlineClanID[client]) {
		char query[512], error[512], steamID[64];
		bool saveClanData = true;

		if (GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
			char name[64], escapedName[192];

			GetClientName(client, name, sizeof(name));
			SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));

			Format(query, sizeof(query), "UPDATE codd0clans_player SET name='%s' WHERE steamID='%s'", escapedName, steamID);
				
			if(g_pluginIsUnloading) {
				if(!SQL_FastQuery(g_sqlConn, query) && SQL_GetError(g_sqlConn, error, sizeof(error))) {
					LogError("MySQL Error! UpdatePlayerData_Handler: %s", error);
				}
			} else {
				SQL_TQuery(g_sqlConn, UpdatePlayerData_Handler, query);
			}
		}

		for (int i = 1; i <= MaxClients; i++) {
			if (i != client && g_plrOnlineClanID[i] == g_plrOnlineClanID[client]) {
				saveClanData = false;
				break;
			}
		}

		if (saveClanData) {
			int onlineClanID = g_plrOnlineClanID[client];

			Format(query, sizeof(query), "UPDATE codd0clans_clans SET name='%s', experience=%d, coins=%d, opponentClanID=%d, fragsOnWar=%d, warEndTime=%d, warBlock=%s, wonWars=%d, drawedWars=%d, lostWars=%d, statVitality=%d, statDamage=%d, statStamina=%d, statSpeed=%d, statWealth=%d, statExperience=%d, statMembers=%d WHERE clanID=%d",
					g_clanName[onlineClanID], g_clanExp[onlineClanID], g_clanCoins[onlineClanID], g_clanWar_oppnntClanID[onlineClanID], g_clanWar_frags[onlineClanID][0], g_clanWar_endTime[onlineClanID], g_clanWar_block[onlineClanID] ? "true" : "false", g_clanWar_stats[onlineClanID][WARSTAT_WINS], g_clanWar_stats[onlineClanID][WARSTAT_DRAWS], 
					g_clanWar_stats[onlineClanID][WARSTAT_LOSES], g_clanStats[onlineClanID][VITALITY], g_clanStats[onlineClanID][DAMAGE], g_clanStats[onlineClanID][STAMINA], g_clanStats[onlineClanID][SPEED], g_clanStats[onlineClanID][WEALTH], g_clanStats[onlineClanID][EXP], g_clanStats[onlineClanID][MEMBERS], g_clanID[onlineClanID]);
			
			if (g_pluginIsUnloading) {
				if (!SQL_FastQuery(g_sqlConn, query) && SQL_GetError(g_sqlConn, error, sizeof(error))) {
					LogError("MySQL Error! UpdateClanData_Handler: %s", error);
				}
			} else {
				SQL_TQuery(g_sqlConn, UpdateClanData_Handler, query);
			}

			if(g_clanWar_oppnntClanID[onlineClanID]) {
				int oppnntOnlineClanID = g_clanWar_oppnntOnlineClanID[onlineClanID];

				if(oppnntOnlineClanID) {
					g_clanWar_oppnntOnlineClanID[oppnntOnlineClanID] = 0;
				}

				if(g_clanWar_timer[onlineClanID] != null) {
					KillTimer(g_clanWar_timer[onlineClanID]);
					g_clanWar_timer[onlineClanID] = null;
				}
			}

			g_clanID[onlineClanID] = 0;
		}

		g_plrOnlineClanID[client] = 0;
		g_plrClanRankID[client] = 0;
	}
}

public void UpdatePlayerData_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! UpdatePlayerData_Handler: %s", error);
	}
}

public void UpdateClanData_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! UpdateClanData_Handler: %s", error);
	}
}

public void ev_PlayerDeath_Post(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if (!attacker || !CodD0_GetClientClass(attacker) || GetClientTeam(client) == GetClientTeam(attacker)) {
		return;
	}

	int onlineClanID = g_plrOnlineClanID[attacker];

	if (!onlineClanID) {
		return;
	}

	if(g_clanWar_oppnntClanID[onlineClanID]) {
		g_clanWar_frags[onlineClanID][0] ++;

		int oppnntOnlineClanID = g_clanWar_oppnntOnlineClanID[onlineClanID];

		if(oppnntOnlineClanID) {
			g_clanWar_frags[oppnntOnlineClanID][1] ++;
		}
	}

	int coinsForFrag = RoundFloat(float(g_clanStats[onlineClanID][WEALTH]) * GetConVarFloat(g_cvStatMultiplier[WEALTH]));
	int expForFrag = RoundFloat(float(g_clanStats[onlineClanID][EXP]) * GetConVarFloat(g_cvStatMultiplier[EXP]));

	CodD0_SetClientCoins(attacker, CodD0_GetClientCoins(attacker) + coinsForFrag);
	CodD0_SetClientExp(attacker, CodD0_GetClientExp(attacker) + expForFrag);

	PrintToChat(attacker, " \x06\x05\x0EKlan:\x05 +%dXP, +%d$\x01 za\x04 zabójstwo", expForFrag, coinsForFrag);
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (weapon == -1 || !(damageType & DMG_BULLET) || attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return Plugin_Continue;
	}

	float newDamage = damage;
	if (g_plrOnlineClanID[attacker]) {
		int onlineClanID = g_plrOnlineClanID[attacker];

		if (g_clanStats[onlineClanID][DAMAGE] > 0) {
			newDamage += float(g_clanStats[onlineClanID][DAMAGE]) * GetConVarFloat(g_cvStatMultiplier[DAMAGE]);
		}
	}

	if (g_plrOnlineClanID[victim]) {
		int onlineClanID = g_plrOnlineClanID[victim];

		if (g_clanStats[onlineClanID][STAMINA] > 0) {
			newDamage -= float(g_clanStats[onlineClanID][STAMINA]) * GetConVarFloat(g_cvStatMultiplier[STAMINA]);
		}
	}

	if (newDamage != damage) {
		damage = newDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void ev_Spawn_Post(int client) {
	if (!IsPlayerAlive(client)) {
		return;
	}

	int onlineClanID = g_plrOnlineClanID[client];

	if (!onlineClanID) {
		return;
	}

	int bonusHealth = RoundFloat(float(g_clanStats[onlineClanID][VITALITY]) * GetConVarFloat(g_cvStatMultiplier[VITALITY]));
	int bonusSpeed = RoundFloat(float(g_clanStats[onlineClanID][SPEED]) * GetConVarFloat(g_cvStatMultiplier[SPEED]));
	
	if (bonusHealth != g_playerBonusHealth[client]) {
		CodD0_SetClientBonusStatsPoints(client, HEALTH_PTS, CodD0_GetClientBonusStatsPoints(client, HEALTH_PTS) + (bonusHealth - g_playerBonusHealth[client]));
		g_playerBonusHealth[client] = bonusHealth;
	}

	if (bonusSpeed != g_playerBonusSpeed[client]) {
		CodD0_SetClientBonusStatsPoints(client, SPEED_PTS, CodD0_GetClientBonusStatsPoints(client, SPEED_PTS) + (bonusSpeed - g_playerBonusSpeed[client]));
		g_playerBonusSpeed[client] = bonusSpeed;
	}
}

public Action cmd_Clans(int client, int args) {
	if (IsPlayerDataProcessing(client, true)) {
		return Plugin_Handled;
	}

	Menu menu = new Menu(MainClansMenu_Handler, MENU_ACTIONS_ALL);
	menu.SetTitle("➫ Główne menu klanów")

	menu.AddItem("", g_plrOnlineClanID[client] ? "★ Mój klan ★" : "★ Stwórz klan ★");
	menu.AddItem("", "★ TOP 15 Klanów ★");
	menu.AddItem("", "★ Pomoc - jak działają klany? ★");

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MainClansMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			switch(item) {
				case 0: {
					if (g_plrOnlineClanID[client]) {
						MyClanMenu(client);
					} else {
						CreateClan(client);
					}
				}

				case 1: {
					Top15Clans(client);
				}

				case 2: {
					Help(client);
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

void CreateClan(int client) {
	if (g_plrOnlineClanID[client]) {
		return;
	}

	int requiredLevel = GetConVarInt(g_cvRequiredLevel);
	if (CodD0_GetClientLevel(client) < requiredLevel) {
		PrintToChat(client, " \x04\x06[KLANY]\x01 Aby założyć klan, musisz posiadać min.\x0E %dLv!", requiredLevel);
		return;
	}

	int requiredCoins = GetConVarInt(g_cvRequireCoins);
	if (CodD0_GetClientCoins(client) < requiredCoins) {
		PrintToChat(client, " \x04\x06[KLANY]\x01 Aby założyć klan, musisz posiadać min.\x0E %d$!", requiredCoins);
		return;
	}

	PrintToChat(client, " \x04\x06[KLANY]\x01 Założenie klanu kosztuje\x05 %d$", requiredCoins);
	PrintToChat(client, " \x04\x06[KLANY]\x01 Aby założyć klan, wpisz na czacie:\x06 !klan_nazwa X");
	PrintToChat(client, " \x04\x06[KLANY]\x01 Gdzie X to nazwa klanu, np.:\x06 !klan_nazwa DruzynaActimela");
}

public Action cmd_CreateClan(int client, int args) {
	if (g_plrOnlineClanID[client]) {
		return Plugin_Handled;
	}

	int requiredCoins = GetConVarInt(g_cvRequireCoins), coins = CodD0_GetClientCoins(client);
	if (coins < requiredCoins) {
		PrintToChat(client, " \x04\x06[KLANY]\x01 Aby założyć klan, musisz posiadać min.\x0E %d$!", requiredCoins);
		return Plugin_Handled;
	}

	char steamID[64];
	if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		return Plugin_Handled;
	}

	char name[MAX_CLANNAME_LENGTH], escapedName[192], query[512];

	CodD0_SetClientCoins(client, coins - requiredCoins);
	g_isPlayerDataProcessing[client][QUERY_ANOTHER] = true;

	GetClientName(client, name, sizeof(name));
	SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));

	DataPack dpData = new DataPack();
	dpData.WriteString(steamID);
	dpData.WriteString(escapedName);

	GetCmdArgString(name, sizeof(name));
	ReplaceString(name, sizeof(name), "!", "");
	ReplaceString(name, sizeof(name), "/", "");
	ReplaceString(name, sizeof(name), "klan_nazwa", "");
	ReplaceString(name, sizeof(name), "clan_name", "");
	StripQuotes(name);
	TrimString(name);
	SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));
	dpData.WriteString(escapedName);
	dpData.WriteCell(GetClientUserId(client));

	Format(query, sizeof(query), "INSERT INTO codd0clans_clans (name) VALUES ('%s')", escapedName);
	SQL_TQuery(g_sqlConn, InsertClanToDB_Handler, query, dpData);

	return Plugin_Handled;
}

public void InsertClanToDB_Handler(Handle sqlConn, Handle result, const char[] error, any data) {
	if (result == null) {
		LogError("MySQL Error! InsertClanToDB_Handler: %s", error);
	} else {
		char steamID[64], name[64], clanName[64], query[512];
		int clanID = SQL_GetInsertId(sqlConn), onlineClanID, userID, client;
		DataPack dpData = view_as<DataPack>(data);

		dpData.Reset();
		dpData.ReadString(steamID, sizeof(steamID));
		dpData.ReadString(name, sizeof(name));
		dpData.ReadString(clanName, sizeof(clanName));
		userID = dpData.ReadCell();
		client = GetClientOfUserId(userID);

		if(client) {
			for (int i = 1; i <= MaxClients; i++) {
				if (!g_clanID[i]) {
					onlineClanID = g_plrOnlineClanID[client] = i;
					break;
				}
			}

			g_plrClanRankID[client] = OWNER;

			g_clanID[onlineClanID] = clanID;
			g_clanExp[onlineClanID] = g_clanCoins[onlineClanID] = g_clanLevel[onlineClanID] = 0;
			g_clanName[onlineClanID] = clanName;

			for (int i = 1; i < MAXSTATS; i++) {
				g_clanStats[onlineClanID][i] = 0;
			}
		}

		Format(query, sizeof(query), "INSERT INTO codd0clans_player (steamID, name, clanID, clanRankID) VALUES ('%s', '%s', %d, %d)", steamID, name, clanID, OWNER);
		SQL_TQuery(g_sqlConn, InsertPlayerToDB_Handler, query, userID);
	}
}

public void InsertPlayerToDB_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! InsertPlayerToDB_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if (client) {
			g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;

			MyClanMenu(client);
			PrintToChat(client, " \x04\x05[KLANY]\x01 Twój klan został stworzony! :)");
		}
	}
}

void MyClanMenu(int client) {
	int onlineClanID = g_plrOnlineClanID[client];
	char item[128];

	Menu menu = new Menu(MyClanMenu_Handler, MENU_ACTIONS_ALL);

	Format(item, sizeof(item), "✢ Nazwa klanu: %s ✢\n✢ Stan konta: %d$ ✢", g_clanName[onlineClanID], g_clanCoins[onlineClanID]);
	menu.SetTitle(item);

	menu.AddItem("", "★ Informacje o klanie ★");
	menu.AddItem("", "★ Członkowie ★");
	menu.AddItem("", "★ Statystyki klanu ★");
	menu.AddItem("", g_plrClanRankID[client] == OWNER ? "★ Rozwiąż klan" : "Opuść klan ★");
	menu.AddItem("", "★ Wojny klanów ★");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MyClanMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				cmd_Clans(client, 0);
			}
		}

		case MenuAction_Select: {
			switch(item) {
				case 0: {
					InfoAboutClan(client, g_clanID[g_plrOnlineClanID[client]]);
				}

				case 1: {
					ClanMembers(client);
				}

				case 2: {
					ClanStats(client);
				}

				case 3: {

					if(g_plrClanRankID[client] != OWNER) {
						LeaveTheClan(client);
					} else {
						RemoveTheClan(client);
					}
				}

				case 4: {
					ClanWars(client);
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

void InfoAboutClan(int client, int clanID) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	char query[512];

	Format(query, sizeof(query), "SELECT %d, COUNT(*) FROM codd0clans_clans AS c INNER JOIN codd0clans_player AS p ON c.clanID=p.clanID WHERE p.clanID=%d", clanID, clanID);
	SQL_TQuery(g_sqlConn, GetClanInfo_Handler, query, GetClientUserId(client));
}

public void GetClanInfo_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! GetClanInfo_Handler: %s", error);
	} else if (SQL_MoreRows(result) && SQL_FetchRow(result)) {
		int client = GetClientOfUserId(userID);

		if (!client || !IsPlayerInClan(client, SQL_FetchInt(result, 0), false)) {
			return;
		}

		int plrClanID = g_plrOnlineClanID[client];
		char item[128];

		Menu menu = new Menu(InfoAboutClanMenu_Handler, MENU_ACTIONS_ALL);

		Format(item, sizeof(item), "♦ Nazwa: %s ♦", g_clanName[plrClanID]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Monety: %d ♦", g_clanCoins[plrClanID]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Ilość członków: %d ♦", SQL_FetchInt(result, 1));
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Witalność: %d ♦", g_clanStats[plrClanID][VITALITY]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Obrażenia: %d ♦", g_clanStats[plrClanID][DAMAGE]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Odporność: %d ♦", g_clanStats[plrClanID][STAMINA]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Szybkość: %d ♦", g_clanStats[plrClanID][SPEED]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Bogactwo: %d ♦", g_clanStats[plrClanID][WEALTH]);
		menu.AddItem("", item);
		Format(item, sizeof(item), "♦ Doświadczenie: %d ♦", g_clanStats[plrClanID][EXP]);
		menu.AddItem("", item);

		menu.ExitBackButton = true;
		menu.Pagination = MENU_NO_PAGINATION;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int InfoAboutClanMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				MyClanMenu(client);
			}
		}

		case MenuAction_Select: {
			MyClanMenu(client);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

void ClanMembers(int client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	Menu menu = new Menu(ClanMambersMenu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Zarządzanie członkami klanu");

	menu.AddItem("", "★ Lista członków wraz z wpłatami ★");
	menu.AddItem("", "★ Dodaj nowego członka ★");
	menu.AddItem("", "★ Usuń członka z klanu ★");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ClanMambersMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				MyClanMenu(client);
			}
		}

		case MenuAction_Select: {
			if (IsPlayerInAnyClan(client, true)) {
				switch(item) { 
					case 0: {
						ListOfAllClanMembers(client);
					}

					case 1: {
						AddMembers(client);
					}
					
					case 2: {
						RemoveMembers(client);
					}
				}
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

void ListOfAllClanMembers(int client) {
	char query[512];

	Format(query, sizeof(query), "SELECT name, paymentsSum FROM codd0clans_player WHERE clanID=%d ORDER BY clanRankID, paymentsSum DESC", g_clanID[g_plrOnlineClanID[client]]);
	SQL_TQuery(g_sqlConn, ListOfAllClanMembers_Handler, query, GetClientUserId(client));
}

public void ListOfAllClanMembers_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! ListOfAllClanMembers_Handler: %s", error);
	} else if (SQL_GetRowCount(result) > 0) {
		int client = GetClientOfUserId(userID);

		if (!client) {
			return;
		}

		char name[64], item[128];
		Menu menu = new Menu(ListOfAllClanMembersMenu_Handler, MENU_ACTIONS_ALL);
		menu.SetTitle("➫ Lista członków wraz w wpłatami");

		while (SQL_MoreRows(result) && SQL_FetchRow(result)) {
			SQL_FetchString(result, 0, name, sizeof(name));
			Format(item, sizeof(item), "★ %s [%d$] ★", name, SQL_FetchInt(result, 1));
			menu.AddItem("", item);
		}

		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int ListOfAllClanMembersMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanMembers(client);
			}
		}

		case MenuAction_Select: {
			menu.Display(client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

void AddMembers(int client) {
	if (!HasPlayerClanRank(client, ASSISTANT, true)) {
		return;
	}

	char query[512];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM codd0clans_player WHERE clanID=%d", g_clanID[g_plrOnlineClanID[client]]);
	SQL_TQuery(g_sqlConn, GetClanMembersNum_Handler, query, GetClientUserId(client));
}

public void GetClanMembersNum_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! GetClanMembersNum_Handler: %s", error);
	} else if (SQL_GetRowCount(result) > 0 && SQL_MoreRows(result) && SQL_FetchRow(result)) {
		int client = GetClientOfUserId(userID);

		if (!client || !HasPlayerClanRank(client, ASSISTANT, false)) {
			return;
		}

		if(SQL_FetchInt(result, 0) >= GetMaxClanMembers(g_clanStats[g_plrOnlineClanID[client]][MEMBERS])) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Musisz zwiększyć limit członków w klanie, aby móc zapraszać kolejnych graczy!");
			return;
		}

		char name[64], info[8], item[128];
		Menu menu = new Menu(AddMembers_Handler, MENU_ACTIONS_ALL);
		menu.SetTitle("➫ Dodaj nowego członka do klanu:");

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i) || g_plrOnlineClanID[i] || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
				continue;
			}

			GetClientName(i, name, sizeof(name));
			Format(item, sizeof(item), "★ %s ★", name);
			IntToString(GetClientUserId(i), info, sizeof(info));

			menu.AddItem(info, name);
		}

		if(!strlen(info[0])) {
			ClanMembers(client);
			PrintToChat(client, " \x04\x05[KLANY]\x01 Nie znaleziono żadnego gracza, którego mógłbyś dodać.");
			delete menu; 
		} else {
			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}
	}
}

public int AddMembers_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanMembers(client);
			}
		}

		case MenuAction_Select: {
			if (!IsPlayerInAnyClan(client, false) || !HasPlayerClanRank(client, ASSISTANT, false)) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Wystąpił błąd.");
			} else {
				char info[8];
				int targetID;

				menu.GetItem(item, info, sizeof(info));
				targetID = GetClientOfUserId(StringToInt(info));

				if (!targetID) {
					PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleziono gracza!");
				} else {
					char name[64];

					int onlineClanID = g_plrOnlineClanID[client];
					g_lastOfferedClanID[targetID] = g_clanID[onlineClanID];

					Menu offerMenu = new Menu(ClanOfferMenu_Handler, MENU_ACTIONS_ALL);
					offerMenu.SetTitle("➫ Czy chcesz dołączyć do klanu %s?", g_clanName[onlineClanID]);
					offerMenu.AddItem("", "✓ Tak ✓");
					offerMenu.AddItem("", "✗ Nie ✗");
					offerMenu.Display(targetID, MENU_TIME_FOREVER);

					GetClientName(targetID, name, sizeof(name));
					PrintToChat(client, " \x04\x06[KLANY]\x01 Oferta została wysłana do\x0E %s", name);
					PrintToChat(client, " \x04\x06[KLANY]\x01 Zostaniesz poinformowany, gdy oferta zostanie zaakceptowana.");
				}
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public int ClanOfferMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanMembers(client);
			}
		}

		case MenuAction_Select: {
			switch(item) {
				case 0: {
					if (g_plrOnlineClanID[client]) {
						PrintToChat(client, " \x04\x06[KLANY]\x01 Nieoczekiwany błąd! Dodawanie do klanu zostało anulowane.");
					} else if (!IsPlayerDataProcessing(client, true)) {
						char query[512];

						Format(query, sizeof(query), "SELECT COUNT(*), (SELECT statMembers FROM codd0clans_clans WHERE clanID=%d) FROM codd0clans_player WHERE clanID=%d", g_lastOfferedClanID[client], g_lastOfferedClanID[client]);
						SQL_TQuery(g_sqlConn, CheckIfPlayerCanJoinToTheClan_Handler, query, GetClientUserId(client));

						g_isPlayerDataProcessing[client][QUERY_ANOTHER] = true;
					}
				}
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public void CheckIfPlayerCanJoinToTheClan_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! CheckIfPlayerCanJoinToTheClan_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if (!client) {
			return;
		}

		if (SQL_GetRowCount(result) > 0 && SQL_MoreRows(result) && SQL_FetchRow(result)) {
			int statMembers = -1;

			for(int i = 1; i <= MaxClients; i++) {
				if(g_clanID[i] == g_lastOfferedClanID[client]) {
					statMembers = g_clanStats[i][MEMBERS];
				}
			}

			if(statMembers == -1) {
				statMembers = SQL_FetchInt(result, 1);
			}

			if(SQL_FetchInt(result, 0) >= GetMaxClanMembers(statMembers)) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Aktualnie klan jest pełny i nie możesz do niego dołączyć!");
				return;
			}

			char query[512], steamID[64], name[64], escapedName[192];

			if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Błąd autoryzacji SteamID! Dodawanie do klanu zostało anulowane.");
				return;
			}

			GetClientName(client, name, sizeof(name));
			SQL_EscapeString(g_sqlConn, name, escapedName, sizeof(escapedName));

			Format(query, sizeof(query), "INSERT INTO codd0clans_player (steamID, name, clanID) VALUES ('%s', '%s', %d)", steamID, escapedName, g_lastOfferedClanID[client]);
			SQL_TQuery(g_sqlConn, AddMemberToDB_Handler, query, userID);
		} else {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Klan, do którego chciałeś dołączyć już nie istnieje :(");
			g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;
		}
	}
}

public void AddMemberToDB_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! AddMemberToDB_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if (!client) {
			return;
		}

		g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;
		if (!ReadPlayerClanData(client, g_lastOfferedClanID[client])) {
			return;
		}

		char name[64];
		GetClientName(client, name, sizeof(name));

		for (int i = 1; i <= MAXPLAYERS; i++) {
			if (g_plrOnlineClanID[i] == g_plrOnlineClanID[client]) {
				PrintToChat(i, " \x04\x06[KLANY]\x01 Do klanu dołączył(a)\x0E %s!\x01 Życzymy powodzenia :)", name);
			}
		}
	}
}

void RemoveMembers(int client) {
	if (!HasPlayerClanRank(client, OWNER, true)) {
		return;
	}

	char query[512];

	Format(query, sizeof(query), "SELECT steamID, name, paymentsSum FROM codd0clans_player WHERE clanID=%d AND clanRankID!=%d ORDER BY name DESC", g_clanID[g_plrOnlineClanID[client]], OWNER);
	SQL_TQuery(g_sqlConn, RemoveMembers_Handler, query, GetClientUserId(client));
}

public void RemoveMembers_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! RemoveMembers_Handler: %s", error);
	} else {
			int client = GetClientOfUserId(userID);

			if (!client) {
				return;
			}

			if (SQL_GetRowCount(result) <= 0) {
				ClanMembers(client);
				PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleiono żadnego członka.");
				return;
			}

			char name[64], steamID[64], sPaymentsSum[32], item[128];
			int paymentsSum;
			Menu menu = new Menu(RemoveMembersMenu_Handler, MENU_ACTIONS_ALL);
			menu.SetTitle("➫ Usuwanie członków:");

			while (SQL_MoreRows(result) && SQL_FetchRow(result)) {
				SQL_FetchString(result, 0, steamID, sizeof(steamID));
				SQL_FetchString(result, 1, name, sizeof(name));
				Format(item, sizeof(item), "★ %s ★", name);
				paymentsSum = SQL_FetchInt(result, 2);

				if(paymentsSum >= GetConVarInt(g_cvPaymentsSumForPermMember)) {
					IntToString(paymentsSum, sPaymentsSum, sizeof(sPaymentsSum));
					menu.AddItem(sPaymentsSum, name);
				} else {
					menu.AddItem(steamID, name);
				}
			}

			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}
}

public int RemoveMembersMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanMembers(client);
			}
		}

		case MenuAction_Select: {
			if (!IsPlayerInAnyClan(client, false) || !HasPlayerClanRank(client, OWNER, false)) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Wystąpił błąd.");
			} else {
				char info[64];
				menu.GetItem(item, info, sizeof(info));

				if(info[0] != 'S') {
					PrintToChat(client, " \x04\x06[KLANY]\x01 Nie możesz tego gracza wyrzucić z klanu! Wpłacił(a) już za dużo monet do klanu!\x05 (%s$)", info);
				} else {
					char query[512]
					int target = GetClientOfSteamId(info);

					if (IsPlayerDataProcessing(target, false)) {
						RemoveMembers(client);
						PrintToChat(client, " \x04\x06[KLANY]\x01 Dane tego gracza są aktualnie przetwarzane, spróbuj ponownie za parę chwil...");
					} else {
						DataPack dpData = new DataPack();
						dpData.WriteCell(GetClientUserId(client));

						if (target) {
							g_isPlayerDataProcessing[target][QUERY_ANOTHER] = true;
							dpData.WriteCell(GetClientUserId(target));
						} else {
							dpData.WriteCell(0);
						}

						Format(query, sizeof(query), "DELETE FROM codd0clans_player WHERE steamID='%s' AND clanID=%d", info, g_clanID[g_plrOnlineClanID[client]])
						SQL_TQuery(g_sqlConn, RemovePlayerFromDB_Handler, query, dpData);
					}
				}
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public void RemovePlayerFromDB_Handler(Handle sqlConn, Handle result, const char[] error, any data) {
	DataPack dpData = view_as<DataPack>(data);

	if (result == null) {
		LogError("MySQL Error! RemovePlayerFromDB_Handler: %s", error);
	} else {
		if (SQL_GetAffectedRows(sqlConn)) {
			dpData.Reset();

			int client = GetClientOfUserId(dpData.ReadCell());
			int target = GetClientOfUserId(dpData.ReadCell());

			if (target) {
				g_isPlayerDataProcessing[target][QUERY_ANOTHER] = false;

				PrintToChat(target, " \x04\x06[KLANY]\x01 Zostałeś wyrzucony z klanu :( ");
			}

			if (client) {
				RemoveMembers(client);
				PrintToChat(client, " \x04\x06[KLANY]\x01 Gracz został usunięty z klanu.");
			}
		}
	}

	delete dpData;
}

void ClanStats(int client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	char item[128];
	int onlineClanID = g_plrOnlineClanID[client];

	Menu menu = new Menu(ClanStatsMenu_Handler, MENU_ACTIONS_ALL);

	Format(item, sizeof(item), "➫ Punkty statystyk klanu\n♦ Monety klanu: %d$", g_clanCoins[onlineClanID]);
	menu.SetTitle(item);

	menu.AddItem("", "✢ Wpłać monety do klanu");

	Format(item, sizeof(item), "♦ Witalność [%d/%d] [+%d zdrowia] [%d$]", 
		g_clanStats[onlineClanID][VITALITY], GetConVarInt(g_cvMaxStat[VITALITY]), RoundFloat(float(g_clanStats[onlineClanID][VITALITY]) * GetConVarFloat(g_cvStatMultiplier[VITALITY])), GetConVarInt(g_cvStatUpgradePrice[VITALITY]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Obrażenia [%d/%d] [+%d zadawanych obrażeń] [%d$]", 
		g_clanStats[onlineClanID][DAMAGE], GetConVarInt(g_cvMaxStat[DAMAGE]), RoundFloat(float(g_clanStats[onlineClanID][DAMAGE]) * GetConVarFloat(g_cvStatMultiplier[DAMAGE])), GetConVarInt(g_cvStatUpgradePrice[DAMAGE]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Wytrzymałość [%d/%d] [-%d otrzymywanych obrażeń] [%d$]", 
		g_clanStats[onlineClanID][STAMINA], GetConVarInt(g_cvMaxStat[STAMINA]), RoundFloat(float(g_clanStats[onlineClanID][STAMINA]) * GetConVarFloat(g_cvStatMultiplier[STAMINA])), GetConVarInt(g_cvStatUpgradePrice[STAMINA]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Prędkość [%d/%d] [+%d do prędkości] [%d$]", 
		g_clanStats[onlineClanID][SPEED], GetConVarInt(g_cvMaxStat[SPEED]), RoundFloat(float(g_clanStats[onlineClanID][SPEED]) * GetConVarFloat(g_cvStatMultiplier[SPEED])), GetConVarInt(g_cvStatUpgradePrice[SPEED]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Bogactwo [%d/%d] [+%d monet za fraga] [%d$]", 
		g_clanStats[onlineClanID][WEALTH], GetConVarInt(g_cvMaxStat[WEALTH]), RoundFloat(float(g_clanStats[onlineClanID][WEALTH]) * GetConVarFloat(g_cvStatMultiplier[WEALTH])), GetConVarInt(g_cvStatUpgradePrice[WEALTH]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Doświadczenie [%d/%d] [+%d dośw. za fraga] [%d$]", 
		g_clanStats[onlineClanID][EXP], GetConVarInt(g_cvMaxStat[EXP]), RoundFloat(float(g_clanStats[onlineClanID][EXP]) * GetConVarFloat(g_cvStatMultiplier[EXP])), GetConVarInt(g_cvStatUpgradePrice[EXP]));
	menu.AddItem("", item);
	Format(item, sizeof(item), "♦ Limit członków [%d/%d] [max. %d członków] [%d$]", 
		g_clanStats[onlineClanID][MEMBERS], GetConVarInt(g_cvMaxStat[MEMBERS]), GetMaxClanMembers(g_clanStats[onlineClanID][MEMBERS]), GetConVarInt(g_cvStatUpgradePrice[EXP]));
	menu.AddItem("", item);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ClanStatsMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				MyClanMenu(client);
			}
		}

		case MenuAction_Select: {
			if (IsPlayerInAnyClan(client, true)) {
				if(item == 0) {
					PrintToChat(client, " \x04\x06[KLANY]\x01 Aby wpłacić monety do klanu, wpisz na czacie:\x05 $klan X");
					PrintToChat(client, " \x04\x06[KLANY]\x01 W miejsce X wpisz kwotę, np.:\x05 $klan 35");

					ClanStats(client);
				} else if(item > 0) {
					if (HasPlayerClanRank(client, ASSISTANT, true)) {
						int onlineClanID = g_plrOnlineClanID[client], max = GetConVarInt(g_cvMaxStat[item]);

						if (g_clanStats[onlineClanID][item] >= max) {
							PrintToChat(client, " \x04\x06[KLANY]\x01 Limit statystyki został osiągnięty.");
						} else {
							int price = GetConVarInt(g_cvStatUpgradePrice[item]);

							if (g_clanCoins[onlineClanID] < price) {
								PrintToChat(client, " \x04\x06[KLANY]\x01 Klan nie posiada wystarczającej ilości monet.");
							} else {
								g_clanStats[onlineClanID][item] ++;
								g_clanCoins[onlineClanID] -= price;
							}
						}
					}

					ClanStats(client);
				}
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if (!IsPlayerInAnyClan(client, false) || strcmp(command, "say", false)) {
		return Plugin_Continue;
	}

	int value, onlineClanID = g_plrOnlineClanID[client];
	char sValue[32];

	strcopy(sValue, sizeof(sValue), args);
	StripQuotes(sValue);
	TrimString(sValue);

	if(StrContains(sValue, "$klan") != 0) {
		return Plugin_Continue;
	}

	ReplaceString(sValue, sizeof(sValue), "$klan", "");
	TrimString(sValue);
	value = StringToInt(sValue);

	if (value <= 0) {
		PrintToChat(client, " \x06\x04[KLANY]\x01 Wpłata musi być większa od zera!");
	} else {
		char query[512], steamID[64];

		if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
			PrintToChat(client, " \x06\x04[KLANY]\x01 Wystąpił błąd autoryzacji");
		} else {
			int playerCoins = CodD0_GetClientCoins(client);

			if (playerCoins < value) {
				value = playerCoins;
			}

			g_clanCoins[onlineClanID] += value;
			CodD0_SetClientCoins(client, playerCoins - value);

			Format(query, sizeof(query), "UPDATE codd0clans_player SET paymentsSum=paymentsSum+%d WHERE steamID='%s'", value, steamID);
			SQL_TQuery(g_sqlConn, SumPlayerPayment_Handler, query);

			ClanStats(client);
			PrintToChat(client, " \x06\x04[KLANY]\x01 Wpłacono:\x0E %d$", value);
		}
	}

	return Plugin_Handled;
}

public void SumPlayerPayment_Handler(Handle sqlConn, Handle result, const char[] error, any data) {
	if (result == null) {
		LogError("MySQL Error! SumPlayerPayment_Handler: %s", error);
	}
}

void LeaveTheClan(int client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	Menu menu = new Menu(LeaveTheClanMenu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Czy jesteś pewny, że chcesz opuścić klan?");

	menu.AddItem("", "✓ Tak ✓");
	menu.AddItem("", "✗ Nie ✗");

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int LeaveTheClanMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			if(item == 0) {
				if (IsPlayerInAnyClan(client, true) && !HasPlayerClanRank(client, OWNER, true)) {
					char steamID[64];

					if(!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
						PrintToChat(client, " \x04\x06[KLANY]\x01 Wystąpił błąd autoryzacji SteamID!");
					} else {
						char query[512];
						int onlineClanID = g_plrOnlineClanID[client];
						bool saveClanData = true;

						for(int i = 1; i <= MaxClients; i++) {
							if(i != client && g_plrOnlineClanID[i] == onlineClanID) {
								saveClanData = false;
								break;
							}
						}

						if(saveClanData) {
							Format(query, sizeof(query), "UPDATE codd0clans_clans SET name='%s', experience=%d, coins=%d, statVitality=%d, statDamage=%d, statStamina=%d, statSpeed=%d, statWealth=%d, statExperience=%d WHERE clanID=%d",
							g_clanName[onlineClanID], g_clanExp[onlineClanID], g_clanCoins[onlineClanID], g_clanStats[onlineClanID][VITALITY], g_clanStats[onlineClanID][DAMAGE], 
							g_clanStats[onlineClanID][STAMINA], g_clanStats[onlineClanID][SPEED], g_clanStats[onlineClanID][WEALTH], g_clanStats[onlineClanID][EXP], g_clanID[onlineClanID]);

							SQL_TQuery(g_sqlConn, UpdatePlayerData_Handler, query);
							g_clanID[onlineClanID] = 0;
						}

						g_plrOnlineClanID[client] = 0;
						g_plrClanRankID[client] = 0;
						g_isPlayerDataProcessing[client][QUERY_ANOTHER] = true;

						Format(query, sizeof(query), "DELETE FROM codd0clans_player WHERE steamID='%s'", steamID);
						SQL_TQuery(g_sqlConn, LeaveTheClan_Handler, query, GetClientUserId(client));
					}
				}
			} else {
				MyClanMenu(client);
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}

}

public void LeaveTheClan_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! LeaveTheClan_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(client) {
			g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;

			PrintToChat(client, " \x04\x06[KLANY]\x01 Opuściłeś klan.");
		}
	}
}

void RemoveTheClan(int client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	if(!HasPlayerClanRank(client, OWNER, true) || HasPlayerClanWar(client, true)) {
		MyClanMenu(client);
	}

	Menu menu = new Menu(RemoveTheClanMenu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Czy jesteś pewny, że chcesz rozwiązać klan?");

	menu.AddItem("", "✓ Tak ✓");
	menu.AddItem("", "✗ Nie ✗");

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RemoveTheClanMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Select: {
			if(item == 0) {
				if (IsPlayerInAnyClan(client, true) && HasPlayerClanRank(client, OWNER, true) && !HasPlayerClanWar(client, true)) {
					char query[512];
					int clanID = g_clanID[g_plrOnlineClanID[client]];

					Format(query, sizeof(query), "SELECT %d, COUNT(*) FROM codd0clans_clans AS c INNER JOIN codd0clans_player AS p ON c.clanID=p.clanID WHERE p.clanID=%d", clanID, clanID);
					SQL_TQuery(g_sqlConn, CheckIfClanHasAnyMembers_Handler, query, GetClientUserId(client));
				}
			} else {
				MyClanMenu(client);
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void CheckIfClanHasAnyMembers_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! CheckIfClanHasAnyMembers_Handler: %s", error);
	} else if (SQL_MoreRows(result) && SQL_FetchRow(result)) {
		int client = GetClientOfUserId(userID);

		if (!client || !IsPlayerInClan(client, SQL_FetchInt(result, 0), true) || !HasPlayerClanRank(client, OWNER, true) || HasPlayerClanWar(client, true) || IsPlayerDataProcessing(client, true)) {
			return;
		}

		if(SQL_FetchInt(result, 1) > 1) {
			MyClanMenu(client);
			PrintToChat(client, " \x04\x06[KLANY]\x01 Rozwiązać klan możesz tylko, gdy nie ma w nim żadnego innego członka.");
			return;
		}

		char query[512];
		int onlineClanID = g_plrOnlineClanID[client], clanID = g_clanID[onlineClanID];

		g_clanID[onlineClanID] = 0;
		g_plrOnlineClanID[client] = 0;
		g_plrClanRankID[onlineClanID] = 0;
		g_isPlayerDataProcessing[client][QUERY_ANOTHER] = true;

		Format(query, sizeof(query), "DELETE c.*, p.* FROM codd0clans_clans AS c INNER JOIN codd0clans_player AS p ON c.clanID=p.clanID WHERE c.clanID=%d", clanID);
		SQL_TQuery(g_sqlConn, RemoveTheClan_Handler, query, GetClientUserId(client));
	}
}

public void RemoveTheClan_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! RemoveTheClan_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(client) {
			g_isPlayerDataProcessing[client][QUERY_ANOTHER] = false;

			PrintToChat(client, " \x04\x06[KLANY]\x01 Klan został usunięty.");
		}
	}
}

void ClanWars(int client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	Menu menu = new Menu(ClanWars_Handler, MENU_ACTIONS_ALL);
	int plrOnlineClanID = g_plrOnlineClanID[client];

	menu.SetTitle("➫ Menu wojen klanów");

	menu.AddItem("", "★ Wyzwij klan na wojnę ★");
	menu.AddItem("", g_clanWar_block[plrOnlineClanID] ? "★ Blokada wojen klanów: ✓ ON ✓" : "Blokada wojen klanów: ✗ OFF ✗" );
	menu.AddItem("", "★ Na czym polegają wojny klanów? ★");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ClanWars_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				MyClanMenu(client);
			}
		}

		case MenuAction_Select: {
			switch(item) {
				case 0: {
					SelectClanToWar(client);
				}

				case 1: {
					if (IsPlayerInAnyClan(client, true) && HasPlayerClanRank(client, ASSISTANT, true)) {
						int plrOnlineClanID = g_plrOnlineClanID[client];

						g_clanWar_block[plrOnlineClanID] = !g_clanWar_block[plrOnlineClanID];
					}

					ClanWars(client);
				}

				case 2: {
					char sItem[256];

					Menu infoMenu = new Menu(InfoAboutWars_Handler, MENU_ACTIONS_ALL);

					infoMenu.AddItem("", "✶ Możesz wyzwać klan na wojnę, a zgarniesz wtedy specjalne nagrody!");
					infoMenu.AddItem("", "✶ Jak działają wojny? Po wyzwaniu klanu na wojnę pojawi się");
					infoMenu.AddItem("", "✶ specjalny licznik na ekranie. Klany podczas odliczania");
					infoMenu.AddItem("", "✶ mają za zadanie zdobyć jak największą ilość fragów!");
					infoMenu.AddItem("", "✶ Klan, który tych fragów będzie mieć więcej, wygrywa główną nagrodę.");
					Format(sItem, sizeof(sItem), "✶ Czas trwania wojny: %d:%d", g_warTime/60, g_warTime%60);
					infoMenu.AddItem("", sItem);
					infoMenu.AddItem("", "✶ Nie zwklekaj i rozwijaj swój klan poprzez wojny!");

					infoMenu.ExitBackButton = true;
					infoMenu.Display(client, MENU_TIME_FOREVER);
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public int InfoAboutWars_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanWars(client);
			}
		}

		case MenuAction_DrawItem: {
			return ITEMDRAW_DISABLED;
		}

		case MenuAction_End: {
			delete menu;
		}
	}

	return 0;
}

void SelectClanToWar(client) {
	if (!IsPlayerInAnyClan(client, true)) {
		return;
	}

	if(!HasPlayerClanRank(client, ASSISTANT, true) || IsWarmupOn(client, true) || HasPlayerClanWar(client, true) || IsItTooLateForWar(client, true)) {
		ClanWars(client);
		return;
	}

	int plrOnlineClanID = g_plrOnlineClanID[client], targetOnlineClanID;
	bool isClanInMenu[MAXPLAYERS+1];
	char info[64], item[128];

	Menu menu = new Menu(SelectClanToWar_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Wybierz klan, z którym chcesz rozpocząć wojnę:");
	for (int i = 1; i <= MaxClients; i++) {
		if (!(targetOnlineClanID = g_plrOnlineClanID[i]) || targetOnlineClanID == plrOnlineClanID || isClanInMenu[targetOnlineClanID] || g_clanWar_block[targetOnlineClanID] || HasPlayerClanWar(i, false) || !HasPlayerClanRank(i, OWNER, false) || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
			continue;
		}

		isClanInMenu[targetOnlineClanID] = true;

		Format(info, sizeof(info), "%d %d", GetClientUserId(i), g_clanID[targetOnlineClanID]);
		Format(item, sizeof(item), "★ %s ★", g_clanName[targetOnlineClanID]);
		menu.AddItem(info, item);
	}


	for (int i = 1; i <= MaxClients; i++) {
		if (!(targetOnlineClanID = g_plrOnlineClanID[i]) || targetOnlineClanID == plrOnlineClanID || isClanInMenu[targetOnlineClanID] || g_clanWar_block[targetOnlineClanID] || HasPlayerClanWar(i, false) || !HasPlayerClanRank(i, ASSISTANT, false) || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
			continue;
		}

		isClanInMenu[targetOnlineClanID] = true;

		Format(info, sizeof(info), "%d %d", GetClientUserId(i), g_clanID[targetOnlineClanID]);
		Format(item, sizeof(item), "★ %s ★", g_clanName[targetOnlineClanID]);
		menu.AddItem(info, item);
	}

	if(!strlen(info)) {
		ClanWars(client);
		PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleziono żadnego klanu :(");
		delete menu;
	} else {
		menu.ExitBackButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int SelectClanToWar_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanWars(client);
			}
		}

		case MenuAction_Select: {
			char info[64], explodedInfo[2][32];
			int target, targetClanID;

			menu.GetItem(item, info, sizeof(info));
			ExplodeString(info, " ", explodedInfo, sizeof(explodedInfo), sizeof(explodedInfo[]));

			target = GetClientOfUserId(StringToInt(explodedInfo[0]));
			targetClanID = StringToInt(explodedInfo[1]);

			if(!target || g_clanID[g_plrOnlineClanID[target]] != targetClanID) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleziono danego klanu :(");
				SelectClanToWar(client);
			} else {
				char sItem[256];

				Menu askMenu = new Menu(AskForWar_Handler, MENU_ACTIONS_ALL);
				int plrOnlineClanID = g_plrOnlineClanID[client];

				Format(sItem, sizeof(sItem), "➫ Klan %s chce rozpocząć z Tobą wojnę!\nPodejmujesz wyzwanie?", g_clanName[plrOnlineClanID]);
				askMenu.SetTitle(sItem);

				Format(info, sizeof(info), "%d %d", GetClientUserId(client), g_clanID[plrOnlineClanID]);
				askMenu.AddItem(info, "✓ Tak ✓");
				askMenu.AddItem("", "✗ Nie ✗");

				askMenu.ExitButton = false;
				askMenu.Display(target, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

public int AskForWar_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				ClanWars(client);
			}
		}

		case MenuAction_Select: {
			if(item || !IsPlayerInAnyClan(client, true) || !HasPlayerClanRank(client, ASSISTANT, true) || HasPlayerClanWar(client, true) || IsItTooLateForWar(client, true)) {
				return 0;
			}

			char info[64], explodedInfo[2][32];
			int target, targetClanID, targetOnlineClanID;

			menu.GetItem(item, info, sizeof(info));
			ExplodeString(info, " ", explodedInfo, sizeof(explodedInfo), sizeof(explodedInfo[]));

			target = GetClientOfUserId(StringToInt(explodedInfo[0]));
			targetClanID = StringToInt(explodedInfo[1]);

			if(!target || g_clanID[(targetOnlineClanID = g_plrOnlineClanID[target])] != targetClanID) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleziono danego klanu :(");
				ClanWars(client);
			} else if(HasPlayerClanRank(target, ASSISTANT, false) && !HasPlayerClanWar(target, false)) {
				int plrOnlineClanID = g_plrOnlineClanID[client], clanID = g_clanID[plrOnlineClanID], timeLeft, endTime;

				GetMapTimeLeft(timeLeft);
				endTime = timeLeft - g_warTime;

				g_clanWar_oppnntClanID[plrOnlineClanID] = targetClanID;
				g_clanWar_oppnntOnlineClanID[plrOnlineClanID] = targetOnlineClanID;
				g_clanWar_oppnntClanName[plrOnlineClanID] = g_clanName[targetClanID];
				g_clanWar_frags[plrOnlineClanID][0] = g_clanWar_frags[plrOnlineClanID][1] = 0;
				g_clanWar_endTime[plrOnlineClanID] = endTime;
				g_clanWar_timer[plrOnlineClanID] = CreateTimer(1.0, timer_WarCountdown, plrOnlineClanID, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

				g_clanWar_oppnntClanID[targetOnlineClanID] = clanID;
				g_clanWar_oppnntOnlineClanID[targetOnlineClanID] = plrOnlineClanID;
				g_clanWar_oppnntClanName[targetOnlineClanID] = g_clanName[plrOnlineClanID];
				g_clanWar_frags[targetOnlineClanID][0] = g_clanWar_frags[targetOnlineClanID][1] = 0;
				g_clanWar_endTime[targetOnlineClanID] = endTime;
				g_clanWar_timer[targetOnlineClanID] = CreateTimer(1.0, timer_WarCountdown, targetOnlineClanID, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

				DataPack dpData/* = new DataPack()*/;
				CreateDataTimer(float(g_warTime), timer_EndOfWar, dpData, TIMER_FLAG_NO_MAPCHANGE);
				dpData.WriteCell(clanID);
				dpData.WriteCell(targetClanID);

				PrintToChatAll(" \x04\x06[KLANY]\x0E %s vs %s\x01 - który z tych klanów okaże się lepszy? Wojna zweryfikuje, zaczynamy!", g_clanName[plrOnlineClanID], g_clanName[targetOnlineClanID]);
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}

	return 0;
}

public Action timer_WarCountdown(Handle timer, any onlineClanID) {
	int timeLeft, warTimeLeft;

	GetMapTimeLeft(timeLeft);
	warTimeLeft = timeLeft - g_clanWar_endTime[onlineClanID];

	char message[256];
	Format(message, sizeof(message), "%s [%d] vs %s [%d] :: %02d:%02d", g_clanName[onlineClanID], g_clanWar_frags[onlineClanID][0], g_clanWar_oppnntClanName[onlineClanID], g_clanWar_frags[onlineClanID][1], warTimeLeft/60, warTimeLeft%60);

	SetHudTextParams(0.005, 0.905, 2.0, 255, 255, 0, 0, 0, 0.0, 0.0, 0.0);

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || g_plrOnlineClanID[i] != onlineClanID) {
			continue;
		}

		ShowSyncHudText(i, g_warHud, message);
	}

	return Plugin_Continue;
}

public Action timer_EndOfWar(Handle timer, DataPack dpData) {
	int clanID[2], onlineClanID[2], frags[2];//, whichClanIsOnline = -1;
	//DataPack dpData = view_as<DataPack>(data);

	dpData.Reset();
	for(int i = 0; i < 2; i++) {
		clanID[i] = dpData.ReadCell();

		for(int j = 1; j <= MAXPLAYERS; j++) {
			if(g_clanID[j] == clanID[i]) {
				onlineClanID[i] = j;
				frags[i] = g_clanWar_frags[j][0];
				frags[!i] = g_clanWar_frags[j][1];
			}
		}
	}

	if(onlineClanID[0] || onlineClanID[1]) {
		EndOfWar(clanID, onlineClanID, frags);
	} else {
		char query[512];

		Format(query, sizeof(query), "SELECT clanID, fragsOnWar FROM codd0clans_clans WHERE clanID=%d OR clanID=%d", clanID[0], clanID[1]);
		SQL_TQuery(g_sqlConn, GetClanFragsOnWar_Handler, query, 0, DBPrio_High);
	}
}

public void GetClanFragsOnWar_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! GetClanFragsOnWar_Handler: %s", error);
	} else {
		int k, clanID[2], frags[2], onlineClanID[2];
		while (SQL_MoreRows(result) && SQL_FetchRow(result)) {
			clanID[k] = SQL_FetchInt(result, 0);
			frags[k] = SQL_FetchInt(result, 1);

			k++;
		}

		for (int i = 0; i < 2; i++) {
			for (int j = 1; j <= MAXPLAYERS; j++) {
				if (g_clanID[j] == clanID[i]) {
					onlineClanID[i] = j;
					frags[i] = g_clanWar_frags[j][0];
					frags[!i] = g_clanWar_frags[j][1];
				}
			}
		}

		EndOfWar(clanID, onlineClanID, frags);
	}
}

void EndOfWar(int clanID[2], int onlineClanID[2], int frags[2]) {
	int winner, loser;

	if (frags[0] > frags[1]) {
		winner = 0;
		loser = 1;
	} else if (frags[0] < frags[1]) {
		winner = 1;
		loser = 0;
	}

	if (!winner && !loser) {
		char query[512];

		for (int i = 0; i < 2; i++) {
			if (onlineClanID[i]) {
				g_clanWar_stats[onlineClanID[i]][WARSTAT_DRAWS] ++;

				g_clanWar_oppnntClanID[onlineClanID[i]] = 0;
				g_clanWar_oppnntOnlineClanID[onlineClanID[i]] = 0;
				
				if (g_clanWar_timer[onlineClanID[i]] != null) {
					KillTimer(g_clanWar_timer[onlineClanID[i]]);
					g_clanWar_timer[onlineClanID[i]] = null;
				}

				for (int j = 1; j <= MaxClients; j++) {
					if (onlineClanID[i] == g_plrOnlineClanID[j]) {
						PrintToChat(j, " \x04\x06[KLANY]\x01 Niestety, ale doszło do remisu :( W tym wypadku nikt nie zgarnia nagrody.");
					}
				}
			} else {
				Format(query, sizeof(query), "UPDATE codd0clans_clans SET drawedWars=drawedWars+1, opponentClanID=0, fragsOnWar=0, warEndTime=0 WHERE clanID=%d", clanID[i]);
				SQL_TQuery(g_sqlConn, UpdateClanDataAfterWar_Handler, query, 0, DBPrio_High);
			}
		}
	} else {
		int coinsAward = GetConVarInt(g_cvWonWarCoinsBaseAward) + RoundFloat(GetConVarFloat(g_cvWonWarCoinsAwardPerFrag) * float(frags[winner]));
		
		if (onlineClanID[winner]) {
			g_clanCoins[onlineClanID[winner]] += coinsAward;
			g_clanWar_stats[onlineClanID[winner]][WARSTAT_WINS] ++;

			g_clanWar_oppnntClanID[onlineClanID[winner]] = 0;
			g_clanWar_oppnntOnlineClanID[onlineClanID[winner]] = 0;
			
			if (g_clanWar_timer[onlineClanID[winner]] != null) {
				KillTimer(g_clanWar_timer[onlineClanID[winner]]);
				g_clanWar_timer[onlineClanID[winner]] = null;
			}

			for (int i = 1; i <= MaxClients; i++) {
				if (g_plrOnlineClanID[i] == onlineClanID[winner]) {
					PrintToChat(i, " \x04\x06[KLANY]\x01 Brawo! Udało Wam się wygrać wojnę! Nagroda:\x0E %d$", coinsAward);
				}
			}
		} else {
			char query[512];

			Format(query, sizeof(query), "UPDATE codd0clans_clans SET coins=coins+%d, wonWars=wonWars+1, opponentClanID=0, fragsOnWar=0, warEndTime=0 WHERE clanID=%d", coinsAward, clanID[winner]);
			SQL_TQuery(g_sqlConn, UpdateClanDataAfterWar_Handler, query, 0, DBPrio_High);
		}

		coinsAward = GetConVarInt(g_cvLostWarCoinsBaseAward) + RoundFloat(GetConVarFloat(g_cvLostWarCoinsAwardPerFrag) * float(frags[loser]));

		if (onlineClanID[loser]) {
			g_clanCoins[onlineClanID[loser]] += coinsAward;
			g_clanWar_stats[onlineClanID[loser]][WARSTAT_LOSES] ++;

			g_clanWar_oppnntClanID[onlineClanID[loser]] = 0;
			g_clanWar_oppnntOnlineClanID[onlineClanID[loser]] = 0;
			
			if (g_clanWar_timer[onlineClanID[loser]] != null) {
				KillTimer(g_clanWar_timer[onlineClanID[loser]]);
				g_clanWar_timer[onlineClanID[loser]] = null;
			}

			for (int i = 1; i <= MaxClients; i++) {
				if (g_plrOnlineClanID[i] == onlineClanID[loser]) {
					PrintToChat(i, " \x04\x06[KLANY]\x01 Niestety, ale tym przegrałeś tą wojnę :( Nagroda:\x0E %d$", coinsAward);
				}
			}
		} else {
			char query[512];

			Format(query, sizeof(query), "UPDATE codd0clans_clans SET coins=coins+%d, lostWars=lostWars+1, opponentClanID=0, fragsOnWar=0, warEndTime=0 WHERE clanID=%d", coinsAward, clanID[loser]);
			SQL_TQuery(g_sqlConn, UpdateClanDataAfterWar_Handler, query, 0, DBPrio_High);
		}
	}
}

public void UpdateClanDataAfterWar_Handler(Handle sqlConn, Handle result, const char[] error, any data) {
	if (result == null) {
		LogError("MySQL Error! UpdateClanDataAfterWar_Handler: %s", error);
	}
}

void Top15Clans(int client) {
	SQL_TQuery(g_sqlConn, SelectTop15_Handler, "SELECT name FROM codd0clans_clans ORDER BY (statVitality+statDamage+statStamina+statSpeed+statWealth+statExperience+statMembers) DESC LIMIT 15", GetClientUserId(client));
}

public void SelectTop15_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! SelectTop15_Handler: %s", error);
	} else {
		int client = GetClientOfUserId(userID);

		if(!client) {
			return;
		}

		if(SQL_GetRowCount(result) > 0) {
			char clanName[64], item[192];
			int i;

			Menu menu = new Menu(Top15ClansMenu_Handler, MENU_ACTIONS_ALL);
			menu.SetTitle("➫ TOP 15 Klanów wg. rozwoju");

			while (SQL_MoreRows(result)) {
				if (SQL_FetchRow(result)) {
					SQL_FetchString(result, 0, clanName, sizeof(clanName));
					Format(item, sizeof(item), "#%d. %s", ++i, clanName);

					menu.AddItem("", item);
				}
			}

			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		} else {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Nie znaleziono żadnego klanu :(");
		}
	}
}

public int Top15ClansMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				cmd_Clans(client, 0);
			}
		}

		case MenuAction_Select: {
			cmd_Clans(client, 0);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

void Help(int client) {
	Menu menu = new Menu(HelpMenu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("➫ Jak działają klany?");
	menu.AddItem("", "♦ Załóż klan ze swoimi znajomymi");
	menu.AddItem("", "♦ aby zwiększyć swoje umiejętności!");
	menu.AddItem("", "♦ W klanie razem ze swoimi członkami");
	menu.AddItem("", "♦ zbieracie monety, za które potem możesz");
	menu.AddItem("", "♦ zamienić na statystyki jak witalność, obrażenia i wiele innych!");
	menu.AddItem("", "♦ Przekonaj się sam i czym prędzej dołącz do klanu!");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int HelpMenu_Handler(Menu menu, MenuAction action, int client, int item) {
	switch(action) {
		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				cmd_Clans(client, 0);
			}
		}

		case MenuAction_Select: {
			cmd_Clans(client, 0);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
}

bool ReadPlayerClanData(int client, int clanID) {
	for (int i = 1; i <= MaxClients; i++) {
		if (g_clanID[i] == clanID) {
			g_plrOnlineClanID[client] = i;
			return true;
		}
	}

	char query[512];

	g_lastOfferedClanID[client] = clanID;
	g_isPlayerDataProcessing[client][QUERY_CONNECT] = true;

	Format(query, sizeof(query), "SELECT %d, name, experience, coins, opponentClanID, (SELECT name FROM codd0clans_clans WHERE clanID=opponentClanID) AS opponentClanName, fragsOnWar, (SELECT fragsOnWar FROM codd0clans_clans WHERE clanID=opponentClanID) AS opponentFragsOnWar, warEndTime, warBlock, lostWars, wonWars, drawedWars, statVitality, statDamage, statStamina, statSpeed, statWealth, statExperience, statMembers FROM codd0clans_clans WHERE clanID=%d;", clanID, clanID);
	SQL_TQuery(g_sqlConn, ReadPlayerClanData_Handler, query, GetClientUserId(client));

	return false;
}

public void ReadPlayerClanData_Handler(Handle sqlConn, Handle result, const char[] error, any userID) {
	if (result == null) {
		LogError("MySQL Error! ReadPlayerClanData_Handler: %s", error);
	} else if (SQL_MoreRows(result) && SQL_FetchRow(result)) {
		int client = GetClientOfUserId(userID), clanID = g_lastOfferedClanID[client];

		if (!client) {
			return;
		}

		g_isPlayerDataProcessing[client][QUERY_CONNECT] = false;
		for (int i = 1; i <= MaxClients; i++) {
			if (g_clanID[i] == clanID) {
				g_plrOnlineClanID[client] = i;
				return;
			}
		}

		int plrOnlineClanID, statsSum;
		for (int i = 1; i <= MaxClients; i++) {
			if (!g_clanID[i]) {
				plrOnlineClanID = g_plrOnlineClanID[client] = i;
				break;
			}
		}

		g_clanID[plrOnlineClanID] = SQL_FetchInt(result, 0);
		SQL_FetchString(result, 1, g_clanName[plrOnlineClanID], MAX_CLANNAME_LENGTH-1);
		g_clanExp[plrOnlineClanID] = SQL_FetchInt(result, 2);
		g_clanCoins[plrOnlineClanID] = SQL_FetchInt(result, 3);

		int oppnntClanID, oppnntOnlineClanID;
		if((oppnntClanID = g_clanWar_oppnntClanID[plrOnlineClanID] = SQL_FetchInt(result, 4))) {
			SQL_FetchString(result, 5, g_clanWar_oppnntClanName[plrOnlineClanID], MAX_CLANNAME_LENGTH-1);
			g_clanWar_frags[plrOnlineClanID][0] = SQL_FetchInt(result, 6);
			g_clanWar_endTime[plrOnlineClanID] = SQL_FetchInt(result, 8);

			for (int i = 1; i <= MaxClients; i++) {
				if (g_clanID[i] == oppnntClanID) {
					oppnntOnlineClanID = g_clanWar_oppnntOnlineClanID[plrOnlineClanID] = i;
					g_clanWar_frags[plrOnlineClanID][1] = g_clanWar_frags[i][0];

					g_clanWar_oppnntOnlineClanID[i] = plrOnlineClanID;
					g_clanWar_frags[i][1] = g_clanWar_frags[plrOnlineClanID][0];

					break;
				}
			}

			if (!oppnntOnlineClanID) {
				g_clanWar_oppnntOnlineClanID[plrOnlineClanID] = 0;
				g_clanWar_frags[plrOnlineClanID][1] = SQL_FetchInt(result, 7);
			}

			g_clanWar_timer[plrOnlineClanID] = CreateTimer(1.0, timer_WarCountdown, plrOnlineClanID, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}

		g_clanWar_block[plrOnlineClanID] = view_as<bool>(SQL_FetchInt(result, 9));
		for (int i = 0; i < 3; i++) {
			g_clanWar_stats[plrOnlineClanID][i] = SQL_FetchInt(result, 10+i);
		}

		for (int i = 1; i < MAXSTATS; i++) {
			statsSum += (g_clanStats[plrOnlineClanID][i] = SQL_FetchInt(result, i+12));
		}

		g_clanStats[plrOnlineClanID][TO_ASSIGN] = g_clanLevel[plrOnlineClanID] - statsSum - 1;
	}
}

bool IsPlayerInClan(int client, int clanID, bool info) {
	if (g_clanID[g_plrOnlineClanID[client]] != clanID) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Nie należysz do tego klanu!");
		}

		return false;
	}

	return true;
}

bool IsPlayerInAnyClan(int client, bool info) {
	if (!g_plrOnlineClanID[client]) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Nie należysz do żadnego klanu!");
		}

		return false;
	}

	return true;
}

bool HasPlayerClanRank(int client, int clanRankID, bool info) {
	if (g_plrClanRankID[client] < clanRankID) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Nie masz dostępu do tej funkcji.");
		}

		return false;
	}

	return true;
}

bool IsPlayerDataProcessing(int client, bool info) {
	for (int i = 0; i < MAXQUERIES; i++) {
		if (g_isPlayerDataProcessing[client][i]) {
			if (info) {
				PrintToChat(client, " \x04\x06[KLANY]\x01 Trwa przetwarzanie danych...");
			}

			return true;
		}
	}

	return false;
}


bool HasPlayerClanWar(int client, bool info) {
	int plrOnlineClanID = g_plrOnlineClanID[client];

	if (g_clanWar_oppnntClanID[plrOnlineClanID]) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Twój klan prowadzi aktualnie wojnę!");
		}

		return true;
	}

	return false;
}


bool IsItTooLateForWar(int client, bool info) {
	int timeLeft;
	GetMapTimeLeft(timeLeft)

	if (timeLeft && timeLeft <= (g_warTime+15)) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Już za późno na wojnę!");
		}

		return true;
	}

	return false;
}

bool IsWarmupOn(int client, bool info) {
	if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
		if (info) {
			PrintToChat(client, " \x04\x06[KLANY]\x01 Aktualnie trwa rozgrzewka!");
		}

		return true;
	}

	return false;
}

int GetClientOfSteamId(const char[] steamID) {
	char plrSteamID[64];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientAuthorized(i) || !GetClientAuthId(i, AuthId_Steam2, plrSteamID, sizeof(plrSteamID))) {
			continue;
		}

		if (StrEqual(steamID, plrSteamID)) {
			return i;
		}
	}

	return 0;
}