#include <sourcemod>
#include <CodD0_engine>

public Plugin myinfo = 
{
	name = "COD: Night Experience",
	author = "d0naciak",
	description = "Doubles experience at night",
	version = "1.0",
	url = "d0naciak.pl"
}

ConVar g_cvFromHour, g_cvToHour;
Handle g_hChangeTimer;

public void OnPluginStart() {
	g_cvFromHour = CreateConVar("cod_nightexp_from", "21", "From which hour give double experience");
	g_cvToHour = CreateConVar("cod_nightexp_to", "8", "To which hour give double experience");

	AutoExecConfig(true, "codmod_nightexp");
	CheckExp();
}


public void OnConfigsExecuted() {
	CheckExp();
}

void CheckExp() {
	static ConVar cvExp[8];
	
	if(!cvExp[0]) {
		cvExp[0] = FindConVar("cod_killxp"),
		cvExp[1] = FindConVar("cod_hsxp"),
		cvExp[2] = FindConVar("cod_assistxp"),
		cvExp[3] = FindConVar("cod_revengexp"),
		cvExp[4] = FindConVar("cod_plantbombxp"),
		cvExp[5] = FindConVar("cod_defusebombxp"),
		cvExp[6] = FindConVar("cod_rescuehostagexp"),
		cvExp[7] = FindConVar("cod_winroundxp");
	}

	char szTime[32];
	FormatTime(szTime, sizeof(szTime), "%H"); //check 
	int iHour = StringToInt(szTime), iFrom = GetConVarInt(g_cvFromHour), iTo = GetConVarInt(g_cvToHour);

	ServerCommand("exec sourcemod/codmod.cfg");

	if(iFrom > iTo) {
		if(iHour >= iFrom || iHour <= iTo) {
			for(int i = 0; i < 8; i++) {
				SetConVarInt(cvExp[i], GetConVarInt(cvExp[i]) * 2);
			}
		}
	} else {
		if(iFrom <= iHour <= iTo) {
			for(int i = 0; i < 8; i++) {
				SetConVarInt(cvExp[i], GetConVarInt(cvExp[i]) * 2);
			}
		}
	}

	FormatTime(szTime, sizeof(szTime), "%m");
	int iMinute = StringToInt(szTime);

	if(g_hChangeTimer != null) {
		KillTimer(g_hChangeTimer);
	}

	g_hChangeTimer = CreateTimer(float(60-iMinute) * 60.0, timer_Check);
}

public Action timer_Check(Handle hTimer) {
	CheckExp();
}
