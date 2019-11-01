#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_damage_consts>

#define MAX_WEAPONS (view_as<int>(CSWeapon_MAX_WEAPONS_NO_KNIFES))

//SKOPIUJ DO NATYWOW ORAZ PRZEPISZ DO ev_OnTakeDamage
float g_clientDmgMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max][MAX_WEAPONS + 1], g_clientActDmgMultiplier[MAXPLAYERS + 1][MAX_WEAPONS + 1];
float g_clientIntDmgMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max][MAX_WEAPONS + 1], g_clientActIntDmgMultiplier[MAXPLAYERS + 1][MAX_WEAPONS + 1];
int g_clientDmgBonus[MAXPLAYERS + 1][CodD0_SkillSlot_Max][MAX_WEAPONS + 1], g_clientActDmgBonus[MAXPLAYERS + 1][MAX_WEAPONS + 1];
int g_clientChanceToKill[MAXPLAYERS + 1][CodD0_SkillSlot_Max][MAX_WEAPONS + 1], g_clientActChanceToKill[MAXPLAYERS + 1][MAX_WEAPONS + 1];
int g_clientChanceToTripleDmg[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActChanceToTripleDmg[MAXPLAYERS + 1];
int g_clientChanceToKillByHS[MAXPLAYERS + 1][CodD0_SkillSlot_Max][MAX_WEAPONS + 1], g_clientActChanceToKillByHS[MAXPLAYERS + 1][MAX_WEAPONS + 1];
bool g_clientOnlyRMB[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActOnlyRMB[MAXPLAYERS + 1];
float g_clientRedDmgMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActRedDmgMultiplier[MAXPLAYERS + 1];
float g_clientExploRedDmgMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActExploRedDmgMultiplier[MAXPLAYERS + 1];
float g_clientHitBoxRedDmgMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max][8], g_clientActHitBoxRedDmgMultiplier[MAXPLAYERS + 1][8];
int g_clientHitBoxDmgBonus[MAXPLAYERS + 1][CodD0_SkillSlot_Max][8], g_clientActHitBoxDmgBonus[MAXPLAYERS + 1][8];
int g_clientChanceToDodgeBullet[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActChanceToDodgeBullet[MAXPLAYERS + 1];
int g_clientChanceToBounceBullet[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActChanceToBounceBullet[MAXPLAYERS + 1];
int g_clientBulletsToBounceNum[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientActBulletsToBounceNum[MAXPLAYERS + 1], g_clientActBulletsToBounceNumInRound[MAXPLAYERS + 1];

public Plugin myinfo =  {
	name = "COD d0 Skill: Damage", 
	author = "d0naciak", 
	description = "Skill: damage", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	HookEvent("round_start", ev_RoundStart_Post);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}

	OnMapStart();
}

public void OnMapStart() {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j <= MAX_WEAPONS; j++) {
			for(int k = 0; k < CodD0_SkillSlot_Max; k++) {
				g_clientDmgMultiplier[i][k][j] = 1.0;
				g_clientIntDmgMultiplier[i][k][j] = 0.0;
				g_clientDmgBonus[i][k][j] = 0;
				g_clientChanceToKill[i][k][j] = 0;
				g_clientChanceToKillByHS[i][k][j] = 0;
				
			}

			g_clientActDmgMultiplier[i][j] = 1.0;
			g_clientActIntDmgMultiplier[i][j] = 0.0;
			g_clientActDmgBonus[i][j] = 0;
			g_clientActChanceToKill[i][j] = 0;
			g_clientActChanceToKillByHS[i][j] = 0;
		}

		for(int j = 0; j < 8; j++) {
			for(int k = 0; k < CodD0_SkillSlot_Max; k++) {
				g_clientHitBoxRedDmgMultiplier[i][k][j] = 1.0;
				g_clientHitBoxDmgBonus[i][k][j] = 0;
			}

			g_clientActHitBoxRedDmgMultiplier[i][j] = 1.0;
			g_clientActHitBoxDmgBonus[i][j] = 0;
		}

		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_clientChanceToTripleDmg[i][j] = 0;
			g_clientOnlyRMB[i][j] = false;
			g_clientRedDmgMultiplier[i][j] = 1.0;
			g_clientExploRedDmgMultiplier[i][j] = 1.0;
			g_clientChanceToDodgeBullet[i][j] = 0;
			g_clientChanceToBounceBullet[i][j] = 0;
			g_clientBulletsToBounceNum[i][j] = 0;
		}


		g_clientActChanceToTripleDmg[i] = 0;
		g_clientActOnlyRMB[i] = false;
		g_clientActRedDmgMultiplier[i] = 1.0;
		g_clientActExploRedDmgMultiplier[i] = 1.0;
		g_clientActChanceToDodgeBullet[i] = 0;
		g_clientActChanceToBounceBullet[i] = 0;
		g_clientActBulletsToBounceNum[i] = 0;
		g_clientActBulletsToBounceNumInRound[i] = 0;
	}
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientDisconnect(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_damage");

	CreateNative("CodD0_SetClientDmgMultiplier", nat_SetClientDmgMultiplier);
	CreateNative("CodD0_GetClientDmgMultiplier", nat_GetClientDmgMultiplier);

	CreateNative("CodD0_SetClientIntDmgMultiplier", nat_SetClientIntDmgMultiplier);
	CreateNative("CodD0_GetClientIntDmgMultiplier", nat_GetClientIntDmgMultiplier);

	CreateNative("CodD0_SetClientDmgBonus", nat_SetClientDmgBonus);
	CreateNative("CodD0_GetClientDmgBonus", nat_GetClientDmgBonus);

	CreateNative("CodD0_SetClientHitBoxDmgBonus", nat_SetClientHitBoxDmgBonus);
	CreateNative("CodD0_GetClientHitBoxDmgBonus", nat_GetClientHitBoxDmgBonus);

	CreateNative("CodD0_SetClientChanceToKill", nat_SetClientChanceToKill);
	CreateNative("CodD0_GetClientChanceToKill", nat_GetClientChanceToKill);

	CreateNative("CodD0_SetClientChanceToKillByHS", nat_SetClientChanceToKillByHS);
	CreateNative("CodD0_GetClientChanceToKillByHS", nat_GetClientChanceToKillByHS);

	CreateNative("CodD0_SetClientChanceToKillByKnife", nat_SetClientChanceToKillByKnife);
	CreateNative("CodD0_GetClientOnlyRMB", nat_GetClientOnlyRMB);

	CreateNative("CodD0_SetClientChanceToTripleDamage", nat_SetClientChanceToTripleDamage);
	CreateNative("CodD0_GetClientChanceToTripleDamage", nat_GetClientChanceToTripleDamage);

	CreateNative("CodD0_SetClientRedDmgMultiplier", nat_SetClientRedDmgMultiplier);
	CreateNative("CodD0_GetClientRedDmgMultiplier", nat_GetClientRedDmgMultiplier);

	CreateNative("CodD0_SetClientExploRedDmgMultiplier", nat_SetClientExploRedDmgMultiplier);
	CreateNative("CodD0_GetClientExploRedDmgMultiplier", nat_GetClientExploRedDmgMultiplier);

	CreateNative("CodD0_SetClientHitBoxRedDmgMultiplier", nat_SetClientHitBoxRedDmgMultiplier);
	CreateNative("CodD0_GetClientHitBoxRedDmgMultiplier", nat_GetClientHitBoxRedDmgMultiplier);

	CreateNative("CodD0_SetClientChanceToDodgeBullet", nat_SetClientChanceToDodgeBullet);
	CreateNative("CodD0_GetClientChanceToDodgeBullet", nat_GetClientChanceToDodgeBullet);

	CreateNative("CodD0_SetClientChanceToBounceBullet", nat_SetClientChanceToBounceBullet);
	CreateNative("CodD0_GetClientChanceToBounceBullet", nat_GetClientChanceToBounceBullet);

	CreateNative("CodD0_SetClientBulletsToBounce", nat_SetClientBulletsToBounce);
	CreateNative("CodD0_GetClientBulletsToBounce", nat_GetClientBulletsToBounce);
}

public int nat_SetClientDmgMultiplier(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = view_as<int>(GetNativeCell(3));

	g_clientDmgMultiplier[client][GetNativeCell(2)][weaponID] = view_as<float>(GetNativeCell(4));
	g_clientActDmgMultiplier[client][weaponID] = 1.0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientDmgMultiplier[client][i][weaponID] > g_clientActDmgMultiplier[client][weaponID]) {
			g_clientActDmgMultiplier[client][weaponID] = g_clientDmgMultiplier[client][i][weaponID];
		}
	}
}

public int nat_GetClientDmgMultiplier(Handle plugin, int paramsNum) {
	return view_as<int>(g_clientDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)][view_as<int>(GetNativeCell(3))]);
}

public int nat_SetClientIntDmgMultiplier(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = view_as<int>(GetNativeCell(3));

	g_clientIntDmgMultiplier[client][GetNativeCell(2)][weaponID] = view_as<float>(GetNativeCell(4));
	g_clientActIntDmgMultiplier[client][weaponID] = 0.0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientIntDmgMultiplier[client][i][weaponID] > g_clientActIntDmgMultiplier[client][weaponID]) {
			g_clientActIntDmgMultiplier[client][weaponID] = g_clientIntDmgMultiplier[client][i][weaponID];
		}
	}
}

public int nat_GetClientIntDmgMultiplier(Handle plugin, int paramsNum) {
	return view_as<int>(g_clientIntDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)][view_as<int>(GetNativeCell(3))]);
}

public int nat_SetClientDmgBonus(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = view_as<int>(GetNativeCell(3));

	g_clientDmgBonus[client][GetNativeCell(2)][weaponID] = GetNativeCell(4);
	g_clientActDmgBonus[client][weaponID] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientDmgBonus[client][i][weaponID] > g_clientActDmgBonus[client][weaponID]) {
			g_clientActDmgBonus[client][weaponID] = g_clientDmgBonus[client][i][weaponID];
		}
	}
}

public int nat_GetClientDmgBonus(Handle plugin, int paramsNum) {
	return g_clientDmgBonus[GetNativeCell(1)][GetNativeCell(2)][view_as<int>(GetNativeCell(3))];
}

public int nat_SetClientHitBoxDmgBonus(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), hitbox = GetNativeCell(3);

	g_clientHitBoxDmgBonus[client][GetNativeCell(2)][hitbox] = GetNativeCell(4);
	g_clientActHitBoxDmgBonus[client][hitbox] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientHitBoxDmgBonus[client][i][hitbox] > g_clientActHitBoxDmgBonus[client][hitbox]) {
			g_clientActHitBoxDmgBonus[client][hitbox] = g_clientHitBoxDmgBonus[client][i][hitbox];
		}
	}
}

public int nat_GetClientHitBoxDmgBonus(Handle plugin, int paramsNum) {
	return g_clientHitBoxDmgBonus[GetNativeCell(1)][GetNativeCell(2)][GetNativeCell(3)];
}

public int nat_SetClientChanceToKill(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = view_as<int>(GetNativeCell(3));

	g_clientChanceToKill[client][GetNativeCell(2)][weaponID] = GetNativeCell(4);
	g_clientActChanceToKill[client][weaponID] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToKill[client][i][weaponID] && (!g_clientActChanceToKill[client][weaponID] || g_clientChanceToKill[client][i][weaponID] < g_clientActChanceToKill[client][weaponID])) {
			g_clientActChanceToKill[client][weaponID] = g_clientChanceToKill[client][i][weaponID];
		}
	}
}

public int nat_GetClientChanceToKill(Handle plugin, int paramsNum) {
	return g_clientChanceToKill[GetNativeCell(1)][GetNativeCell(2)][view_as<int>(GetNativeCell(3))];
}

public int nat_SetClientChanceToKillByHS(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), weaponID = view_as<int>(GetNativeCell(3));

	g_clientChanceToKillByHS[client][GetNativeCell(2)][weaponID] = GetNativeCell(4);
	g_clientActChanceToKillByHS[client][weaponID] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToKillByHS[client][i][weaponID] && (!g_clientActChanceToKillByHS[client][weaponID] || g_clientChanceToKillByHS[client][i][weaponID] < g_clientActChanceToKillByHS[client][weaponID])) {
			g_clientActChanceToKillByHS[client][weaponID] = g_clientChanceToKillByHS[client][i][weaponID];
		}
	}
}

public int nat_GetClientChanceToKillByHS(Handle plugin, int paramsNum) {
	return g_clientChanceToKillByHS[GetNativeCell(1)][GetNativeCell(2)][view_as<int>(GetNativeCell(3))];
}

public int nat_SetClientChanceToKillByKnife(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), weaponID = view_as<int>(CSWeapon_KNIFE);

	g_clientChanceToKill[client][skillID][weaponID] = GetNativeCell(3);
	g_clientOnlyRMB[client][skillID] = view_as<bool>(GetNativeCell(4));
	g_clientActChanceToKill[client][weaponID] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToKill[client][i][weaponID] && (!g_clientActChanceToKill[client][weaponID] || g_clientChanceToKill[client][i][weaponID] < g_clientActChanceToKill[client][weaponID])) {
			g_clientActChanceToKill[client][weaponID] = g_clientChanceToKill[client][i][weaponID];
			g_clientActOnlyRMB[client] = g_clientOnlyRMB[client][i];
		}
	}
}

public int nat_GetClientOnlyRMB(Handle plugin, int paramsNum) {
	return g_clientOnlyRMB[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientChanceToTripleDamage(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientChanceToTripleDmg[client][GetNativeCell(2)] = GetNativeCell(3);
	g_clientActChanceToTripleDmg[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToTripleDmg[client][i] && (!g_clientActChanceToTripleDmg[client] || g_clientChanceToTripleDmg[client][i] < g_clientActChanceToTripleDmg[client])) {
			g_clientActChanceToTripleDmg[client] = g_clientChanceToTripleDmg[client][i];
		}
	}
}

public int nat_GetClientChanceToTripleDamage(Handle plugin, int paramsNum) {
	return g_clientChanceToTripleDmg[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientRedDmgMultiplier(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientRedDmgMultiplier[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_clientActRedDmgMultiplier[client] = 1.0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientRedDmgMultiplier[client][i] < g_clientActRedDmgMultiplier[client]) {
			g_clientActRedDmgMultiplier[client] = g_clientRedDmgMultiplier[client][i];
		}
	}
}

public int nat_GetClientRedDmgMultiplier(Handle plugin, int paramsNum) {
	return view_as<int>(g_clientRedDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)]);
}

public int nat_SetClientExploRedDmgMultiplier(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientExploRedDmgMultiplier[client][GetNativeCell(2)] = view_as<float>(GetNativeCell(3));
	g_clientActExploRedDmgMultiplier[client] = 1.0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientExploRedDmgMultiplier[client][i] < g_clientActExploRedDmgMultiplier[client]) {
			g_clientActExploRedDmgMultiplier[client] = g_clientExploRedDmgMultiplier[client][i];
		}
	}
}

public int nat_GetClientExploRedDmgMultiplier(Handle plugin, int paramsNum) {
	return view_as<int>(g_clientExploRedDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)]);
}

public int nat_SetClientHitBoxRedDmgMultiplier(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), hitbox = GetNativeCell(3);

	g_clientHitBoxRedDmgMultiplier[client][GetNativeCell(2)][hitbox] = view_as<float>(GetNativeCell(4));
	g_clientActHitBoxRedDmgMultiplier[client][hitbox] = 1.0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientHitBoxRedDmgMultiplier[client][i][hitbox] < g_clientActHitBoxRedDmgMultiplier[client][hitbox]) {
			g_clientActHitBoxRedDmgMultiplier[client][hitbox] = g_clientHitBoxRedDmgMultiplier[client][i][hitbox];
		}
	}
}

public int nat_GetClientHitBoxRedDmgMultiplier(Handle plugin, int paramsNum) {
	return view_as<int>(g_clientHitBoxRedDmgMultiplier[GetNativeCell(1)][GetNativeCell(2)][GetNativeCell(3)]);
}

public int nat_SetClientChanceToDodgeBullet(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientChanceToDodgeBullet[client][GetNativeCell(2)] = GetNativeCell(3);
	g_clientActChanceToDodgeBullet[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToDodgeBullet[client][i] && (!g_clientActChanceToDodgeBullet[client] || g_clientChanceToDodgeBullet[client][i] < g_clientActChanceToDodgeBullet[client])) {
			g_clientActChanceToDodgeBullet[client] = g_clientChanceToDodgeBullet[client][i];
		}
	}
}

public int nat_GetClientChanceToDodgeBullet(Handle plugin, int paramsNum) {
	return g_clientChanceToDodgeBullet[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientChanceToBounceBullet(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientChanceToBounceBullet[client][GetNativeCell(2)] = GetNativeCell(3);
	g_clientActChanceToBounceBullet[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientChanceToBounceBullet[client][i] && (!g_clientActChanceToBounceBullet[client] || g_clientChanceToBounceBullet[client][i] < g_clientActChanceToBounceBullet[client])) {
			g_clientActChanceToBounceBullet[client] = g_clientChanceToBounceBullet[client][i];
		}
	}
}

public int nat_GetClientChanceToBounceBullet(Handle plugin, int paramsNum) {
	return g_clientChanceToBounceBullet[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientBulletsToBounce(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_clientBulletsToBounceNum[client][GetNativeCell(2)] = GetNativeCell(3);
	g_clientActBulletsToBounceNum[client] = 0;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_clientBulletsToBounceNum[client][i] > g_clientActBulletsToBounceNum[client]) {
			g_clientActBulletsToBounceNum[client] = g_clientBulletsToBounceNum[client][i];
		}
	}

	g_clientActBulletsToBounceNumInRound[client] = g_clientActBulletsToBounceNum[client];
}

public int nat_GetClientBulletsToBounce(Handle plugin, int paramsNum) {
	return g_clientBulletsToBounceNum[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_TraceAttack, ev_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_TraceAttack, ev_TraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		g_clientActBulletsToBounceNumInRound[i] = g_clientActBulletsToBounceNum[i];
	}
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim) || damageType & (1<<31) || !(damageType & (DMG_BULLET+DMG_SLASH+DMG_BLAST+DMG_BURN))) {
		return Plugin_Continue;
	}

	float newDamage = damage;

	int weaponID;
	CSWeaponID csWeaponID;

	if(weapon == -1) {
		if(ent > MAXPLAYERS) {
			char className[64];
			GetEntPropString(ent, Prop_Data, "m_iClassname", className, sizeof(className));

			if(StrEqual(className, "hegrenade_projectile")) {
				weaponID = view_as<int>(CSWeapon_HEGRENADE);
			} else if(StrEqual(className, "inferno")) {
				weaponID = view_as<int>(CSWeapon_MOLOTOV);
			}
		} 
	} else {
		weaponID = GetWeaponID(weapon);
	}

	csWeaponID = view_as<CSWeaponID>(weaponID);

	//PrintToChatAll("1. att %d, vic %d, old damage %.1f new damage: %.1f", attacker, victim, damage, newDamage);

	switch(csWeaponID) {
		case CSWeapon_HEGRENADE, CSWeapon_MOLOTOV: {
			if(g_clientActChanceToKill[attacker][weaponID] && !GetRandomInt(0,g_clientActChanceToKill[attacker][weaponID]-1)) {
				newDamage = float(GetClientHealth(victim) * 5);
			} else {
				newDamage *= g_clientActDmgMultiplier[attacker][weaponID];
				newDamage += (float(CodD0_GetClientUsableIntelligence(attacker)) * g_clientActIntDmgMultiplier[attacker][weaponID]);
				newDamage += float(g_clientActDmgBonus[attacker][weaponID]);

				if(csWeaponID == CSWeapon_HEGRENADE) {
					newDamage *= g_clientActExploRedDmgMultiplier[victim];
				}
			}

			//PrintToChatAll("HE. att %d, vic %d, old damage %.1f new damage: %.1f", attacker, victim, damage, newDamage);
		}

		case CSWeapon_KNIFE: {
			if(g_clientActChanceToKill[attacker][weaponID] && !GetRandomInt(0,g_clientActChanceToKill[attacker][weaponID]-1) && (!g_clientActOnlyRMB[attacker] || (GetClientButtons(attacker) & IN_ATTACK2))) {
				newDamage = float(GetClientHealth(victim) * 5);
			} else {
				newDamage *= g_clientActDmgMultiplier[attacker][weaponID];
				newDamage += (float(CodD0_GetClientUsableIntelligence(attacker)) * g_clientActIntDmgMultiplier[attacker][weaponID]);
				newDamage += float(g_clientActDmgBonus[attacker][weaponID]);
			}


			//PrintToChatAll("KNIFE. att %d, vic %d, old damage %.1f new damage: %.1f", attacker, victim, damage, newDamage);

		}

		default: {
			if(
				(
					(g_clientActChanceToKill[attacker][0] && !GetRandomInt(0,g_clientActChanceToKill[attacker][0]-1)) ||
					(g_clientActChanceToKill[attacker][weaponID] && !GetRandomInt(0,g_clientActChanceToKill[attacker][weaponID]-1))
				) || (
					(damageType & CS_DMG_HEADSHOT) && (
						(g_clientActChanceToKillByHS[attacker][0] && !GetRandomInt(0,g_clientActChanceToKillByHS[attacker][0]-1)) ||
						(g_clientActChanceToKillByHS[attacker][weaponID] && !GetRandomInt(0,g_clientActChanceToKillByHS[attacker][weaponID]-1))
					)
				)
			) {
				newDamage = float(GetClientHealth(victim) * 5);
			} else {
				if(g_clientActChanceToTripleDmg[attacker] && !GetRandomInt(0, g_clientActChanceToTripleDmg[attacker]-1)) {
					newDamage *= 3.0;
				}

				int intelligence = CodD0_GetClientUsableIntelligence(attacker);

				newDamage *= g_clientActDmgMultiplier[attacker][0] * g_clientActDmgMultiplier[attacker][weaponID];
				newDamage += (float(intelligence) * g_clientActIntDmgMultiplier[attacker][0]) + (float(intelligence) * g_clientActIntDmgMultiplier[attacker][weaponID]);
				newDamage += float(g_clientActDmgBonus[attacker][0] + g_clientActDmgBonus[attacker][weaponID]);
			}

			if(g_clientActChanceToDodgeBullet[victim] && GetRandomInt(1, g_clientActChanceToDodgeBullet[victim]) == 1) {
				return Plugin_Handled;
			}

			if((g_clientActBulletsToBounceNumInRound[victim]-- > 0) || (g_clientActChanceToBounceBullet[victim] && GetRandomInt(1, g_clientActChanceToBounceBullet[victim]) == 1)) {
				if (!g_clientActChanceToBounceBullet[attacker] && !g_clientActBulletsToBounceNumInRound[attacker]) {
					SDKHooks_TakeDamage(attacker, victim, victim, damage, (1<<1), -1, NULL_VECTOR, NULL_VECTOR);
				}

				return Plugin_Handled;
			}
			
			//PrintToChatAll("DEF. att %d, vic %d, old damage %.1f new damage: %.1f", attacker, victim, damage, newDamage);

		}
	}

	newDamage *= g_clientActRedDmgMultiplier[victim];

	//PrintToChatAll("2. att %d, vic %d, old damage %.1f new damage: %.1f", attacker, victim, damage, newDamage);

	if(newDamage != damage) {
		damage = newDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action ev_TraceAttack(int victim, int &attacker, int &ent, float &damage, int &damageType, int &ammoType, int hitbox, int hitgroup) {
	if(!attacker || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return Plugin_Continue;
	}
	

	if(damageType & DMG_BULLET && hitgroup > 0 && hitgroup < 8) {
		float newDamage = damage;

		if (g_clientActHitBoxDmgBonus[attacker][hitgroup]) {
			newDamage += float(g_clientActHitBoxDmgBonus[attacker][hitgroup]);
		}

		if (g_clientActHitBoxRedDmgMultiplier[victim][hitgroup] < 1.0) {
			newDamage *= g_clientActHitBoxRedDmgMultiplier[victim][hitgroup];
		}

		if(newDamage <= 0.0) {
			return Plugin_Handled;
		} else if(newDamage != damage) {
			damage = newDamage;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

int GetWeaponID(int weaponEnt) {
	CSWeaponID weaponId;

	weaponId = CS_ItemDefIndexToID(GetEntProp(weaponEnt, Prop_Send, "m_iItemDefinitionIndex"));

	if(_:weaponId < 0) {
		return 0;
	} else if(_:weaponId > MAX_WEAPONS || weaponId == CSWeapon_KNIFE_GG || weaponId == CSWeapon_KNIFE_T || weaponId == CSWeapon_KNIFE_GHOST) {
		return _:CSWeapon_KNIFE;
	}

	return _:weaponId;
}