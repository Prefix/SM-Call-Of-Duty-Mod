#include <sourcemod>
#include <sdktools>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "COD: Rewrite code", 
	author = "d0naciak", 
	description = "", 
	version = "1.0", 
	url = "d0naciak.pl"
};

char g_chars[33] = "123456789abcdefghijklmnopqrstwyz";
//char g_chars[33] = {'1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','w','y','z', 0};
char g_code[64];

ConVar g_cvMinTime, g_cvMaxTime, g_cvMinChars, g_cvMaxChars, g_cvAnsweringTimeLimit, g_cvXpAward;
Handle g_timerEndOfAnswering;

public void OnPluginStart() {
	AddCommandListener(cmd_Say, "say"); 
	AddCommandListener(cmd_Say, "say2"); 
	AddCommandListener(cmd_Say, "say_team"); 

	g_cvMinTime = CreateConVar("cod_rewritecode_min_delay", "300.0", "Min. delay between next chance to rewrite code. Need to be greater than cod_rewritecode_answering_timelimit");
	g_cvMaxTime = CreateConVar("cod_rewritecode_max_delay", "600.0", "Max. delay between next chance to rewrite code");
	g_cvMinChars = CreateConVar("cod_rewritecode_min_chars", "6", "Min. chars of generated code");
	g_cvMaxChars = CreateConVar("cod_rewritecode_max_chars", "12", "Max. chars of generated code. Don't set this cvar greater than 64!");
	g_cvAnsweringTimeLimit = CreateConVar("cod_rewritecode_answering_timelimit", "10.0", "Time limit for answers");
	g_cvXpAward = CreateConVar("cod_rewritecode_xp_award", "250", "Experience award for the winner");

	AutoExecConfig(true, "codmod_rewritecode");

	CreateTimer(GetRandomFloat(GetConVarFloat(g_cvMinTime), GetConVarFloat(g_cvMaxTime)), timer_GenerateCode);
}

public void OnMapStart() {
	AddFileToDownloadsTable("sound/CodMod_d0naciak/rewrite_code/winner.mp3");
}

public Action timer_GenerateCode(Handle timer) {
	int codeLength = GetRandomInt(GetConVarInt(g_cvMinChars), GetConVarInt(g_cvMaxChars));

	strcopy(g_code, sizeof(g_code), "");
	for(int i = 0; i < codeLength; i++) {
		g_code[i] = g_chars[GetRandomInt(0, sizeof(g_chars) - 2)];
	}

	/*g_code[0] = 'a';
	g_code[1] = 'b';
	g_code[2] = 'c';*/
	//strcopy(g_code, sizeof(g_code), "1xc57u");
	g_code[codeLength] = 0;

	PrintToChatAll(" \x06\x04[KOD]\x01 Przepisz wygenerowany kod, a w nagrodę otrzymasz\x06 %d dośw.!", GetConVarInt(g_cvXpAward));
	PrintToChatAll(" \x06\x04[KOD]\x01 Kod do przepisania:\x0E %s", g_code);

	g_timerEndOfAnswering = CreateTimer(GetConVarFloat(g_cvAnsweringTimeLimit), timer_EndOfAnswering);
}

public Action cmd_Say(int client, const char[] command, args)  {
	if(g_timerEndOfAnswering == null) {
		return Plugin_Continue;
	}

	char code[96];
	GetCmdArgString(code, sizeof(code));
	StripQuotes(code);
	TrimString(code);

	//PrintToChatAll("%d said %s", client, code);

	if(StrEqual(code, g_code)) {
		char name[64];
		int award = GetConVarInt(g_cvXpAward);

		CodD0_SetClientExp(client, CodD0_GetClientExp(client) + award);
		GetClientName(client, name, sizeof(name));
		PrintToChatAll(" \x06\x04[KOD]\x01 Jako pierwszy kod przepisał...\x0E %s!", name);
		PrintToChatAll(" \x06\x04[KOD]\x01 Nagroda:\x0E %d dośw.!", award);
		ClientCommand(client, "play */CodMod_d0naciak/rewrite_code/winner.mp3");

		KillTimer(g_timerEndOfAnswering);
		g_timerEndOfAnswering = null;
		CreateTimer(GetRandomFloat(GetConVarFloat(g_cvMinTime), GetConVarFloat(g_cvMaxTime)), timer_GenerateCode);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action timer_EndOfAnswering(Handle timer) {
	g_timerEndOfAnswering = null;
	CreateTimer(GetRandomFloat(GetConVarFloat(g_cvMinTime), GetConVarFloat(g_cvMaxTime)), timer_GenerateCode);

	PrintToChatAll(" \x06\x04[KOD]\x01 Nikt nie przepisał kodu na czas :(");
}

