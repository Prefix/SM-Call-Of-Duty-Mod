#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Important element",
        author = "d0naciak",
        description = "Mission: Important element",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Ważny element";
char g_desc[] = "Zdobądź nagrodę MVP 75 razy";
int g_reqProgress = 75;
char g_award[] = "2000 dośw., 50$";

int g_missionID;

public void OnPluginStart() {
	if(MEd0_IsEngineReady()) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}

	HookEvent("round_mvp", ev_RoundMVP_Post);
}

public void MEd0_EngineGotReady() {
	if(!g_missionID) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}
}

public void MEd0_OnMissionsReload() {
	g_missionID = MEd0_GetMissionID(g_name);
}

public void ev_RoundMVP_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && MEd0_GetClientMission(client) == g_missionID) {
		MEd0_SetClientMissionPrgrs(client, MEd0_GetClientMissionPrgrs(client) + 1);
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 2000);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 50);
	}
}
