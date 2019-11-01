#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_damage>

public Plugin myinfo =  {
	name = "COD d0 Skill: Loading damage", 
	author = "d0naciak", 
	description = "Skill: Loading damage", 
	version = "1.0", 
	url = "d0naciak.pl"
};

float g_loadingTime[MAXPLAYERS+1][CodD0_SkillSlot_Max];
int g_bonusDamage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeSkill[MAXPLAYERS+1];

int g_loadedSkillID[MAXPLAYERS+1];
Handle g_timerLoading[MAXPLAYERS+1];

Handle g_hud;

public void OnPluginStart() {
	HookEvent("round_prestart", ev_RoundPreStart_Post);
	g_hud = CreateHudSynchronizer();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_loadingDamage");

	CreateNative("CodD0_SetClientDamageLoader", nat_SetClientDamageLoader);
	CreateNative("CodD0_GetClientDamageLoader", nat_GetClientDamageLoader);
}

public int nat_SetClientDamageLoader(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), actSkillID;

	g_loadingTime[client][skillID] = view_as<float>(GetNativeCell(3));
	g_bonusDamage[client][skillID] = GetNativeCell(4);

	for(int i = 1; i < CodD0_SkillSlot_Max; i++) {
		if(g_bonusDamage[client][i] > g_bonusDamage[client][actSkillID]) {
			actSkillID = i;
		}
	}

	if(g_loadedSkillID[client]) {
		int loadedSkillID = g_loadedSkillID[client] - 1;
		CodD0_SetClientDmgBonus(client, loadedSkillID, CSWeapon_NONE, 0);
		g_loadedSkillID[client] = 0;
	}

	g_activeSkill[client] = actSkillID;

	if(g_timerLoading[client] != null) {
		KillTimer(g_timerLoading[client]);
		g_timerLoading[client] = null;
	}
}

public int nat_GetClientDamageLoader(Handle plugin, int paramsNum) {
	return g_bonusDamage[GetNativeCell(1)][GetNativeCell(2)];
}

public void ev_RoundPreStart_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		if(g_loadedSkillID[i]) {
			CodD0_SetClientDmgBonus(i, g_loadedSkillID[i] - 1, CSWeapon_NONE, 0);
			g_loadedSkillID[i] = 0;
		}

		if(g_timerLoading[i] != null) {
			KillTimer(g_timerLoading[i]);
			g_timerLoading[i] = null;
		}
	}
}

public void OnGameFrame() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || !g_bonusDamage[i][g_activeSkill[i]] || g_loadedSkillID[i]) {
			continue;
		}
		
		if(!(GetClientButtons(i) & (IN_MOVELEFT+IN_MOVERIGHT+IN_FORWARD+IN_BACK+IN_JUMP+IN_DUCK+IN_LEFT+IN_RIGHT)) && GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(i, CS_SLOT_KNIFE)) {
			float velocity[3];
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);

			if(g_timerLoading[i] == null && GetVectorLength(velocity) < 10.0) {
				int skillID = g_activeSkill[i];

				DataPack dataPack;
				char loadingLevel[32];

				g_timerLoading[i] = CreateDataTimer(g_loadingTime[i][skillID] / 20.0, timer_Loading, dataPack);
				dataPack.WriteCell(i);
				dataPack.WriteCell(0);

				for(int j = 0; j < 20; j++) {
					loadingLevel[j] = '-';
				}
				loadingLevel[20] = 0;

				SetHudTextParams(-1.0, 0.8, 2.0, 0, 204, 204, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, g_hud, "[%s]", loadingLevel);
			}
		} else if(g_timerLoading[i] != null) {
			ClearSyncHud(i, g_hud);
			KillTimer(g_timerLoading[i]);
			g_timerLoading[i] = null;
		}
	}
}

public Action timer_Loading(Handle timer, DataPack dataPack) {
	int client, loadingLevel;

	dataPack.Reset();
	client = dataPack.ReadCell();
	loadingLevel = dataPack.ReadCell() + 1;

	if(!IsPlayerAlive(client)) {
		g_timerLoading[client] = null;
		return Plugin_Stop;
	}

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	if(GetVectorLength(velocity) >= 10.0) {
		g_timerLoading[client] = null;
		return Plugin_Stop;
	}

	int skillID = g_activeSkill[client];

	if(loadingLevel >= 20) {
		CodD0_SetClientDmgBonus(client, skillID, CSWeapon_NONE, g_bonusDamage[client][skillID]);
		g_loadedSkillID[client] = skillID + 1;
		g_timerLoading[client] = null;

		ClearSyncHud(client, g_hud);
		PrintCenterText(client, "Umiejętność została załadowana!");
		return Plugin_Stop;
	} else {
		DataPack dataPack2;
		char sLoadingLevel[32];

		g_timerLoading[client] = CreateDataTimer(g_loadingTime[client][skillID] / 20.0, timer_Loading, dataPack2);
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