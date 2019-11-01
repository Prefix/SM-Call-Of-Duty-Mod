#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD d0 Skill: Silent footsteps", 
	author = "d0naciak", 
	description = "Skill: Silent footsteps", 
	version = "1.0", 
	url = "d0naciak.pl"
};

bool g_silentFootsteps[MAXPLAYERS+1][CodD0_SkillSlot_Max], g_activeSilentFootsteps[MAXPLAYERS+1];

public void OnPluginStart() {
	AddNormalSoundHook(ev_NormalSoundHook);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int len) {
	RegPluginLibrary("CodD0_skill_silentFootsteps");

	CreateNative("CodD0_SetClientSilentFootsteps", nat_SetClientSilentFootsteps);
	CreateNative("CodD0_GetClientSilentFootsteps", nat_GetClientSilentFootsteps);
}

public int nat_SetClientSilentFootsteps(Handle plugin, int paramsNum) {
	int client = GetNativeCell(1);

	g_silentFootsteps[client][GetNativeCell(2)] = GetNativeCell(3);
	g_activeSilentFootsteps[client] = false;

	for(int i = 0; i < CodD0_SkillSlot_Max; i++) {
		if(g_silentFootsteps[client][i]) {
			g_activeSilentFootsteps[client] = true;
			break;
		}
	}
}

public int nat_GetClientSilentFootsteps(Handle plugin, int paramsNum) {
	return g_silentFootsteps[GetNativeCell(1)][GetNativeCell(2)];
}

public void OnClientPutInServer(int cId) {
	static Handle hConVarFootSteps;

	if(hConVarFootSteps == null) {
		hConVarFootSteps = FindConVar("sv_footsteps");
	}
	
	if(!IsFakeClient(cId)) {
		SendConVarValue(cId, hConVarFootSteps, "0");
	}
}

public Action ev_NormalSoundHook(int iClients[64], &iNumClients, char szSample[PLATFORM_MAX_PATH], int &iEnt, int &iChnl, float &fVol, int &iLvl, int &iPitch, int &iFlags) {
	if (iEnt && iEnt <= MAXPLAYERS && (StrContains(szSample, "physics") != -1 || StrContains(szSample, "footsteps") != -1))  {
		if(!g_activeSilentFootsteps[iEnt]) {
			iNumClients = 0;

			for(int i = 1; i <= MaxClients; i++) {
				if(IsClientInGame(i) && !IsFakeClient(i))  {
					iClients[iNumClients++] = i;
				}
			}

			return Plugin_Changed;
		}

		return Plugin_Stop;
	}

	return Plugin_Continue;
}