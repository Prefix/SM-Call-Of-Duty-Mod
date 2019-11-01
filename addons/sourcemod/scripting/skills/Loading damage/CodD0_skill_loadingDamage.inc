#if defined _CodD0_skill_loadingDamage_included
 #endinput
#endif
#define _CodD0_skill_loadingDamage_included

native void CodD0_SetClientDamageLoader(int client, int CodD0_SkillSlot, float time, int damage);
native int CodD0_GetClientDamageLoader(int client, int CodD0_SkillSlot);