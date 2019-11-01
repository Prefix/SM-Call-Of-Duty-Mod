#if defined _CodD0_skill_noClip_included
 #endinput
#endif
#define _CodD0_skill_noClip_included

native void CodD0_SetClientNoClips(int client, int CodD0_SkillSlot, int num, float time);
native int CodD0_GetClientNoClips(int client, int CodD0_SkillSlot);

native int CodD0_UseNoClip(int client, int CodD0_SkillSlot);

forward void CodD0_EndOfNoClip(int client, int CodD0_SkillSlot, int CodD0_SkillPrep);