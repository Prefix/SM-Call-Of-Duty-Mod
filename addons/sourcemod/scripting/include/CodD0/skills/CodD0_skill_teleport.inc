#if defined _CodD0_skill_teleport_included
 #endinput
#endif
#define _CodD0_skill_teleport_included

native void CodD0_SetClientTeleports(int client, int CodD0_SkillSlot, int num, float range);
native int CodD0_GetClientTeleports(int client, int CodD0_SkillSlot);

native int CodD0_UseTeleport(int client, int CodD0_SkillSlot);