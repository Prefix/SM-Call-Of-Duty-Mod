#include <sourcemod>
#include <sdktools>
#include <CodD0_DR_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Multi jump", 
	author = "d0naciak", 
	description = "Multi jump manager", 
	version = "1.0", 
	url = "d0naciak.pl"
};

#define WATER_LEVEL_FEET_IN_WATER 1
#define BOOST_FORWARD 50.0

int g_multiJumpsNum[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actMultiJumpsNum[MAXPLAYERS+1];
bool g_autoBH[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_actAutoBH[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_multiJump");

	CreateNative("CodD0_SetClientMultiJumps", nat_SetClientMultiJumps);
	CreateNative("CodD0_GetClientMultiJumps", nat_GetClientMultiJumps);

	CreateNative("CodD0_SetClientAutoBH", nat_SetClientAutoBH);
	CreateNative("CodD0_GetClientAutoBH", nat_GetClientAutoBH);

	return APLRes_Success;
}

public int nat_SetClientMultiJumps(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_multiJumpsNum[client][skillID] = GetNativeCell(3);
	g_actMultiJumpsNum[client] = 0;

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_multiJumpsNum[client][i] > g_actMultiJumpsNum[client]) {
			g_actMultiJumpsNum[client] = g_multiJumpsNum[client][i];
		}
	}
}

public int nat_GetClientMultiJumps(Handle plugin, int paramsNum) {
	return g_multiJumpsNum[GetNativeCell(1)][GetNativeCell(2)];
}

public int nat_SetClientAutoBH(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1), skillID = GetNativeCell(2);

	g_autoBH[client][skillID] = view_as<bool>(GetNativeCell(3));

	for (int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if (g_autoBH[client][i]) {
			g_actAutoBH[client] = true;
			return;
		}
	}

	g_actAutoBH[client] = false;
}

public int nat_GetClientAutoBH(Handle plugin, int paramsNum) {
	return view_as<int>(g_autoBH[GetNativeCell(1)][GetNativeCell(2)]);
}
/*
public void OnClientPutInServer(int client) {
	g_autoBH[client][CodD0_SkillSlot_VIP] = true;
	g_actAutoBH[client] = true;
}
*/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (GetEntProp(client, Prop_Send, "m_nWaterLevel") > WATER_LEVEL_FEET_IN_WATER || GetEntityMoveType(client) & MOVETYPE_LADDER) {
		return Plugin_Continue;
	}
	
	static lastButtons[MAXPLAYERS+1];
	static jumps[MAXPLAYERS+1];
	
	int flags = GetEntityFlags(client);
	
	float eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	
	if (flags & FL_ONGROUND) {
		jumps[client] = g_actMultiJumpsNum[client];
	} else if (jumps[client] && buttons & IN_JUMP && !(lastButtons[client] & IN_JUMP)) {
		jumps[client] --;
					
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		velocity[2] = 290.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}

	if(g_actAutoBH[client]) {
		if (buttons & IN_JUMP) {
			SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);

			if (flags & FL_ONGROUND) {
				if (BOOST_FORWARD != 0.0) {
					eyeAngles[0] = 0.0;
					
					if (buttons & IN_BACK) {
						eyeAngles[1] += 180.0;
					}
					
					if (buttons & IN_MOVELEFT) {
						eyeAngles[1] += 90.0;
					}
					
					if (buttons & IN_MOVERIGHT) {
						eyeAngles[1] += -90.0;
					}

					float forwardVector[3], velocity[3];
					
					GetAngleVectors(eyeAngles, forwardVector, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(forwardVector, forwardVector);
					ScaleVector(forwardVector, BOOST_FORWARD);
					
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
					
					for (int i=0;i<3;i++) {
						velocity[i] += forwardVector[i];
					}
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
				}
			} else {
				lastButtons[client] = buttons;
				buttons &= ~IN_JUMP;

				return Plugin_Changed;
			}
		}
	}

	lastButtons[client] = buttons;
	return Plugin_Continue;
}
/*
public void OnGameFrame() {
	static int jumps[MAXPLAYERS+1], lastButtons[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_actMultiJumpsNum[i]) {
			int flags = GetEntityFlags(i), buttons = GetClientButtons(i);
		
			if(flags & FL_ONGROUND) {
				jumps[i] = g_actMultiJumpsNum[i] + 1;
			} else if (!(lastButtons[i] & IN_JUMP) && (buttons & IN_JUMP) && jumps[i]) {
				jumps[i] --;
				
				float velocity[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity);
				velocity[2] = 250.0;
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
			}
			
			lastButtons[i] = buttons;
		}
	}
}*/