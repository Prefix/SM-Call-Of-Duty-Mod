#if defined _CodD0_skill_chanceToKillOppnntWithKnife_included
 #endinput
#endif
#define _CodD0_skill_chanceToKillOppnntWithKnife_included

#include <cstrike>

native void CodD0_SetClientChanceToKillOppnntWithKnife(int client, int CodD0_SkillSlot, CSWeaponID weaponID, int chance);
native int CodD0_GetClientChanceToKillOppnntWithKnife(int client, int CodD0_SkillSlot, CSWeaponID weaponID);
