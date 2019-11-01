#if defined _CodD0_skill_exploding_included
 #endinput
#endif
#define _CodD0_skill_exploding_included

#include <CodD0/skills/CodD0_skill_exploding_consts>

native void CodD0_SetClientExplodes(int client, int CodD0_SkillSlot, int num, float damage, float damagePerInt, int mode);
native int CodD0_GetClientExplodes(int client, int CodD0_SkillSlot);

native int CodD0_UseExplode(int client, int CodD0_SkillSlot);
