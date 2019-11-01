#if defined _CodD0_skill_bonusesForDamage_included
 #endinput
#endif
#define _CodD0_skill_bonusesForDamage_included

native void CodD0_SetClientHealthForHeadShot(int client, int value);
native int CodD0_GetClientHealthForHeadShot(int client);

native void CodD0_SetClientHealthPerDmgMulti(int client, int CodD0_SkillSlot, float multi);
native float CodD0_GetClientHealthPerDmgMulti(int client, int CodD0_SkillSlot);