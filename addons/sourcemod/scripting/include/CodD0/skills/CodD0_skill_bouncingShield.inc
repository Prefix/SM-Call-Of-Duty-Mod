#if defined _CodD0_skill_bouncingShield_included
 #endinput
#endif
#define _CodD0_skill_bouncingShield_included

native void CodD0_SetClientBouncingShield(int client, int CodD0_SkillSlot, float multiplier, int num, float time);
native int CodD0_GetClientBouncingShield(int client, int CodD0_SkillSlot);
native void CodD0_UseBouncingShield(int client, int CodD0_SkillSlot);