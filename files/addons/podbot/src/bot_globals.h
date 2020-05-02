// ####################################
// #                                  #
// #       Ping of Death - Bot        #
// #                by                #
// #    Markus Klinge aka Count Floyd #
// #                                  #
// ####################################
//
// Started from the HPB-Bot Alpha Source
// by Botman so Credits for a lot of the basic
// HL Server/Client Stuff goes to him
//
// bot_globals.h
//
// Only File to include in the Code (does include all the rest)

#ifndef BOT_GLOBALS_H
#define BOT_GLOBALS_H

#ifndef _WIN32
#include <string.h>
#include <ctype.h>
#endif

#include <extdll.h>
#include <dllapi.h>
#include <h_export.h>
#include <meta_api.h>
#include <entity_state.h>

#include "bot.h"
#include "bot_weapons.h"
#include "waypoint.h"

#include <sys/types.h>
#include <sys/stat.h>


#define NUM_WEAPONS 26
#define MAX_WAYPOINTS 1024
#define MAXNUMBOMBSPOTS 16
#define NUM_SPRAYPAINTS 16


extern int g_iMapType;
extern bool g_bIsDedicatedServer;
extern bool g_bWaypointOn;
extern bool g_bWaypointsChanged;
extern bool g_bWaypointsSaved;
extern bool g_bAutoWaypoint;
extern float g_fAutoPathMaxDistance;
extern bool g_bShowWpFlags;
extern int g_iDangerFactor;
extern bool g_bLearnJumpWaypoint;
extern float g_fTimeNextBombUpdate;
extern int g_iNumWaypoints;
extern int g_iCachedWaypoint;
extern bool g_bLeaderChosenT;
extern bool g_bLeaderChosenCT;
extern char g_cKillHistory;
extern int g_rgiTerrorWaypoints[MAX_WAYPOINTS];
extern int g_iNumTerrorPoints;
extern int g_rgiCTWaypoints[MAX_WAYPOINTS];
extern int g_iNumCTPoints;
extern int g_rgiGoalWaypoints[MAX_WAYPOINTS];
extern int g_iNumGoalPoints;
extern int g_rgiCampWaypoints[MAX_WAYPOINTS];
extern int g_iNumCampPoints;
extern float g_fWPDisplayTime;
extern int *g_pFloydDistanceMatrix;
extern bool g_bMapInitialised;
extern bool g_bRecalcVis;
extern float g_fTimeDisplayVisTableMsg;
extern int g_iCurrVisIndex;
extern unsigned char g_rgbyVisLUT[MAX_WAYPOINTS][MAX_WAYPOINTS / 4];
extern int iNumBotNames;
extern int iNumKillChats;
extern int iNumBombChats;
extern int iNumDeadChats;
extern int iNumNoKwChats;
extern int min_bots;
extern int max_bots;
extern float botcreation_time;
extern int g_iMinBotSkill;
extern int g_iMaxBotSkill;
extern bool g_bBotChat;
extern bool g_bJasonMode;
extern bool g_bDetailNames;
extern bool g_bInstantTurns;
extern int g_iMaxNumFollow;
extern int g_iMaxWeaponPickup;
extern bool g_bShootThruWalls;
extern bool g_bIgnoreEnemies;
extern float g_fLastChatTime;
extern float g_fTimeRoundStart;
extern float g_fTimeRoundEnd;
extern float g_fTimeRoundMid;
extern float g_fTimeSoundUpdate;
extern float g_fTimePickupUpdate;
extern float g_fTimeGrenadeUpdate;
extern float g_fTimeNextBombUpdate;
extern int g_iLastBombPoint;
extern bool g_bBombPlanted;
extern float g_fTimeBombPlanted;
extern bool g_bBombSayString;
extern int g_rgiBombSpotsVisited[MAXNUMBOMBSPOTS];
extern bool g_bUseSpeech;
extern bool g_bUseExperience;
extern bool g_bBotSpray;
extern bool g_bBotsCanPause;
extern bool g_bHostageRescued;
extern int iRadioSelect[32];
extern int g_rgfLastRadio[2];
extern float g_rgfLastRadioTime[2];
extern char g_szWaypointMessage[512];
extern int g_iNumLogos;
extern int state;
extern int g_iDebugGoalIndex;
extern int g_iSearchGoalIndex;
extern Vector g_vecBomb;
extern edict_t *pHostEdict;
extern bool g_bIsOldCS15;
extern DLL_FUNCTIONS gFunctionTable;
extern DLL_FUNCTIONS gFunctionTable_Post;
extern enginefuncs_t g_engfuncs;
extern globalvars_t  *gpGlobals;
extern char g_argv[1024];
extern char szBotNames[100][32];
extern char szKillChat[100][256];
extern char szBombChat[100][256];
extern char szDeadChat[100][256];
extern char szNoKwChat[100][256];
extern const char *szUsedBotNames[32];
extern const char *szUsedDeadChat[8];
extern replynode_t *pChatReplies;
extern createbot_t BotCreateTab[32];
extern client_t clients[32];
extern bool g_bEditNoclip;
extern int m_spriteTexture;
extern bool isFakeClientCommand;
extern int fake_arg_count;
extern int num_bots;
extern bool g_GameRules;
extern int iStoreAddbotSkill;
extern int iStoreAddbotTeam;
extern menutext_t *pUserMenu;
extern char g_szWPTDirname[256];
extern FILE *fp;
extern bool file_opened;
extern float previous_time;
extern bot_t bots[32];
extern int msecnum;
extern float msecdel;
extern float msecval;
extern void (*botMsgFunction) (void *, int);
extern int botMsgIndex;
extern PATH *paths[MAX_WAYPOINTS];
extern experience_t *pBotExperienceData;
extern int *g_pFloydPathMatrix;
extern int *g_pWithHostageDistMatrix;
extern int *g_pWithHostagePathMatrix;
extern bool g_bEndJumpPoint;
extern float g_fTimeJumpStarted;
extern Vector vecLearnVelocity;
extern Vector vecLearnPos;
extern int g_iLastJumpWaypoint;
extern Vector g_vecLastWaypoint;
extern float g_fTimeRestartServer;

extern bot_weapon_select_t cs_weapon_select[NUM_WEAPONS + 1];
extern bot_fire_delay_t cs_fire_delay[NUM_WEAPONS + 1];
extern botaim_t BotAimTab[6];
extern bot_weapon_t weapon_defs[MAX_WEAPONS];
extern skilldelay_t BotSkillDelays[6];
extern bottask_t taskFilters[];
extern int NormalWeaponPrefs[NUM_WEAPONS];
extern int AgressiveWeaponPrefs[NUM_WEAPONS];
extern int DefensiveWeaponPrefs[NUM_WEAPONS];
extern int *ptrWeaponPrefs[];
extern char szSprayNames[NUM_SPRAYPAINTS][20];
extern const char szSpeechSentences[16][80];
extern const char *szWelcomeMessage;
extern menutext_t menuPODBotMain;
extern menutext_t menuPODBotAddBotSkill;
extern menutext_t menuPODBotAddBotTeam;
extern menutext_t menuPODBotAddBotTModel;
extern menutext_t menuPODBotAddBotCTModel;
extern menutext_t menuPODBotFillServer;
extern menutext_t menuPODBotWeaponMode;
extern menutext_t menuWpMain;
extern menutext_t menuWpAdd;
extern menutext_t menuWpDelete;
extern menutext_t menuWpSetRadius;
extern menutext_t menuWpSetFlags;
extern menutext_t menuWpSetTeam;
extern menutext_t menuWpAddPath;
extern menutext_t menuWpDeletePath;
extern menutext_t menuWpSave;
extern menutext_t menuWpOptions;
extern menutext_t menuWpAutoPathMaxDistance;


#endif