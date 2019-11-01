#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Hunter",
        author = "d0naciak",
        description = "Mission: Hunter",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Łowca";
char g_desc[] = "Zdobądź 3 razy perk Nanokamizelka";
int g_reqProgress = 3;
char g_award[] = "350 dośw., 25$";

int g_missionID;

public void OnPluginStart() {
	if(MEd0_IsEngineReady()) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}
}

public void MEd0_EngineGotReady() {
	if(!g_missionID) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}
}

public void MEd0_OnMissionsReload() {
	g_missionID = MEd0_GetMissionID(g_name);
}

public void CodD0_PerkChanged_Post(int client, int perkID, int perkValue) {
	if (MEd0_GetClientMission(client) != g_missionID) {
		return;
	}

	CreateTimer(1.0, timer_AddProgress, GetClientUserId(client));
}

public Action timer_AddProgress(Handle timer, any userID) {
	int client = GetClientOfUserId(userID);

	if(!client || MEd0_GetClientMission(client) != g_missionID) {
		return Plugin_Continue;
	}

	static int nanoPerkID;

	if(!nanoPerkID) {
		nanoPerkID = CodD0_GetPerkID("Nanokamizelka");
	}

	if(nanoPerkID == CodD0_GetClientPerk(client)) {
		MEd0_SetClientMissionPrgrs(client, MEd0_GetClientMissionPrgrs(client) + 1);
	}

	return Plugin_Continue;
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 350);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 25);
	}
}
