#if defined _CodD0_engine_consts_included
 #endinput
#endif
#define _CodD0_engine_consts_included
/*
enum CodD0_SkillSlot {
	CodD0_SkillSlot_Class = 0,
	CodD0_SkillSlot_Perk = 1,
	CodD0_SkillSlot_Max = 2
};
*/
#define CodD0_SkillSlot_Class 0
#define CodD0_SkillSlot_Perk 1
#define CodD0_SkillSlot_Max 2
/*
enum CodD0_SkillPreparedness {
	CodD0_SkillPrep_Available = 0,
	CodD0_SkillPrep_NAvailable = 1,
	CodD0_SkillPrep_Fail = 2
};
*/

#define CodD0_SkillPrep_Available 0
#define CodD0_SkillPrep_NAvailable 1
#define CodD0_SkillPrep_Fail 2

#define MAX_CLASSESNUM 64
#define MAX_PERKSNUM 128
#define MAX_CLASSNAME_LENGTH 64
#define MAX_PERKNAME_LENGTH 64
#define MAX_CLASSDESC_LENGTH 256
#define MAX_PERKDESC_LENGTH 256
#define MAX_CLASSWEAPONSNUM 32
#define MAX_BONUSWEAPONSNUM 32

#define TOASSIGN_PTS 0
#define INT_PTS 1
#define HEALTH_PTS 2
#define STAMINA_PTS 3
#define SPEED_PTS 4