#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>
#include <MEd0_engine>

public Plugin myinfo = {
        name = "Mission: Pistol operation",
        author = "d0naciak",
        description = "Mission: Pistol operation",
        version = "1.0.0",
        url = "d0naciak.pl"
};

char g_name[] = "Obsługa pistoletu";
char g_desc[] = "Zabij 50 przeciwników z pistoletu";
int g_reqProgress = 50;
char g_award[] = "250 dośw., 20$";

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

		if(StrEqual(weaponName, "usp_silencer") || StrEqual(weaponName, "deagle") || StrEqual(weaponName, "elite") || StrEqual(weaponName, "fiveseven") || StrEqual(weaponName, "glock") || StrEqual(weaponName, "hkp2000") || StrEqual(weaponName, "p250") || StrEqual(weaponName, "tec9") || StrEqual(weaponName, "cz75a")) {
			MEd0_SetClientMissionPrgrs(attacker, MEd0_GetClientMissionPrgrs(attacker) + 1);
		}
	}
}

public void MEd0_OnMissionComplete(int client, int missionID) {
	if(g_missionID == missionID) {
		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + 250);
		CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + 20);
	}
}
