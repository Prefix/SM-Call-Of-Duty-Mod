#if defined _CodD0_skill_blindingWave_included
 #endinput
#endif
#define _CodD0_skill_blindingWave_included

native void CodD0_SetClientBlindingWaves(int client, int CodD0_SkillSlot, int num, float range);
native int CodD0_GetClientBlindingWaves(int client, int CodD0_SkillSlot);

native int CodD0_UseBlindingWaves(int client, int CodD0_SkillSlot);
