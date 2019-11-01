#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Quick action",
        author = "d0naciak",
        description = "Mission: Quick action",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Szybka akcja";
char g_desc[] = "Zabij 3 przeciwników w ciągu jednej rundy";
int g_reqProgress = 3;
char g_award[] = "250 dośw.";

int g_missionID;

public void OnPluginStart() {
	if(MEd0_IsEngineReady()) {
		g_missionID = MEd0_RegisterMission(g_name, g_desc, g_reqProgress, g_award);
	}

	HookEvent("round_start", ev_RoundStart_Post);
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

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && MEd0_GetClientMission(i) == g_missionID) {
			MEd0_SetClientMissionPrgrs(i, 0);
		}
	}
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker && MEd0_GetClientMission(attacker) == g_missionID) {
		MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 250);
	}
}
