#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

float g_clientBouncingShieldMultiplier[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientBouncingShieldTime[MAXPLAYERS + 1][CodD0_SkillSlot_Max];
int g_clientBouncingShieldsNum[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_clientBouncingShieldsNumInRound[MAXPLAYERS + 1][CodD0_SkillSlot_Max], g_lastUsedSkillID[MAXPLAYERS + 1];
Handle g_timerShield[MAXPLAYERS+1];

Handle g_hud;

public Plugin myinfo =  {
	name = "COD d0 Skill: Bouncing shield", 
	author = "d0naciak", 
	description = "Skill: Bouncing shield", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	g_hud = CreateHudSynchronizer();
	HookEvent("round_start", ev_RoundStart_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_bouncingShield");

	CreateNative("CodD0_SetClientBouncingShield", nat_SetClientBouncingShield);
	CreateNative("CodD0_GetClientBouncingShield", nat_GetClientBouncingShield);
	CreateNative("CodD0_UseBouncingShield", nat_UseBouncingShield);
}

public int nat_SetClientBouncingShield(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_clientBouncingShieldMultiplier[client][skillID] = view_as<float>(GetNativeCell(3));
	g_clientBouncingShieldsNum[client][skillID] = g_clientBouncingShieldsNumInRound[client][skillID] = GetNativeCell(4);
	g_clientBouncingShieldTime[client][skillID] = view_as<float>(GetNativeCell(5));

	if(g_timerShield[client] != null) {
		KillTimer(g_timerShield[client]);
		g_timerShield[client] = null;
		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);

		ClearSyncHud(client, g_hud);
	}
}

public int nat_GetClientBouncingShield(Handle plugin, int paramsNum) {
	return g_clientBouncingShieldsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseBouncingShield(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	if (g_timerShield[client] != null) {
		PrintCenterText(client, "Używasz aktualnie tarczy!");
		return CodD0_SkillPrep_Fail;
	}
	
	int skillID = g_lastUsedSkillID[client] = GetNativeCell(2)

	if (g_clientBouncingShieldsNumInRound[client][skillID] <= 0) {
		PrintCenterText(client, "Nie posiadasz już więcej tarcz!");
		return CodD0_SkillPrep_Fail;
	}

	SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
	SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
	
	DataPack dataPack;
	char loadingLevel[32];

	g_timerShield[client] = CreateDataTimer(g_clientBouncingShieldTime[client][skillID] / 20.0, timer_Shield, dataPack);
	dataPack.WriteCell(client);
	dataPack.WriteCell(0);

	for(int j = 0; j < 20; j++) {
		loadingLevel[j] = '-';
	}

	loadingLevel[20] = 0;

	SetHudTextParams(-1.0, 0.8, 2.0, 0, 204, 204, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hud, "[%s]", loadingLevel);

	return (--g_clientBouncingShieldsNumInRound[client][skillID] <= 0) ? CodD0_SkillPrep_NAvailable : CodD0_SkillPrep_Available;
}

public Action timer_Shield(Handle hTimer, DataPack dataPack) {
	int client, loadingLevel;

	dataPack.Reset();
	client = dataPack.ReadCell();
	loadingLevel = dataPack.ReadCell() + 1;

	if(!IsPlayerAlive(client)) {
		g_timerShield[client] = null;
		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);

		ClearSyncHud(client, g_hud);
		return Plugin_Stop;
	}

	int skillID = g_lastUsedSkillID[client];

	if(loadingLevel >= 20) {
		g_timerShield[client] = null;
		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);

		ClearSyncHud(client, g_hud);
		return Plugin_Stop;
	} else {
		DataPack dataPack2;
		char sLoadingLevel[32];

		g_timerShield[client] = CreateDataTimer(g_clientBouncingShieldTime[client][skillID] / 20.0, timer_Shield, dataPack2);
		dataPack2.WriteCell(client);
		dataPack2.WriteCell(loadingLevel);

		for(int i = 0; i < 20; i++) {
			if(i < loadingLevel) {
				sLoadingLevel[i] = '+';
			} else {
				sLoadingLevel[i] = '-';
			}
		}
		sLoadingLevel[20] = 0;

		SetHudTextParams(-1.0, 0.8, 2.0, 0, 204, 204, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hud, "[%s]", sLoadingLevel);
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
	if (g_timerShield[client] != null) {
		KillTimer(g_timerShield[client]);
		g_timerShield[client] = null;
			
		SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
		SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
	}
}

public void ev_Spawn_Post(int client) {
	KillTimer(g_timerShield[client]);
	g_timerShield[client] = null;
	ClearSyncHud(client, g_hud);
		
	SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
	SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);

}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (attacker <= 0 || attacker > MAXPLAYERS || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) == GetClientTeam(victim)) {
		return Plugin_Continue;
	}

	if (damageType & DMG_BULLET) {
		float degreedDamage = damage * g_clientBouncingShieldMultiplier[victim][g_lastUsedSkillID[victim]];

		if (g_timerShield[victim] != null) {
			SDKHooks_TakeDamage(attacker, victim, victim, degreedDamage, (1<<1), -1, NULL_VECTOR, NULL_VECTOR);
		}

		damage -= degreedDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_clientBouncingShieldsNumInRound[i][j] = g_clientBouncingShieldsNum[i][j];
		}
	}
}