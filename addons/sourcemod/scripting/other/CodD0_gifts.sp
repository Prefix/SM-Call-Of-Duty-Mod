#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <CodD0_engine>

public Plugin myinfo =  {
	name = "Cod D0: Gifts",
	author = "d0naciak",
	description =  "You can pick up gifts from players",
	version = "1.0",
	url = "d0naciak.pl"
}

public void OnPluginStart() {
	HookEvent("player_death", ev_PlayerDeath_Post);
}

public void OnMapStart() {
	PrecacheModel("models/props_survival/cash/dufflebag.mdl");
	PrecacheSound("survival/money_collect_05.wav");
}

public void ev_PlayerDeath_Post(Handle event, const char[] name, bool dontBroadcast) {
	if(GameRules_GetProp("m_bWarmupPeriod") == 1) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || !IsClientInGame(client)) {
		return;
	}

	CreateGift(client);
}

void CreateGift(client) {
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	
	int entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "model", "models/props_survival/cash/dufflebag.mdl");
	DispatchKeyValue(entity, "physicsmode", "2");
	DispatchKeyValue(entity, "massScale", "2.0");
	DispatchKeyValue(entity, "targetname", "cod_gift");
	DispatchSpawn(entity);
	
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);

	SetVariantString("OnUser1 !self:kill::5.0:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
	SDKHook(entity, SDKHook_StartTouch, ev_StartTouch); 
}

public void ev_StartTouch(int entity, int client) {
	if(!(1 <= client <= MAXPLAYERS) || !IsPlayerAlive(client)) {
		return;
	}
	
	switch(GetRandomInt(1,5)) {
		case 1, 2: {
			int exp = GetRandomInt(1, 250);

			CodD0_SetClientExp(client, CodD0_GetClientExp(client) + exp);

			EmitSoundToClient(client, "survival/money_collect_05.wav", -2, 0, 0, 0, 0.5, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintToChat(client, " \x06\x04[Gifts]\x01 Wylosowałeś\x0E +%d dośw.!", exp);
		}

		case 3, 4: {
			int coins = GetRandomInt(1, 5);

			CodD0_SetClientCoins(client, CodD0_GetClientCoins(client) + coins);

			EmitSoundToClient(client, "survival/money_collect_05.wav", -2, 0, 0, 0, 0.5, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintToChat(client, " \x06\x04[Gifts]\x01 Wylosowałeś\x0E +%d$!", coins);
		}

		case 5, 6: {
			int health = GetRandomInt(1, 100), clientHealth = GetClientHealth(client) + health, maxHealth = 100 + RoundFloat(float(CodD0_GetAllClientStatsPoints(client, HEALTH_PTS)) * 0.25);

			if(clientHealth > maxHealth) {
				clientHealth = maxHealth;
			}

			SetEntityHealth(client, clientHealth);

			EmitSoundToClient(client, "survival/money_collect_05.wav", -2, 0, 0, 0, 0.5, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			PrintToChat(client, " \x06\x04[Gifts]\x01 Wylosowałeś\x0E +%dHP!", health);
		}
		
		case 7: {
			PrintToChat(client, " \x06\x04[Gifts]\x01 Wylosowałeś\x0E zupełne nic!");
		}
	}

	AcceptEntityInput(entity, "Kill");
}