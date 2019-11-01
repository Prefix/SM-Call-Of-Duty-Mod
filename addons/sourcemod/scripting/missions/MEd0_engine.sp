#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo = {
        name = "Missions Engine",
        author = "d0naciak",
        description = "API for missions",
        version = "1.0.0",
        url = "d0naciak.pl"
};

Database g_sqlConn;
ArrayList g_missionName, g_missionDesc, g_missionReqProgress, g_missionAward, g_chapterName, g_chapterReqLevel, g_chapterMissions;
ConVar g_cvMinPlayers;
Handle g_fwEngineGotReady, g_fwOnMissionsReload, g_fwOnMissionComplete;
bool g_allPluginsLoaded, g_isPluginLoaded;

int g_plrActiveMissionID[MAXPLAYERS+1], g_plrMissionProgress[MAXPLAYERS+1];
bool g_isPlayerDataLoading[MAXPLAYERS+1];

public void OnPluginStart() {
	RegConsoleCmd("sm_misje", cmd_Missions, "display missions menu");
	RegConsoleCmd("sm_misja", cmd_Missions, "display missions menu");
	RegConsoleCmd("sm_mission", cmd_Missions, "display missions menu");
	RegConsoleCmd("sm_missions", cmd_Missions, "display missions menu");

	RegServerCmd("me_removemission", cmd_RemoveMission, "removes all mision data");

	g_cvMinPlayers = CreateConVar("mission_min_players", "4", "min players required to change client mission progress")
	AutoExecConfig(true, "codmod_missions");

	char error[512];
	g_sqlConn = SQL_Connect("missions", true, error, sizeof(error));
	if (g_sqlConn == INVALID_HANDLE) {
		PrintToServer("Can't connect to database: %s", error);
	} else {
		SQL_LockDatabase(g_sqlConn);

		char query[][] = {
				"SET SQL_MODE=\"NO_AUTO_VALUE_ON_ZERO\"",

				"CREATE TABLE IF NOT EXISTS med0_players\
				( \
					playerID int NOT NULL AUTO_INCREMENT, \
					steamID varchar(64) NOT NULL, \
					activeMissionID int NOT NULL DEFAULT 0,  \
					missionProgress int NOT NULL DEFAULT 0,  \
					PRIMARY KEY (playerID), \
					UNIQUE (steamID) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS med0_missions \
				( \
					missionID int NOT NULL AUTO_INCREMENT, \
					missionName varchar(64) NOT NULL, \
					chapterID int NOT NULL DEFAULT 0, \
					position int NOT NULL DEFAULT 0, \
					PRIMARY KEY (missionID), \
					UNIQUE (missionName) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;",

				"CREATE TABLE IF NOT EXISTS med0_plrs_missions \
				( \
					playerID int NOT NULL, \
					missionID int NOT NULL, \
					isPassed boolean NOT NULL DEFAULT true, \
					CONSTRAINT playerMissionId UNIQUE (playerID, missionID) \
				) ENGINE = InnoDB DEFAULT CHARSET = utf8;"
			}
		if (SQL_FastQuery(g_sqlConn, query[0]) && SQL_FastQuery(g_sqlConn, query[1]) && SQL_FastQuery(g_sqlConn, query[2]) && SQL_FastQuery(g_sqlConn, query[3])) {
			PrintToServer("Missions Engine: Database is ready to work!");
		} else {
			if (SQL_GetError(g_sqlConn, error, sizeof(error))) {
				PrintToServer("Missions Engine: Error while creating tables: %s", error);
			}
		}


		SQL_UnlockDatabase(g_sqlConn);
	}

	g_missionName = new ArrayList(64);
	g_missionDesc = new ArrayList(256);
	g_missionReqProgress = new ArrayList(1);
	g_missionAward = new ArrayList(256);

	g_chapterName = new ArrayList(64);
	g_chapterReqLevel = new ArrayList(1);
	g_chapterMissions = new ArrayList(64);

	RegisterMission("Brak", "-", 0, "-");

	g_fwEngineGotReady = CreateGlobalForward("MEd0_EngineGotReady", ET_Ignore);
	g_fwOnMissionsReload = CreateGlobalForward("MEd0_OnMissionsReload", ET_Ignore);
	g_fwOnMissionComplete = CreateGlobalForward("MEd0_OnMissionComplete", ET_Ignore, Param_Cell, Param_Cell);

	g_isPluginLoaded = true;
	Call_StartForward(g_fwEngineGotReady);
	Call_Finish();
}

public void OnAllPluginsLoaded() {
	g_allPluginsLoaded = true;
}

public void OnMapStart() {
	AddFileToDownloadsTable("sound/CodMod_d0naciak/missions/complete.mp3");
	PrecacheSound("*/CodMod_d0naciak/missions/complete.mp3");

	ReadChapters();
}

public Action cmd_Missions(int client, int args) {
	if(g_isPlayerDataLoading[client]) {
		PrintMsg(client, "Trwa wczytywanie danych, spróbuj ponownie za chwilę.");
		return Plugin_Handled;
	}

	if(g_plrActiveMissionID[client]) {
		menu_MissionStatus(client);
	} else {
		menu_SelectChapter(client);
	}

	return Plugin_Handled;
}

void menu_SelectChapter(int client) {
	Menu menu = new Menu(menu_SelectChapter_Handler, MENU_ACTIONS_ALL);
	int chaptersNum = g_chapterName.Length;
	char chapterName[64], item[128];

	menu.SetTitle("Wybierz rozdział:");

	for (int i = 0; i < chaptersNum; i++) {
		g_chapterName.GetString(i, chapterName, sizeof(chapterName));
		Format(item, sizeof(item), "%s [Od %dLv]", chapterName, g_chapterReqLevel.Get(i))
		menu.AddItem("", item);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int menu_SelectChapter_Handler(Menu menu, MenuAction action, int client, int item) {
	switch (action) {
		case MenuAction_Select: {
			char query[512], steamID[64];

			if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
				PrintMsg(client, "Niespodziwany błąd autoryzacji!");
			} else {
				int reqLevel = g_chapterReqLevel.Get(item);

				if (CodD0_GetClientLevel(client) < reqLevel) {
					PrintMsg(client, "Ten rozdział jest dostępny dopiero od\x0E %d poziomu!", reqLevel);
				} else {
					Format(query, sizeof(query), "SELECT m.missionName FROM med0_missions AS m LEFT JOIN med0_plrs_missions AS pm ON m.missionID=pm.missionID LEFT JOIN med0_players AS p ON pm.playerID=p.playerID WHERE (p.steamID='%s' OR p.steamID IS NULL) AND m.chapterID=%d AND (pm.isPassed IS NOT true OR pm.isPassed IS NULL) GROUP BY m.missionName ORDER BY m.position LIMIT 1", steamID, item+1)
					g_sqlConn.Query(tquery_ReadNextMissionOnChapter, query, GetClientUserId(client));
				}
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

public void tquery_ReadNextMissionOnChapter(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_ReadNextMissionOnChapter error: %s", error);
		return;
	}

	int client = GetClientOfUserId(data);

	if (!client) {
		return;
	}

	if (results.RowCount > 0) {
		if (results.FetchRow()) {
			Menu menu = new Menu(menu_StartMission_Handler, MENU_ACTIONS_ALL);
			char itemName[512], name[64], desc[256], award[256], szMissionID[8];

			results.FetchString(0, name, sizeof(name));

			int missionID = g_missionName.FindString(name);
			IntToString(missionID, szMissionID, sizeof(szMissionID));
			g_missionDesc.GetString(missionID, desc, sizeof(desc));
			g_missionAward.GetString(missionID, award, sizeof(award));

			Format(itemName, sizeof(itemName), "Misja: %s\nOpis: %s\nNagroda: %s", name, desc, award);
			menu.SetTitle(itemName);
			menu.AddItem(szMissionID, "Podejmuje wyzwanie");
			menu.ExitBackButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}
	} else {
		menu_SelectChapter(client);
		PrintMsg(client, "Już wykonałeś wszystkie misje w tym rozdziale!");
	}
}

public int menu_StartMission_Handler(Menu menu, MenuAction action, int client, int item) {
	switch (action) {
		case MenuAction_Select: {
			char szMissionID[8], name[64], desc[256], award[256];

			menu.GetItem(item, szMissionID, sizeof(szMissionID));
			int missionID = StringToInt(szMissionID);

			g_plrActiveMissionID[client] = missionID;

			g_missionName.GetString(missionID, name, sizeof(name));
			g_missionDesc.GetString(missionID, desc, sizeof(desc));
			g_missionAward.GetString(missionID, award, sizeof(award));

			PrintMsg(client, "Rozpoczęto misje pt.\x06 '%s'", name);
			PrintMsg(client, "Opis: %s", desc);
			PrintMsg(client, "Nagroda: %s", award);
			PrintMsg(client, "Życzymy powodzenia!");
		}

		case MenuAction_Cancel: {
			if (item == MenuCancel_ExitBack) {
				menu_SelectChapter(client);
			}
		}

		case MenuAction_End: {
			delete menu;
		}
	}
}

void menu_MissionStatus(int client) {
	char itemName[256], name[64], desc[256], award[256];

	int missionID = g_plrActiveMissionID[client];

	g_missionName.GetString(missionID, name, sizeof(name));
	g_missionDesc.GetString(missionID, desc, sizeof(desc));
	g_missionAward.GetString(missionID, award, sizeof(award));
	
	Menu menu = new Menu(menu_MissionStatus_Handler, MENU_ACTIONS_ALL);
	Format(itemName, sizeof(itemName), "✢ Misja: %s ✢", name);
	menu.AddItem("", itemName);
	Format(itemName, sizeof(itemName), "✢ Opis: %s ✢", desc);
	menu.AddItem("", itemName);
	Format(itemName, sizeof(itemName), "✢ Postęp: %d/%d ✢", g_plrMissionProgress[client], g_missionReqProgress.Get(missionID));
	menu.AddItem("", itemName);
	Format(itemName, sizeof(itemName), "✢ Nagroda: %s ✢", award);
	menu.AddItem("", itemName);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int menu_MissionStatus_Handler(Menu menu, MenuAction action, int client, int item) {
	if(action == MenuAction_DrawItem) {
		return ITEMDRAW_DISABLED;
	}

	return 0;
}

public void OnClientAuthorized(int client, const char[] steamID) {
	ReadPlayerData(client, steamID);
}

public void OnClientDisconnect(int client) {
	char steamID[64];

	if (GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
		SavePlayerData(client, steamID)
	}
}

public Action cmd_RemoveMission(int args) {
	if (args < 1) {
		PrintToServer("Usage: sm_removemission <name>");
		return Plugin_Handled;
	}

	char name[64]; 
	GetCmdArg(1, name, sizeof(name));
	int missionID = g_missionName.FindString(name);

	if(missionID == -1) {
		PrintToServer("*** Can't find mission named %s", name);
		return Plugin_Handled;
	}

	char plrMissionName[64], escapedName[128], steamID[64], query[512], error[256];

	SQL_LockDatabase(g_sqlConn);

	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientAuthorized(i) || !g_plrActiveMissionID[i] || !GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			continue;
		}

		g_missionName.GetString(g_plrActiveMissionID[i], plrMissionName, sizeof(plrMissionName));
		g_sqlConn.Escape(plrMissionName, escapedName, sizeof(escapedName));

		Format(query, sizeof(query), "UPDATE med0_players SET activeMissionID=(SELECT missionID FROM med0_missions WHERE missionName='%s'), missionProgress=%d WHERE steamID='%s'", escapedName, g_plrMissionProgress[i], steamID);
		if (!SQL_FastQuery(g_sqlConn, query)) {
			SQL_GetError(g_sqlConn, error, sizeof(error));
			LogError("cmd_RemoveMission error: %s", error);
		}
	}

	/*DBResultSet results = SQL_Query(db, "SELECT missionID FROM med0_missions WHERE missionName='%s'", escapedName);

	if(results == null) {
		SQL_GetError(g_sqlConn, error, sizeof(error));
		LogError("cmd_RemoveMission error: %s", error);
	} else if(results.FetchRow()) {
		sqlMissionID = results.FetchInt(0);
		delete results; 
	}*/

	g_sqlConn.Escape(name, escapedName, sizeof(escapedName));
	Format(query, sizeof(query), "UPDATE med0_players AS p INNER JOIN med0_missions AS m ON p.activeMissionID=m.missionID SET p.activeMissionID=0, p.missionProgress=0 WHERE m.missionName='%s'", escapedName);
	if (!SQL_FastQuery(g_sqlConn, query)) {
		SQL_GetError(g_sqlConn, error, sizeof(error));
		LogError("cmd_RemoveMission error: %s", error);
	}

	Format(query, sizeof(query), "DELETE m.*, pm.* FROM med0_plrs_missions AS pm INNER JOIN med0_missions AS m ON pm.missionID=m.missionID WHERE m.missionName='%s'", escapedName); //maybe better?
	if (!SQL_FastQuery(g_sqlConn, query)) {
		SQL_GetError(g_sqlConn, error, sizeof(error));
		LogError("cmd_RemoveMission error: %s", error);
	}

	g_missionName.Erase(missionID);
	g_missionDesc.Erase(missionID);
	g_missionReqProgress.Erase(missionID);
	g_missionAward.Erase(missionID);

	Call_StartForward(g_fwOnMissionsReload);
	Call_Finish();

	SQL_UnlockDatabase(g_sqlConn);

	for( int i = 1; i <= MaxClients; i++) {
		if (!IsClientAuthorized(i) || !GetClientAuthId(i, AuthId_Steam2, steamID, sizeof(steamID))) {
			continue;
		}

		ReadPlayerData(i, steamID);
	}


	PrintToServer("*** Mission %s has been removed.", name);
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorLen) {
	RegPluginLibrary("MEd0");

	CreateNative("MEd0_RegisterMission", nat_RegisterMission);

	CreateNative("MEd0_IsEngineReady", nat_IsEngineReady);
	CreateNative("MEd0_GetMissionID", nat_GetMissionID);

	CreateNative("MEd0_GetClientMission", nat_GetClientMission);
	CreateNative("MEd0_GetClientMissionPrgrs", nat_GetClientMissionPrgrs);

	CreateNative("MEd0_GetMissionName", nat_GetMissionName);
	CreateNative("MEd0_GetMissionDesc", nat_GetMissionDesc);
	CreateNative("MEd0_GetMissionReqPrgrs", nat_GetMissionReqPrgrs);
	CreateNative("MEd0_GetMissionAward", nat_GetMissionAward);

	CreateNative("MEd0_SetClientMission", nat_GetClientMission);
	CreateNative("MEd0_SetClientMissionPrgrs", nat_SetClientMissionPrgrs);

	return APLRes_Success;
}

int RegisterMission(const char[] name, const char[] desc, int reqProgress, const char[] award) {
	int sqlID = -1;
	DBResultSet results;
	char error[256], query[512], escapedName[128];
	static bool noMissionRecord;

	SQL_LockDatabase(g_sqlConn);

	g_sqlConn.Escape(name, escapedName, sizeof(escapedName));
	Format(query, sizeof(query), "SELECT missionID FROM med0_missions WHERE missionName='%s'", escapedName);
	results = SQL_Query(g_sqlConn, query);
	if (results != null) {
		if (results.RowCount) {
			if (results.FetchRow()) {
				sqlID = results.FetchInt(0);
			}
		} else {
			if(!noMissionRecord) {
				if(!SQL_FastQuery(g_sqlConn, "INSERT INTO med0_missions (missionID, missionName) VALUES (0, 'Brak')")) {
					if(SQL_GetError(g_sqlConn, error, sizeof(error))) {
						LogError("MEd0_RegisterMission: Insert none mission error: %s", error);
					}

					SQL_UnlockDatabase(g_sqlConn);
					return -1;
				}

				sqlID = SQL_GetInsertId(g_sqlConn);
			} else {
				Format(query, sizeof(query), "INSERT INTO med0_missions (missionName) VALUES ('%s')", escapedName);
				if (SQL_FastQuery(g_sqlConn, query)) {
					sqlID = SQL_GetInsertId(g_sqlConn);
				}
			}
		}
	}

	SQL_UnlockDatabase(g_sqlConn);

	if (sqlID == -1) {
		return -1;
	}

	noMissionRecord = true;
	int missionID = g_missionName.FindString(name);

	if(missionID >= 0) {
		g_missionDesc.SetString(missionID, desc);
		g_missionReqProgress.Set(missionID, reqProgress);
		g_missionAward.SetString(missionID, award);
	} else {
		missionID = g_missionName.Length;

		g_missionName.PushString(name);
		g_missionDesc.PushString(desc);
		g_missionReqProgress.Push(reqProgress);
		g_missionAward.PushString(award);
	}

	if(g_allPluginsLoaded) {
		ReadChapters();
	}

	return missionID;
}

public int nat_RegisterMission(Handle plugin, int paramsNum) {
	char name[64], desc[256], award[256];

	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, desc, sizeof(desc));
	GetNativeString(4, award, sizeof(award));
	return RegisterMission(name, desc, GetNativeCell(3), award);
}

public int nat_IsEngineReady(Handle plugin, int paramsNum) {
	return view_as<bool>(g_isPluginLoaded);
}

public int nat_GetMissionID(Handle plugin, int paramsNum) {
	char name[64];

	GetNativeString(1, name, sizeof(name));
	int missionID = g_missionName.FindString(name);

	if(missionID <= 0) {
		return 0;
	}

	return missionID;
}

public int nat_GetClientMission(Handle plugin, int paramsNum) {
	return g_plrActiveMissionID[GetNativeCell(1)];
}

public int nat_GetClientMissionPrgrs(Handle plugin, int paramsNum) {
	return g_plrMissionProgress[GetNativeCell(1)];
}

public int nat_GetMissionName(Handle plugin, int paramsNum) {
	char name[64];
	g_missionName.GetString(GetNativeCell(1), name, sizeof(name));
	SetNativeString(2, name, GetNativeCell(3));
}

public int nat_GetMissionDesc(Handle plugin, int paramsNum) {
	char desc[256];
	g_missionDesc.GetString(GetNativeCell(1), desc, sizeof(desc));
	SetNativeString(2, desc, GetNativeCell(3));
}

public int nat_GetMissionReqPrgrs(Handle plugin, int paramsNum) {
	return g_missionReqProgress.Get(GetNativeCell(1));
}

public int nat_GetMissionAward(Handle plugin, int paramsNum) {
	char award[256];
	g_missionAward.GetString(GetNativeCell(1), award, sizeof(award));
	SetNativeString(2, award, GetNativeCell(3));
}

public int nat_SetClientMission(Handle plugin, int paramsNum) {
	g_plrActiveMissionID[GetNativeCell(1)] = GetNativeCell(2);
}

public int nat_SetClientMissionPrgrs(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	if(g_isPlayerDataLoading[client]) {
		return view_as<int>(false);
	}

	bool force = view_as<bool>(GetNativeCell(3));
	if(GetClientCount(true) < g_cvMinPlayers.IntValue && !force) {
		return view_as<int>(false);
	}

	g_plrMissionProgress[client] = GetNativeCell(2);
	CheckMissionProgress(client);

	return view_as<int>(true);
}

void CheckMissionProgress(int client) {
	if(g_plrMissionProgress[client] >= g_missionReqProgress.Get(g_plrActiveMissionID[client])) {
		char steamID[64];

		if(!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
			return;
		}

		int missionID = g_plrActiveMissionID[client];
		char query[512], name[64], escapedName[128], award[256];

		g_missionName.GetString(missionID, name, sizeof(name));
		g_missionAward.GetString(missionID, award, sizeof(award));
		g_sqlConn.Escape(name, escapedName, sizeof(escapedName));

		Format(query, sizeof(query), "INSERT INTO med0_plrs_missions (playerID, missionID) SELECT playerID, missionID FROM med0_players, med0_missions WHERE steamID='%s' AND missionName='%s'", steamID, escapedName);
		g_sqlConn.Query(tquery_InsertDoneMission, query);

		g_plrActiveMissionID[client] = g_plrMissionProgress[client] = 0;

		Call_StartForward(g_fwOnMissionComplete);
		Call_PushCell(client);
		Call_PushCell(missionID);
		Call_Finish();

		PrintMsg(client, "Gratulacje! Misja\x0E %s\x01 została ukończona!", name);
		PrintMsg(client, "Nagroda:\x05 %s", award);

		ClientCommand(client, "play */CodMod_d0naciak/missions/complete.mp3");
	}
}

public void tquery_InsertDoneMission(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_InsertDoneMission error: %s", error);
		return;
	}
}

void ReadPlayerData(int client, const char[] steamID) {
	char query[512];

	g_isPlayerDataLoading[client] = true;

	Format(query, sizeof(query), "SELECT m.missionName, p.missionProgress FROM med0_players AS p INNER JOIN med0_missions AS m ON p.activeMissionID=m.missionID WHERE p.steamID='%s'", steamID);
	g_sqlConn.Query(tquery_ReadPlayerData, query, GetClientUserId(client));
}

public void tquery_ReadPlayerData(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_ReadPlayerData error: %s", error);
		return;
	}

	int client = GetClientOfUserId(data);

	if (!client) {
		return;
	}

	if (results.RowCount > 0) {
		if (results.FetchRow()) {
			char name[64];

			results.FetchString(0, name, sizeof(name));
			g_plrActiveMissionID[client] = g_missionName.FindString(name);
			g_plrMissionProgress[client] = results.FetchInt(1);

			g_isPlayerDataLoading[client] = false;
		}
	} else {
		char query[512], steamID[64];

		if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) {
			return;
		}

		Format(query, sizeof(query), "INSERT INTO med0_players (steamID) VALUES ('%s')", steamID);
		g_sqlConn.Query(tquery_InsertPlayerData, query, data);
	}
}


public void tquery_InsertPlayerData(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_InsertPlayerData error: %s", error);
		return;
	}

	int client = GetClientOfUserId(data);

	if (client) {
		g_plrActiveMissionID[client] = 0;
		g_plrMissionProgress[client] = 0;

		g_isPlayerDataLoading[client] = false;
	}
}

void SavePlayerData(client, const char[] steamID) {
	if (g_isPlayerDataLoading[client]) {
		return;
	}

	char query[512], missionName[64], escapedMissionName[192];

	g_missionName.GetString(g_plrActiveMissionID[client], missionName, sizeof(missionName));
	g_sqlConn.Escape(missionName, escapedMissionName, sizeof(escapedMissionName));

	Format(query, sizeof(query), "UPDATE med0_players SET activeMissionID=(SELECT missionID FROM med0_missions WHERE missionName='%s'), missionProgress=%d WHERE steamID='%s'", escapedMissionName, g_plrMissionProgress[client], steamID);
	g_sqlConn.Query(tquery_SavePlayerData, query);
}

public void tquery_SavePlayerData(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_SavePlayerData error: %s", error);
		return;
	}
}

void ReadChapters() {
	g_chapterName.Clear();
	g_chapterReqLevel.Clear();
	g_chapterMissions.Clear();

	char chapterName[64], missionName[64], escapedMissionName[128], query[512];
	int missionID, reqLevel, chapterID;
	KeyValues keyValues = new KeyValues("Chapters");
	keyValues.ImportFromFile("addons/sourcemod/configs/MEd0_chapters.cfg");
 
	if (!keyValues.GotoFirstSubKey()) {
		delete keyValues;
		return;
	}

	do {
		keyValues.GetSectionName(chapterName, sizeof(chapterName));

		chapterID ++;
		reqLevel = keyValues.GetNum("required_level");
		if (!keyValues.GotoFirstSubKey()) {
			continue;
		}

		int chapterMissionID[64], pos;
		do {
			keyValues.GetSectionName(missionName, sizeof(missionName)); //check - required_level is a section?
			missionID = g_missionName.FindString(missionName);

			if(missionID == -1) {
				LogError("MEd0_chapters.cfg error: Can't find mission %s", missionName);
			}

			chapterMissionID[pos++] = missionID;

			g_sqlConn.Escape(missionName, escapedMissionName, sizeof(escapedMissionName));
			Format(query, sizeof(query), "UPDATE med0_missions SET chapterID=%d, position=%d WHERE missionName='%s'", chapterID, pos, escapedMissionName);
			g_sqlConn.Query(tquery_SetMissionPosition, query);
		} while (keyValues.GotoNextKey());

		g_chapterName.PushString(chapterName);
		g_chapterReqLevel.Push(reqLevel);
		g_chapterMissions.PushArray(chapterMissionID);

		keyValues.GoBack();
	} while (keyValues.GotoNextKey());

	delete keyValues;
	PrintToServer("*** MEd0_chapters.cfg has been (re)loaded");
}

public void tquery_SetMissionPosition(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		LogError("tquery_SetMissionPosition error: %s", error);
		return;
	}
}

void PrintMsg(int client, const char[] msg, any ...) {
	char formatedMsg[512];

	VFormat(formatedMsg, sizeof(formatedMsg), msg, 3);
	PrintToChat(client, " \x06\x04[COD:MISJE]\x01 %s", formatedMsg);
}