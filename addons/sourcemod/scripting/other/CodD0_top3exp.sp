#include <sourcemod>
#include <cstrike>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "CODMOD: TOP 3 Exp",
	author = "d0naciak",
	description = "Gives exp for top 3 players",
	version = "1.0",
	url = "-"
}

ConVar g_minPlayers, g_award[3];

public void OnPluginStart() {
	HookEvent("cs_win_panel_match", ev_WinPanelMatch);

	g_minPlayers = CreateConVar("cod_top3xp_minplayers", "6", "Min. players to give exp at the end of the match");
	g_award[0] = CreateConVar("cod_top3xp_1st", "500", "Award for 1st place");
	g_award[1] = CreateConVar("cod_top3xp_2nd", "400", "Award for 2nd place");
	g_award[2] = CreateConVar("cod_top3xp_3rd", "300", "Award for 3rd place");

	AutoExecConfig(true, "codmod_top3exp");
}

public void ev_WinPanelMatch(Handle event, const char[] evName, bool dontBroadcast) {
	if(GetClientCount() < g_minPlayers.IntValue) {
		return;
	}

	int topClients[3], topScore[3], targetScore;

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i)) {
			continue;
		}

		targetScore = CS_GetClientContributionScore(i);

		for(int j = 0; j < 3; j++) {
			if(targetScore >= topScore[j]) {
				for(int k = 2; k > j; k--) {
					topScore[k] = topScore[k-1];
					topClients[k] = topClients[k-1];
				}

				topScore[j] = targetScore;
				topClients[j] = i;
				break;
			}
		}
	}

	char name[64];
	int targetID, exp;

	PrintToChatAll(" \x05\x06 ~\x01 Nagrody dla najlepszych graczy:");
	for(int i = 0; i < 3; i++) {
		if(!topClients[i]) {
			break;
		}

		targetID = topClients[i];
		exp = g_award[i].IntValue;

		GetClientName(targetID, name, sizeof(name));

		PrintToChatAll(" \x05\x06 #%d.\x0E %s\x01 -\x06 %d pkt.\x01 zgarnia\x05 +%d dośw.", i+1, name, topScore[i], exp);
		CodD0_SetClientExp(targetID, CodD0_GetClientExp(targetID) + exp);
	}
}