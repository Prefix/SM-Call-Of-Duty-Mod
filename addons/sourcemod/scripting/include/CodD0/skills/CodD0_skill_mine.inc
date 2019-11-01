#if defined _CodD0_skill_mine_included
 #endinput
#endif
#define _CodD0_skill_mine_included

native void CodD0_SetClientMines(int client, int CodD0_SkillSlot, int num, float damage, float damagePerInt);
native int CodD0_GetClientMines(int client, int CodD0_SkillSlot);

native int CodD0_PlantMine(int client, int CodD0_SkillSlot);