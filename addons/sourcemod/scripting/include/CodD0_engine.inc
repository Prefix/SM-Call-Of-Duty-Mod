#if defined _CodD0_engine_included
 #endinput
#endif
#define _CodD0_engine_included

#include <CodD0_engine_consts>
#include <cstrike>

native int CodD0_RegisterClass(const char[] name, const char[] desc, int statsPoints[4], const any[] weapons, int weaponsNum);
native void CodD0_UnregisterClass(int classID);

native int CodD0_RegisterPerk(const char[] name, const char[] desc, const int minValue = 0, const int maxValue = 0);
native void CodD0_UnregisterPerk(int perkID);

native int CodD0_GetClassesNum();
native int CodD0_GetPerksNum();
native int CodD0_GetClassID(const char[] name);
native int CodD0_GetPerkID(const char[] name);
native void CodD0_GetClassName(int classID, char[] className, int classNameLen);
native void CodD0_GetClassDesc(int classID, char[] classDesc, int classDescLen);
native void CodD0_GetClassWeapons(int classID, any[] weapons, int weaponsNum);
native int CodD0_GetClassStatsPoints(int classID, int statsPoints);
native void CodD0_GetPerkName(int perkID, char[] perkName, int perkNameLen);
native void CodD0_GetPerkDesc(int perkID, char[] perkDesc, int perkDescLen);
native int CodD0_GetPerkMaxValue(int perkID);
native int CodD0_GetPerkMinValue(int perkID);
native int CodD0_GetLevelExp(int level);

native int CodD0_GetClientExp(int client);
native int CodD0_GetClientLevel(int client);
native int CodD0_GetClientClass(int client);
native int CodD0_GetClientPerk(int client);
native int CodD0_GetClientPerkValue(int client);
native int CodD0_GetClientStatsPoints(int client, int statID);
native int CodD0_GetClientBonusStatsPoints(int client, int statID);
native int CodD0_GetClientCoins(int client);
native int CodD0_GetClientUsableIntelligence(int client);

native int CodD0_SetClientExp(int client, int exp);
native int CodD0_SetClientLevel(int client, int level);
native int CodD0_SetClientClass(int client, int classID);
native int CodD0_SetClientPerk(int client, int perkID=-1, int perkValue=-1, bool info=true);
native int CodD0_SetClientStatsPoints(int client, int statID, int amount);
native int CodD0_SetClientBonusStatsPoints(int client, int statID, int amount);
native int CodD0_SetClientCoins(int client, int amount);
native int CodD0_GiveClientWeapon(int client, CSWeaponID weaponID);
native int CodD0_TakeClientWeapon(int client, CSWeaponID weaponID);
native int CodD0_InflictDamage(int attacker, int entity, int victim, float damage, float intMultiplier, int dmgBits, int weaponEnt);
native int CodD0_MakeExplosion(int attacker, float position[3], float damage, float damagePerInt, int range);
native int CodD0_ClientClassSkillGotReady(int client, float cooldown);
native int CodD0_ClientPerkGotReady(int client, float cooldown);

forward Action CodD0_ClassChanged(int client, int classID);
forward void CodD0_ClassChanged_Post(int client, int classID);
forward Action CodD0_PerkChanged(int client, int perkID, int perkValue);
forward void CodD0_PerkChanged_Post(int client, int perkID, int perkValue);
forward void CodD0_ClassSkillUsed(int client, int classID);
forward void CodD0_PerkUsed(int client, int perkID);

stock int CodD0_GetAllClientStatsPoints(int client, int statID) {
	return CodD0_GetClientStatsPoints(client, statID) + CodD0_GetClientBonusStatsPoints(client, statID) + CodD0_GetClassStatsPoints(CodD0_GetClientClass(client), statID)
}