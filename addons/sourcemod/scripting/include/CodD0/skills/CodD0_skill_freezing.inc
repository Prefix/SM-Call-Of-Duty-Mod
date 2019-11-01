#if defined _CodD0_skill_freezing_included
 #endinput
#endif
#define _CodD0_skill_freezing_included

native void CodD0_SetClientChanceToFreeze(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToFreeze(int client, int CodD0_SkillSlot);
