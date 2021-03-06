/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_damage>

public Plugin myinfo =  {
	name = "CodD0 Class: Deagler",
	author = "d0naciak",
	description =  "Deagler",
	version = "1.0",
	url = "d0naciak.pl"
}

int g_classID;
bool g_hasClass[MAXPLAYERS + 1];

public void OnPluginStart() {
	g_classID = CodD0_RegisterClass("Deagler", "+14 do obrażeń (+int) oraz 1/3 na zabicie z HeadShota z DEAGLE'a", {25, 0, 0, 60}, { CSWeapon_DEAGLE, CSWeapon_TAGGRENADE, CSWeapon_FLASHBANG, CSWeapon_FLASHBANG }, 4);
}

public void OnPluginEnd() {
	CodD0_UnregisterClass(g_classID);
}

public Action CodD0_ClassChanged(int client, int classID) {
	if(g_classID != classID && g_hasClass[client]) {
		CodD0_SetClientDmgBonus(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 0); 
		CodD0_SetClientIntDmgMultiplier(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 0.0); 
		CodD0_SetClientChanceToKillByHS(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 0); 
		g_hasClass[client] = false;
	}

	return Plugin_Continue;
}

public void CodD0_ClassChanged_Post(int client, int classID) {
	if(g_classID == classID) {
		CodD0_SetClientDmgBonus(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 14); 
		CodD0_SetClientIntDmgMultiplier(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 0.08); 
		CodD0_SetClientChanceToKillByHS(client, CodD0_SkillSlot_Class, CSWeapon_DEAGLE, 3); 
		g_hasClass[client] = true;
	}
}