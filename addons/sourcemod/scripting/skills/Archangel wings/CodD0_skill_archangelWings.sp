#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Archangel wings", 
	author = "d0naciak", 
	description = "Skill: Archangel wings", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_usedWings[MAXPLAYERS+1], g_power[MAXPLAYERS+1][CodD0_SkillSlot_Max];
float g_damage[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_damagePerInt[MAXPLAYERS+1][CodD0_SkillSlot_Max];
bool g_hooks[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_archangelWings");

	CreateNative("CodD0_SetClientArchangelWings", nat_SetClientArchangelWings);
	CreateNative("CodD0_GetClientArchangelWings", nat_GetClientArchangelWings);
	CreateNative("CodD0_UseArchangelWings", nat_UseArchangelWings);
}

public int nat_SetClientArchangelWings(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_power[client][skillID] = GetNativeCell(3);
	g_damage[client][skillID] = view_as<float>(GetNativeCell(4));
	g_damagePerInt[client][skillID] = view_as<float>(GetNativeCell(5));

	bool hasWings;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_power[client][i]) {
			hasWings = true;
			break;
		}
	}

	if (!g_hooks[client]) {
		if(hasWings) {
			SDKHook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
			SDKHook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooks[client] = true;
		}
	} else {
		if(!hasWings) {
			SDKUnhook(client, SDKHook_OnTakeDamage, ev_OnTakeDamage);
			SDKUnhook(client, SDKHook_SpawnPost, ev_Spawn_Post);
			g_hooks[client] = false;
		}
	}
}

public int nat_GetClientArchangelWings(Handle plugin, int paramsNum) {
	return g_power[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_UseArchangelWings(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	if (g_usedWings[client]) {
		return CodD0_SkillPrep_Fail;
	}

	if (GetEntityFlags(client) & FL_ONGROUND) {
		PrintCenterText(client, "Musisz być w powietrzu!");
		return CodD0_SkillPrep_Fail;
	}

	float velocity[3];
	velocity[2] -= 800.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	g_usedWings[client] = skillID + 1;

	return CodD0_SkillPrep_Available;
}

public Action ev_OnTakeDamage(int victim, int &attacker, int &ent, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePos[3], int damageCustom) {
	if (damageType & DMG_FALL && g_usedWings[victim]) {
		int skillID = g_usedWings[victim] - 1;
		float position[2][3];
		
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", position[0]);
		
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(victim) == GetClientTeam(i)) {
				continue;
			}
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", position[1]);
			
			if (GetVectorDistance(position[0], position[1]) <= 250.0 && GetEntityFlags(i) & FL_ONGROUND) {
				Shake(i, 10.0);
				CodD0_InflictDamage(victim, victim, i, g_damage[victim][skillID], g_damagePerInt[victim][skillID], DMG_CRUSH, -1);
			}
		}
		
		Shake(victim, 10.0);
		g_usedWings[victim] = 0;

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void ev_Spawn_Post(int client) {
	g_usedWings[client] = 0;
}

void Shake(int client, float Amp=1.0) {
	Handle message = StartMessageOne("Shake", client, 1);
	PbSetInt(message, "command", 0);
	PbSetFloat(message, "local_amplitude", Amp);
	PbSetFloat(message, "frequency", 100.0);
	PbSetFloat(message, "duration", 1.5);
	EndMessage();
}