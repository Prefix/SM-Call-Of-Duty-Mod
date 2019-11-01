#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: No clip", 
	author = "d0naciak", 
	description = "Skill: No clip", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_noClipsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_noClipsNumInRound[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_time[MAXPLAYERS+1][CodD0_SkillSlot_Max];
Handle g_timerNoClip[MAXPLAYERS+1];
int g_lastUsedSkillID[MAXPLAYERS+1];

Handle g_hud;
Handle g_forward;

public void OnPluginStart() {
	HookEvent("player_spawn", ev_PlayerSpawn_Post);
	HookEvent("round_prestart", ev_RoundPreStart_Post);

	g_hud = CreateHudSynchronizer();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_noClip");

	CreateNative("CodD0_SetClientNoClips", nat_SetClientNoClips);
	CreateNative("CodD0_GetClientNoClips", nat_GetClientNoClips);
	CreateNative("CodD0_UseNoClip", nat_UseNoClip);

	g_forward = CreateGlobalForward("CodD0_EndOfNoClip", ET_Event, Param_Cell, Param_Cell, Param_Cell);
}

public int nat_SetClientNoClips(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_noClipsNum[client][skillID] = g_noClipsNumInRound[client][skillID] = GetNativeCell(3);
	g_time[client][skillID] = view_as<float>(GetNativeCell(4));
}

public int nat_GetClientNoClips(Handle plugin, int paramsNum) {
	return g_noClipsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseNoClip(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if(g_timerNoClip[client] != null) {
		KillTimer(g_timerNoClip[client]);
		g_timerNoClip[client] = null;

		EndOfNoClip(client, g_lastUsedSkillID[client]);
		return CodD0_SkillPrep_Fail;
	}

	if (g_noClipsNumInRound[client][skillID] <= 0) {
		PrintCenterText(client, "Wykorzystałeś wszystkie duszki!");
		return CodD0_SkillPrep_Fail;
	}

	DataPack dataPack;
	char loadingLevel[32];

	g_lastUsedSkillID[client] = skillID;
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.25);

	g_timerNoClip[client] = CreateDataTimer(g_time[client][skillID] / 20.0, timer_NoClipCountdown, dataPack);
	dataPack.WriteCell(client);
	dataPack.WriteCell(0);

	for(int j = 0; j < 20; j++) {
		loadingLevel[j] = '-';
	}
	loadingLevel[20] = 0;

	SetHudTextParams(-1.0, 0.8, 2.0, 0, 204, 204, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hud, "[%s]", loadingLevel);

	return --g_noClipsNumInRound[client][skillID] > 0 ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable
}


public Action timer_NoClipCountdown(Handle timer, DataPack dataPack) {
	int client, loadingLevel;

	dataPack.Reset();
	client = dataPack.ReadCell();
	loadingLevel = dataPack.ReadCell() + 1;

	if(!IsPlayerAlive(client)) {
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 + float(CodD0_GetAllClientStatsPoints(client, SPEED_PTS)) * 0.0005);

		g_timerNoClip[client] = null;
		return Plugin_Stop;
	}

	int skillID = g_lastUsedSkillID[client];

	if(loadingLevel >= 20) {
		g_timerNoClip[client] = null;
		EndOfNoClip(client, g_lastUsedSkillID[client]);

		return Plugin_Stop;
	} else {
		DataPack dataPack2;
		char sLoadingLevel[32];

		g_timerNoClip[client] = CreateDataTimer(g_time[client][skillID] / 20.0, timer_NoClipCountdown, dataPack2);
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

void EndOfNoClip(int client, int skillID) {
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 + float(CodD0_GetAllClientStatsPoints(client, SPEED_PTS)) * 0.0005);

	ClearSyncHud(client, g_hud);

	Call_StartForward(g_forward);
	Call_PushCell(client);
	Call_PushCell(skillID);
	Call_PushCell(g_noClipsNumInRound[client][skillID] > 0 ? CodD0_SkillPrep_Available : CodD0_SkillPrep_NAvailable);
	Call_Finish();
}

public void ev_PlayerSpawn_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client) {
		if(g_timerNoClip[client] != null) {
			KillTimer(g_timerNoClip[client]);
			g_timerNoClip[client] = null;

			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public void ev_RoundPreStart_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		for(int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_noClipsNumInRound[i][j] = g_noClipsNum[i][j];
		}
	}
}