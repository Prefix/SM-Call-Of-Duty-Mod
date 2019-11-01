#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Rescuer",
        author = "d0naciak",
        description = "Mission: Rescuer",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Ratownik";
char g_desc[] = "Uratuj zakładnika 16 razy";
int g_reqProgress = 16;
char g_award[] = "1250 dośw., 40$";

int g_missionID;

public void OnPluginStart() {
	if(MEd0_IsEngineReady()) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}

	HookEvent("hostage_rescued", ev_HostageRescued_Post);
}

public void MEd0_EngineGotReady() {
	if(!g_missionID) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}
}

public void MEd0_OnMissionsReload() {
	g_missionID = MEd0_GetMissionID(g_name);
}

public void ev_HostageRescued_Post(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && MEd0_GetClientMission(client) == g_missionID) {
		MEd0_SetClientMissionPrgrs(client, MEd0_GetClientMissionPrgrs(client) + 1);
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 1250);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 40);
	}
}
