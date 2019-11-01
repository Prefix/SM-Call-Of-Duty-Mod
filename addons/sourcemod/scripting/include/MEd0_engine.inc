#if defined _MEd0_engine_included
 #endinput
#endif
#define _MEd0_engine_included

native int MEd0_RegisterMission(const char[] name, const char[] desc, int reqProgress, const char[] award);

native bool MEd0_IsEngineReady();
native int MEd0_GetMissionID(const char[] name);

native int MEd0_GetClientMission(int client);
native int MEd0_GetClientMissionPrgrs(int client);

native void MEd0_GetMissionName(int missionID, char[] name, int len);
native void MEd0_GetMissionDesc(int missionID, char[] name, int len);
native int MEd0_GetMissionReqPrgrs(int missionID);
native void MEd0_GetMissionAward(int missionID, char[] name, int len);

native void MEd0_SetClientMission(int client, int missionID);
native void MEd0_SetClientMissionPrgrs(int client, int missionPrgrs, const bool force=false);

forward void MEd0_EngineGotReady();
forward void MEd0_OnMissionsReload();
forward void MEd0_OnMissionComplete(int client, int missionID);