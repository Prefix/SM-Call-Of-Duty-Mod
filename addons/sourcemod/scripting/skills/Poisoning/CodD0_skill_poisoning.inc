#if defined _CodD0_skill_poisoning_included
 #endinput
#endif
#define _CodD0_skill_poisoning_included

native void CodD0_SetClientChanceToPoison(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToPoison(int client, int CodD0_SkillSlot);

native void CodD0_SetClientPoisoningSmokes(int client, int CodD0_SkillSlot, bool set);
native bool CodD0_GetClientPoisoningSmokes(int client, int CodD0_SkillSlot);