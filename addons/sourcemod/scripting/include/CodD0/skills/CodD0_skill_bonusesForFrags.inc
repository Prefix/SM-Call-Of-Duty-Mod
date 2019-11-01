#if defined _CodD0_skill_bonusesForFrags_included
 #endinput
#endif
#define _CodD0_skill_bonusesForFrags_included

native void CodD0_SetClientHealthForFrag(int client, int value);
native int CodD0_GetClientHealthForFrag(int client);

native void CodD0_SetClientExpForFrag(int client, int value);
native int CodD0_GetClientExpForFrag(int client);

native void CodD0_SetClientCoinsForFrag(int client, int value);
native int CodD0_GetClientCoinsForFrag(int client);

native void CodD0_SetClientAmmoForFrag(int client, int value);
native int CodD0_GetClientAmmoForFrag(int client);