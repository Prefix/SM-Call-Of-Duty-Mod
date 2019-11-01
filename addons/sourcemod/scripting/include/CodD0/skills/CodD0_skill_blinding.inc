#if defined _CodD0_skill_blinding_included
 #endinput
#endif
#define _CodD0_skill_blinding_included

native void CodD0_SetClientNoFlash(int client, int CodD0_SkillSlot, bool set);
native int CodD0_GetClientNoFlash(int client, int CodD0_SkillSlot);

native void CodD0_SetClientChanceToBlind(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToBlind(int client, int CodD0_SkillSlot);