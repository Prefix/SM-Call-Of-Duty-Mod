#if defined _CodD0_skill_rocket_included
 #endinput
#endif
#define _CodD0_skill_rocket_included

native void CodD0_SetClientRockets(int client, int CodD0_SkillSlot, int num, float damage, float damagePerInt);
native int CodD0_GetClientRockets(int client, int CodD0_SkillSlot);

native int CodD0_FireRocket(int client, int CodD0_SkillSlot);
