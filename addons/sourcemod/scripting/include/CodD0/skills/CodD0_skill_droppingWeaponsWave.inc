#if defined _CodD0_skill_droppingWeaponsWave_included
 #endinput
#endif
#define _CodD0_skill_droppingWeaponsWave_included

native void CodD0_SetClientDroppingWpnsWaves(int client, int CodD0_SkillSlot, int num, float range);
native int CodD0_GetClientDroppingWpnsWaves(int client, int CodD0_SkillSlot);

native int CodD0_UseDroppingWpnsWaves(int client, int CodD0_SkillSlot);