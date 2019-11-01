#if defined _CodD0_skill_unlimitedAmmo_included
 #endinput
#endif
#define _CodD0_skill_unlimitedAmmo_included

native void CodD0_SetClientUnlimitedAmmo(int client, int CodD0_SkillSlot, bool set);
native int CodD0_GetClientUnlimitedAmmo(int client, int CodD0_SkillSlot);
native int CodD0_GetClientActUnlimitedAmmo(int client);
