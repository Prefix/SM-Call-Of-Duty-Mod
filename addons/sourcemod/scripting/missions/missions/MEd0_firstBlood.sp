#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: First blood",
        author = "d0naciak",
        description = "Mission: First blood",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Pierwsza krew";
char g_desc[] = "Zabij 80 przeciwników jako pierwszy w rundzie";
int g_reqProgress = 80;
char g_award[] = "3000 dośw., 60$";

int g_missionID;
bool g_firstBlood;

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
	g_firstBlood = false;
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(attacker && MEd0_GetClientMission(attacker) == g_missionID && !g_firstBlood) {
		MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
	}

	g_firstBlood = true;
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 3000);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 60);
	}
}
