#if defined _CodD0_skill_multiJump_included
 #endinput
#endif
#define _CodD0_skill_multiJump_included

native void CodD0_SetClientMultiJumps(int client, int CodD0_SkillSlot, int amount);
native int CodD0_GetClientMultiJumps(int client, int CodD0_SkillSlot);

native void CodD0_SetClientAutoBH(int client, int CodD0_SkillSlot, bool set);
native bool CodD0_GetClientAutoBH(int client, int CodD0_SkillSlot);
