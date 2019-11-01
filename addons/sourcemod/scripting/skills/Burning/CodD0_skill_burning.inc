#if defined _CodD0_skill_burning_included
 #endinput
#endif
#define _CodD0_skill_burning_included

native void CodD0_SetClientChanceToBurn(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToBurn(int client, int CodD0_SkillSlot);