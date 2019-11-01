#if defined _CodD0_skill_damage_included
 #endinput
#endif
#define _CodD0_skill_damage_included

#include <CodD0/skills/CodD0_skill_damage_consts>

native void CodD0_SetClientDmgMultiplier(int client, int CodD0_SkillSlot, CSWeaponID weaponID, float multiplier);
native float CodD0_GetClientDmgMultiplier(int client, int CodD0_SkillSlot, CSWeaponID weaponID);

native void CodD0_SetClientIntDmgMultiplier(int client, int CodD0_SkillSlot, CSWeaponID weaponID, float multiplier);
native float CodD0_GetClientIntDmgMultiplier(int client, int CodD0_SkillSlot, CSWeaponID weaponID);

native void CodD0_SetClientDmgBonus(int client, int CodD0_SkillSlot, CSWeaponID weaponID, int bonus);
native int CodD0_GetClientDmgBonus(int client, int CodD0_SkillSlot, CSWeaponID weaponID);

native void CodD0_SetClientHitBoxDmgBonus(int client, int CodD0_SkillSlot, int hitbox, int bonus);
native int CodD0_GetClientHitBoxDmgBonus(int client, int CodD0_SkillSlot, int hitbox);

native void CodD0_SetClientChanceToKill(int client, int CodD0_SkillSlot, CSWeaponID weaponID, int chance);
native int CodD0_GetClientChanceToKill(int client, int CodD0_SkillSlot, CSWeaponID weaponID);

native void CodD0_SetClientChanceToKillByHS(int client, int CodD0_SkillSlot, CSWeaponID weaponID, int chance);
native int CodD0_GetClientChanceToKillByHS(int client, int CodD0_SkillSlot, CSWeaponID weaponID);

native void CodD0_SetClientChanceToKillByKnife(int client, int CodD0_SkillSlot, int chance, bool onlyRMB);
native bool CodD0_GetClientOnlyRMB(int client, int CodD0_SkillSlot);

native void CodD0_SetClientChanceToTripleDamage(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToTripleDamage(int client, int CodD0_SkillSlot);

native void CodD0_SetClientRedDmgMultiplier(int client, int CodD0_SkillSlot, float multiplier);
native float CodD0_GetClientRedDmgMultiplier(int client, int CodD0_SkillSlot);

native void CodD0_SetClientExploRedDmgMultiplier(int client, int CodD0_SkillSlot, float multiplier);
native float CodD0_GetClientExploRedDmgMultiplier(int client, int CodD0_SkillSlot);

native void CodD0_SetClientHitBoxRedDmgMultiplier(int client, int CodD0_SkillSlot, int hitbox, float multiplier);
native float CodD0_GetClientHitBoxRedDmgMultiplier(int client, int CodD0_SkillSlot, int hitbox);

native void CodD0_SetClientChanceToDodgeBullet(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToDodgeBullet(int client, int CodD0_SkillSlot);

native void CodD0_SetClientChanceToBounceBullet(int client, int CodD0_SkillSlot, int chance);
native int CodD0_GetClientChanceToBounceBullet(int client, int CodD0_SkillSlot);

native void CodD0_SetClientBulletsToBounce(int client, int CodD0_SkillSlot, int num);
native int CodD0_GetClientBulletsToBounce(int client, int CodD0_SkillSlot);
