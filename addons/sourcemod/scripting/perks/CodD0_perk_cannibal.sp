/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "CodD0 Perk: Cannibal",
	author = "d0naciak",
	description =  "Cannibal",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_perkID;
bool g_used[MAXPLAYERS + 1];

public void OnPluginStart() {
	g_perkID = CodD0_RegisterPerk("Kanibal", "Użyj na kompanie z drużyny, aby uleczyć się o 50HP. Perk dostępny raz na rundę, nie ograniczają go statystyki");

	HookEvent("round_start", ev_RoundStart_Post);
}

public void OnPluginEnd() {
	CodD0_UnregisterPerk(g_perkID);
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		g_used[i] = false;
	}
}

public void CodD0_PerkUsed(int client, int perkID) {
	if (g_perkID != perkID) {
		return;
	}

	if (g_used[client]) {
		PrintCenterText(client, "Perk jest dostępny tylko raz na rundę!");
		return;
	}

	float position[2][3];
	int target;
	bool thereIs;

	GetClientAbsOrigin(client, position[0]);

	for (target = 1; target <= MaxClients; target++) {
		if (client == target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(client) != GetClientTeam(target)) {
			continue;
		}

		GetClientAbsOrigin(target, position[1]);
			
		if (GetVectorDistance(position[0], position[1]) <= 100.0) {
			thereIs = true;
			break;
		}
	}
	
	if(!thereIs) {
		PrintCenterText(client, "Aby zabrać życie kompanowi, musisz być blisko niego!");
		return;
	}
	
	g_used[client] = true;
	SetEntityHealth(client, GetClientHealth(client) + 50);
	
	PrintCenterText(client, "Uleczyłeś się!");
}
	