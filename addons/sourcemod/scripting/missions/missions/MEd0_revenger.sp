#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Revenger",
        author = "d0naciak",
        description = "Mission: Revenger",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Mściciel";
char g_desc[] = "Zdobądź zemstę 60 razy";
int g_reqProgress = 75;
char g_award[] = "2500 dośw., 60$";

int g_missionID;

public void OnPluginStart() {
	if(MEd0_IsEngineReady()) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}

	HookEvent("player_death", ev_PlayerDeath_Post);
}

public void MEd0_EngineGotReady() {
	if(!g_missionID) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}
}

public void MEd0_OnMissionsReload() {
	g_missionID = MEd0_GetMissionID(g_name);
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client && MEd0_GetClientMission(client) == g_missionID && GetEventInt(event, "revenge")) {
		MEd0_SetClientMissionPrgrs(client, MEd0_GetClientMissionPrgrs(client) + 1);
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 2500);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 60);
	}
}
