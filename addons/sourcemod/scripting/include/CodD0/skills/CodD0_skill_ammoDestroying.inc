#if defined _CodD0_skill_ammoDestroying_included
 #endinput
#endif
#define _CodD0_skill_ammoDestroying_included

native void CodD0_SetClientChanceToDestroyClip(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToDestroyClip(int client, int CodD0_SkillSlot);

native void CodD0_SetClientClipDestroyers(int client, int CodD0_SkillSlot, int amount);
native int CodD0_GetClientClipDestroyers(int client, int CodD0_SkillSlot);
native int CodD0_UseClipDestroyer(int client, int CodD0_SkillSlot);
