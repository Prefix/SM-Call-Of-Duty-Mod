/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_eagleEye>

public Plugin myinfo =  {
	name = "CodD0 Perk: Eagle eye",
	author = "d0naciak",
	description =  "Eagle eye",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_perkID;
bool g_hasPerk[MAXPLAYERS + 1];

public void OnPluginStart() {
	g_perkID = CodD0_RegisterPerk("Sokole oko", "Użyj, a będziesz widział wszystkich niewidzialnych przez 5 sec. LW / rundę", 1, 4);
}

public void OnPluginEnd() {
	CodD0_UnregisterPerk(g_perkID);
}

public Action CodD0_PerkChanged(int client, int perkID, int perkValue) {
	if(g_perkID != perkID && g_hasPerk[client]) {
		CodD0_SetClientEagleEye(client, CodD0_SkillSlot_Perk, 0, 0.0);
		g_hasPerk[client] = false;
	}
	
	return Plugin_Continue;
}

public void CodD0_PerkChanged_Post(int client, int perkID, int perkValue) {
	if (perkID == g_perkID) {
		CodD0_SetClientEagleEye(client, CodD0_SkillSlot_Perk, perkValue, 5.0);
		g_hasPerk[client] = true;
	}
}

public void CodD0_PerkUsed(int client, int perkID) {
	if (g_hasPerk[client]) {
		CodD0_UseEagleEye(client, CodD0_SkillSlot_Perk);
	}
}