#if defined _CodD0_skill_visibility_included
 #endinput
#endif
#define _CodD0_skill_visibility_included

native void CodD0_SetClientVisibility(int client, int CodD0_SkillSlot, int value);
native int CodD0_GetClientVisibility(int client, int CodD0_SkillSlot);

native void CodD0_SetClientVisibilityOnKnife(int client, int CodD0_SkillSlot, int value);
native int CodD0_GetClientVisibilityOnKnife(int client, int CodD0_SkillSlot);