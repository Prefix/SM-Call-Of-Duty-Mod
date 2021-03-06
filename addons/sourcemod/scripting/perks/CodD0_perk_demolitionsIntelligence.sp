/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "CodD0 Perk: Demolitions intelligence",
	author = "d0naciak",
	description =  "Demolitions intelligence",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_perkID;

public void OnPluginStart() {
	g_perkID = CodD0_RegisterPerk("Inteligencja Demolitions", "+LW do statystyki inteligencji", 15, 45);
}

public OnPluginEnd() {
	CodD0_UnregisterPerk(g_perkID);
}

public void CodD0_PerkChanged_Post(int client, int perkID, int perkValue) {
	static int perkLastValue[MAXPLAYERS + 1];

	if(perkID == g_perkID) {
		CodD0_SetClientBonusStatsPoints(client, INT_PTS, CodD0_GetClientBonusStatsPoints(client, INT_PTS) + perkValue - perkLastValue[client]);
		perkLastValue[client] = perkValue;
	} else if(perkLastValue[client]) {
		CodD0_SetClientBonusStatsPoints(client, INT_PTS, CodD0_GetClientBonusStatsPoints(client, INT_PTS) - perkLastValue[client]);
		perkLastValue[client] = 0;
	}
}