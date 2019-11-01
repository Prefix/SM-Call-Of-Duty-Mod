#if defined _CodD0_skill_replicas_included
 #endinput
#endif
#define _CodD0_skill_replicas_included

native void CodD0_SetClientReplicas(int client, int CodD0_SkillSlot, int num, float damage, float damagePerInt);
native int CodD0_GetClientReplicas(int client, int CodD0_SkillSlot);

native int CodD0_PlaceReplica(int client, int CodD0_SkillSlot);