#include <sourcemod>
#include <sdkhooks>
#include <CodD0_engine>
#include <CodD0/skills/CodD0_skill_visibility>

public Plugin myinfo =  {
	name = "COD d0 Skill: Visibility by attacking", 
	author = "d0naciak", 
	description = "Skill: Visibility by attacking", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_visibility[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actSkillID[MAXPLAYERS+1], g_respVisibility[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("player_spawn", ev_PlayerSpawn_Post);
	HookEvent("weapon_fire", ev_WeaponFire_Post);

	for (int i = 1; i <= MaxClients; i++) {
		for (int j = 0; j < CodD0_SkillSlot_Max; j++) {
			g_visibility[i][j] = 255;
		}

		g_respVisibility[i] = 255;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_visibilityByAttacking");

	CreateNative("CodD0_SetClientVisibilityByAttacking", nat_SetClientVisibilityByAttacking);
	CreateNative("CodD0_GetClientVisibilityByAttacking", nat_GetClientVisibilityByAttacking);
}

public int nat_SetClientVisibilityByAttacking(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2), visibility = GetNativeCell(3), actSkillID;

	g_visibility[client][skillID] = visibility;
	CodD0_SetClientVisibility(client, skillID, visibility);

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_visibility[client][i] < g_visibility[client][actSkillID]) {
			actSkillID = i;
		}
	}

	g_actSkillID[client] = actSkillID;
	g_respVisibility[client] = g_visibility[client][actSkillID];

	if(g_respVisibility[client] < 255) {
		CodD0_SetClientVisibility(client, actSkillID, g_respVisibility[client]);
	}
}

public int nat_GetClientVisibilityByAttacking(Handle plugin, int paramsNum) {
	return g_visibility[GetNativeCell(1)][GetNativeCell(2)];
}

public void ev_PlayerSpawn_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid")), skillID = g_actSkillID[client];

	if(client && g_visibility[client][skillID] < 255) {
		g_respVisibility[client] = g_visibility[client][skillID];
		CodD0_SetClientVisibility(client, skillID, g_respVisibility[client]);
	}
}

public void ev_WeaponFire_Post(Handle event, const char[] eventName, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && g_respVisibility[client] < 255) {
		g_respVisibility[client] += 16;
		
		if(g_respVisibility[client] > 255) {
			g_respVisibility[client] = 255;
		}

		CodD0_SetClientVisibility(client, g_actSkillID[client], g_respVisibility[client]);
	}
}