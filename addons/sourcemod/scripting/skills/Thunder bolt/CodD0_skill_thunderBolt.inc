#if defined _CodD0_skill_thunderBolt_included
 #endinput
#endif
#define _CodD0_skill_thunderBolt_included

native void CodD0_SetClientThunderBolt(int client, int CodD0_SkillSlot, int num, float damage, float damagePerInt);
native int CodD0_GetClientThunderBolt(int client, int CodD0_SkillSlot);

native int CodD0_UseThunderBolt(int client, int CodD0_SkillSlot);
