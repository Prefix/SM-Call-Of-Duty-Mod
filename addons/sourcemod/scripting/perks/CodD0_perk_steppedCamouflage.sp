/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_visibilityByAttacking>

public Plugin myinfo =  {
	name = "CodD0 Perk: Stepped camouflage",
	author = "d0naciak",
	description =  "Stepped camouflage",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_perkID;
bool g_hasPerk[MAXPLAYERS + 1];

public void OnPluginStart() {
	g_perkID = CodD0_RegisterPerk("Kamuflaż stopniowany", "Na początku rundy masz ~6% widoczności, jednak z każdym strzałem Twoja widoczność rośnie");
}

public void OnPluginEnd() {
	CodD0_UnregisterPerk(g_perkID);
}

public Action CodD0_PerkChanged(int client, int perkID, int perkValue) {
	if(g_perkID != perkID && g_hasPerk[client]) {
		CodD0_SetClientVisibilityByAttacking(client, CodD0_SkillSlot_Perk, 255);
		g_hasPerk[client] = false;
	}
	
	return Plugin_Continue;
}

public void CodD0_PerkChanged_Post(int client, int perkID, int perkValue) {
	if(g_perkID == perkID && !g_hasPerk[client]) {
		CodD0_SetClientVisibilityByAttacking(client, CodD0_SkillSlot_Perk, 15);
		g_hasPerk[client] = true;
	}
}