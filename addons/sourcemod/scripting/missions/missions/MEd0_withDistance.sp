#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: With distance",
        author = "d0naciak",
        description = "Mission: With distance",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Z dystansem";
char g_desc[] = "Zabij 25 przeciwników z odległości min. 10m";
int g_reqProgress = 25;
char g_award[] = "700 dośw., 20$";

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
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		float position[2][3];

		GetClientAbsOrigin(attacker, position[0]);
		GetClientAbsOrigin(victim, position[1]);

		if (GetVectorDistance(position[0], position[1]) >= 600.0) {
			MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
		}
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 700);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 20);
	}
}
