#include <sourcemod>
#include <sdktools>
#include <d0_shop>

int g_itemID;
int g_maxUsages;

int g_plrLongJumps[MAXPLAYERS+1], g_plrLongJumpsPerRound[MAXPLAYERS+1];

public Plugin myinfo =  {
	name = "d0 Shop Item: Long Jump", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

public void OnPluginStart() {
	if(d0s_AreItemsLoaded()) {
		g_itemID = d0s_GetItemID("longjump");
	}

	HookEvent("round_start", ev_RoundStart_Post);
}

public void d0s_OnAllItemsCfgLoad_Post() {
	char data[128], explodedData[3][32];

	g_itemID = d0s_GetItemID("longjump");
	d0s_GetItemData(g_itemID, data, sizeof(data));
	ExplodeString(data, "|", explodedData, sizeof(explodedData), sizeof(explodedData[]));

	g_maxUsages = StringToInt(explodedData[0]);
}

public void OnClientPutInServer(int client) {
	g_plrLongJumps[client] = g_plrLongJumpsPerRound[client] = 0;
}

public ev_RoundStart_Post(Handle event, const char[] name, bool dontBroadcast) {
	for(int i = 1; i <= MaxClients; i++) {
		g_plrLongJumps[i] = g_plrLongJumpsPerRound[i] = 0;
	}
}

public Action d0s_OnItemUse(int client, int itemID, int typeID) {
	if(itemID != g_itemID) {
		return Plugin_Continue;
	}

	if(g_plrLongJumpsPerRound[client] >= g_maxUsages && g_maxUsages) {
		PrintCenterText(client, "Możesz użyć maks. %d LJ / rundę", g_maxUsages);
		return Plugin_Handled;
	}

	g_plrLongJumpsPerRound[client] ++;
	PrintCenterText(client, "Użycie LJ: Kucnij + SPACJA\nPosiadasz: %d LJ", ++g_plrLongJumps[client]);
	return Plugin_Continue;
}

public void OnGameFrame() {
	static int lastButtons[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_plrLongJumps[i]) {
			int buttons = GetClientButtons(i);
		
			if((buttons & IN_JUMP) && !(lastButtons[i] & IN_JUMP) && buttons & IN_DUCK) {
				float velocity[3];

				GetAimVelocity(i, 1000.0, velocity);
				velocity[2] = GetRandomFloat(265.0, 285.0);
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);

				g_plrLongJumps[i] --;
			}
			
			lastButtons[i] = buttons;
		}
	}
}



stock GetAimVelocity(client, Float:fSpeed, Float:InitialVec[3])
{
	new Float:OwnerAng[3];
	GetClientEyeAngles(client, OwnerAng);
	
	new Float:OwnerPos[3];
	GetClientEyePosition(client, OwnerPos);
	//TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, client);
	new Handle:hTrace = TR_TraceRayFilterEx(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if(!TR_DidHit(hTrace)) 
		return 0;
	
	new Float:InitialPos[3];
	TR_GetEndPosition(InitialPos, hTrace);
	
	//new Float:InitialPos[3];
	//TR_GetEndPosition(InitialPos);
	
	//new Float:InitialVec[3];
	MakeVectorFromPoints(OwnerPos, InitialPos, InitialVec);
	
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, fSpeed);
	
	return 1;
}


public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > MaxClients;
} 