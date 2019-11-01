#if defined _CodD0_skill_longJump_included
 #endinput
#endif
#define _CodD0_skill_longJump_included

native void CodD0_SetClientLongJumps(int client, int CodD0_SkillSlot, int amount, int power, float intMultiplier);
native int CodD0_GetClientLongJumps(int client, int CodD0_SkillSlot);

native int CodD0_UseClientLongJump(int client, int CodD0_SkillSlot);
