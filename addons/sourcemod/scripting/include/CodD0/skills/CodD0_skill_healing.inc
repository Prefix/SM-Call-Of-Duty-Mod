#if defined _CodD0_skill_healing_included
 #endinput
#endif
#define _CodD0_skill_healing_included

native void CodD0_SetClientDuckHealing(int client, int CodD0_SkillSlot, int health, float intMultiplier, float time);
native int CodD0_GetClientDuckHealing(int client, int CodD0_SkillSlot);