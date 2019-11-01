#if defined _d0_shop_included
 #endinput
#endif
#define _d0_shop_included

#include <d0_shop_consts>

native int d0s_RegisterType(const char[] name, int eqMode);
native void d0s_UnregisterType(int typeID);

native void d0s_GetTypeKey(int typeID, char[] key, int keyLen);
native int d0s_GetTypeEQType(int typeID);
native int d0s_GetTypeID(const char[] key);

native void d0s_GetItemKey(int itemID, char[] key, int keyLen);
native void d0s_GetItemDesc(int itemID, char[] desc, int descLen);
native int d0s_GetItemTypeID(int itemID);
native int d0s_GetItemID(const char[] key);
native void d0s_GetItemData(int itemID, char[] data, int dataLen);
native void d0s_SetItemData(int itemID, const char[] data);

native bool d0s_IsItemEquipped(int client, int typeID);
native bool d0s_UseClientItem(int client, int itemID);
native bool d0s_EquipClientItem(int client, int itemID);
native bool d0s_TakeoffClientItem(int client, int itemID);

native bool d0s_AreItemsLoaded();
native int d0s_GetItemsNum();

forward void d0s_OnTypeLoad_Post(int typeID);
forward void d0s_OnItemCfgLoad_Post(int typeID, int catID, int itemID, KeyValues kv);
forward void d0s_OnAllItemsCfgLoad_Post();
forward void d0s_OnItemEquip_Post(int client, int itemID, int typeID);
forward void d0s_OnItemTakeoff_Post(int client, int itemID, int typeID);
forward Action d0s_OnItemUse(int client, int itemID, int typeID);
