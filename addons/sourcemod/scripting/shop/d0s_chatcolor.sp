#include <sourcemod>
#include <sdktools>
#include <chat-processor>
#include <d0_shop>

public Plugin myinfo =  {
	name = "d0 Shop Item Type: Nick / msg color", 
	author = "d0naciak", 
	description = "Shop", 
	version = "1.0", 
	url = "d0naciak.pl"
};

int g_typeNickColorID;
int g_typeMsgColorID;

char g_playerNameColor[MAXPLAYERS+1][32];
char g_playerMsgColor[MAXPLAYERS+1][32];

public void OnPluginStart() {
	g_typeNickColorID = -1;
	g_typeMsgColorID = -1;
	
	if(d0s_AreItemsLoaded()) {
		g_typeNickColorID = d0s_RegisterType("nick_color", d0s_EQMode_Equip);
		g_typeMsgColorID = d0s_RegisterType("msg_color", d0s_EQMode_Equip);
	}
}

public void d0s_OnTypeLoad_Post(int typeID) {
	if(g_typeNickColorID == -1) {
		g_typeNickColorID = d0s_RegisterType("nick_color", d0s_EQMode_Equip);
		g_typeMsgColorID = d0s_RegisterType("msg_color", d0s_EQMode_Equip);
	}

	if(typeID != g_typeNickColorID) {
		g_typeNickColorID = d0s_GetTypeID("nick_color");
	}

	if(typeID != g_typeMsgColorID) {
		g_typeMsgColorID = d0s_GetTypeID("msg_color");
	}
}

public void OnPluginEnd() {
	if(g_typeNickColorID >= 0) {
		d0s_UnregisterType(g_typeNickColorID);
		d0s_UnregisterType(g_typeMsgColorID);
	}
}

public void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv) {
	if(typeID == g_typeNickColorID || typeID == g_typeMsgColorID) {
		char color[32];

		kv.GetString("color", color, sizeof(color));
		d0s_SetItemData(itemID, color);
	}
}

public void d0s_OnItemEquip_Post(int client, int itemID, int typeID) {
	if(typeID == g_typeNickColorID) {
		d0s_GetItemData(itemID, g_playerNameColor[client], sizeof(g_playerNameColor[]));
	} else if(typeID == g_typeMsgColorID) {
		d0s_GetItemData(itemID, g_playerMsgColor[client], sizeof(g_playerMsgColor[]));
	}
}

public void d0s_OnItemTakeoff_Post(int client, int itemID, int typeID) {
	if(typeID == g_typeNickColorID) {
		g_playerNameColor[client] = "teamcolor";
	} else if(typeID == g_typeMsgColorID) {
		g_playerMsgColor[client] = "default";
	}
}

public void OnClientConnected(int client) {
	g_playerNameColor[client] = "teamcolor";
	g_playerMsgColor[client] = "default";
}

public Action CP_OnChatMessage(int& sender, ArrayList recipients, char[] flag, char[] name, char[] msg, bool &proccessColors, bool &removeColors) {
	if(!StrEqual(g_playerNameColor[sender], "teamcolor") || !StrEqual(g_playerMsgColor[sender], "default")) {
		//PrintToChatAll("MSG: %s", g_playerMsgColor[sender]);
		Format(name, MAXLENGTH_NAME, "{%s}%s", g_playerNameColor[sender], name);
		Format(msg, MAXLENGTH_MESSAGE, "{%s}%s", g_playerMsgColor[sender], msg);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}