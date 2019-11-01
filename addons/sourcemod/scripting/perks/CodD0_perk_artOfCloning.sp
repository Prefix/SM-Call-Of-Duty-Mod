/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_replicas>

public Plugin myinfo =  {
	name = "CodD0 Perk: Art of cloning",
	author = "d0naciak",
	description =  "Art of cloning",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_perkID;
bool g_hasPerk[MAXPLAYERS + 1];

public void OnPluginStart() {
	g_perkID = CodD0_RegisterPerk("Sztuka klonowania", "Możesz postawić 4 kukły, które odbijają obrażenia. Można je zniszczyć nożem");
}

public void OnPluginEnd() {
	CodD0_UnregisterPerk(g_perkID);
}

public Action CodD0_PerkChanged(int client, int perkID, int perkValue) {
	if(g_perkID == perkID) {
		if(CodD0_GetClientReplicas(client, CodD0_SkillSlot_Class)) {
			return Plugin_Handled;
		}
	} else if(g_hasPerk[client]) {
		CodD0_SetClientReplicas(client, CodD0_SkillSlot_Perk, 0, 0.0, 0.0);
		g_hasPerk[client] = false;
	}
	
	return Plugin_Continue;
}

public void CodD0_PerkChanged_Post(int client, int perkID, int perkValue) {
	if (perkID == g_perkID && !g_hasPerk[client]) {
		CodD0_SetClientReplicas(client, CodD0_SkillSlot_Perk, 4, 16.0, 0.16);
		g_hasPerk[client] = true;
	}
}

public void CodD0_PerkUsed(int client, int perkID) {
	if(!g_hasPerk[client]) {
		return;
	}

	if(CodD0_PlaceReplica(client, CodD0_SkillSlot_Perk) == CodD0_SkillPrep_Available) {
		CodD0_ClientClassSkillGotReady(client, 6.0);
	}
}