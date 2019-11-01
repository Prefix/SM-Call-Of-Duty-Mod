#if defined _CodD0_skill_multiWeapons_included
 #endinput
#endif
#define _CodD0_skill_multiWeapons_included

#include <cstrike>

native void CodD0_SetClientMultiWeapon(int client, int slot, int whichWeapon, CSWeaponID weaponID);
native CSWeaponID CodD0_GetClientMultiWeapon(int client, int slot, int whichWeapon);

native bool CodD0_ChangeClientWeapon(int client, int slot);
