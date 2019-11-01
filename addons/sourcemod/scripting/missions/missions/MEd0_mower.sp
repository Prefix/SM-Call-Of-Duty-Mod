#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Mower",
        author = "d0naciak",
        description = "Mission: Mower",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Kosiarz";
char g_desc[] = "Zabij 25 przeciwników z granata wybuchowego";
int g_reqProgress = 25;
char g_award[] = "4000 dośw., 75$";

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

	if(attacker && MEd0_GetClientMission(attacker) == g_missionID) {
		char weaponName[32];
		GetEventString(event, "weapon", weaponName, sizeof(weaponName));

		if (StrContains(weaponName, "knife") != -1) {
			MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
		}
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 4000);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 75);
	}
}
