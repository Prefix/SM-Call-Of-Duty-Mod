#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Aimer",
        author = "d0naciak",
        description = "Mission: Aimer",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Aimer";
char g_desc[] = "Zabij 25 przeciwnikow z HeadShota";
int g_reqProgress = 25;
char g_award[] = "20$";

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
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker && MEd0_GetClientMission(attacker) == g_missionID && GetEventBool(event, "headshot")) {
		MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 20);
	}
}
