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
// bot_globals.cpp
//
// Defines and initializes the global Variables

#include "bot_globals.h"

int g_iMapType; // Type of Map - Assault,Defuse etc...
bool g_bIsDedicatedServer = TRUE;
bool g_bWaypointOn = FALSE;
bool g_bWaypointsChanged = TRUE; // Waypoints changed
bool g_bWaypointsSaved = FALSE;
bool g_bAutoWaypoint = FALSE;
float g_fAutoPathMaxDistance = 250;
bool g_bShowWpFlags = TRUE;
int g_iDangerFactor = 2000;
bool g_bLearnJumpWaypoint = FALSE;
int g_iNumWaypoints; // number of waypoints currently in use for each team
int g_iCachedWaypoint = -1;
bool g_bLeaderChosenT = FALSE; // Leader for both Teams chosen
bool g_bLeaderChosenCT = FALSE; // Leader for both Teams chosen
int g_rgiTerrorWaypoints[MAX_WAYPOINTS];
int g_iNumTerrorPoints = 0;
int g_rgiCTWaypoints[MAX_WAYPOINTS];
int g_iNumCTPoints = 0;
int g_rgiGoalWaypoints[MAX_WAYPOINTS];
int g_iNumGoalPoints = 0;
int g_rgiCampWaypoints[MAX_WAYPOINTS];
int g_iNumCampPoints = 0;
float g_fWPDisplayTime; // waypoint display (while editing)
int *g_pFloydDistanceMatrix = NULL; // array of head pointers to the path structures (Distance Table)
bool g_bMapInitialised = FALSE;
bool g_bRecalcVis = TRUE;
float g_fTimeDisplayVisTableMsg = 1.0;
int g_iCurrVisIndex = 0;
unsigned char g_rgbyVisLUT[MAX_WAYPOINTS][MAX_WAYPOINTS / 4];
char g_cKillHistory;
int iNumBotNames = 0;
int iNumKillChats = 0;
int iNumBombChats = 0;
int iNumDeadChats = 0;
int iNumNoKwChats = 0;
int min_bots = 0;
int max_bots = 32;
float botcreation_time = 0.0;
int g_iMinBotSkill = 1; // When creating Bots with random Skill,
int g_iMaxBotSkill = 100; // skill Numbers are assigned between these 2 values
bool g_bBotChat = TRUE; // Flag for Botchatting
bool g_bJasonMode = FALSE; // Flag for Jasonmode (Knife only)
bool g_bDetailNames = TRUE; // Switches Skilldisplay on/off in Botnames
bool g_bInstantTurns = FALSE; // Toggles inhuman turning on/off
int g_iMaxNumFollow = 3; // Maximum Number of Bots to follow User
int g_iMaxWeaponPickup = 1; // Stores the maximum number of Weapons Bots are allowed to pickup
bool g_bShootThruWalls = TRUE; // Stores if Bots are allowed to pierce thru Walls
bool g_bIgnoreEnemies = FALSE; // Stores if Bots are told to ignore Enemies (debug feature)
float g_fLastChatTime = 0.0; // Stores Last Time chatted - prevents spamming
float g_fTimeRoundStart = 0.0; // stores the Start of the round (in worldtime)
float g_fTimeRoundEnd = 0.0; // Stores the End of the round (in worldtime) gpGlobals->time+roundtime
float g_fTimeRoundMid = 0.0; // Stores the halftime of the round (in worldtime)
float g_fTimeSoundUpdate = 1.0; // These Variables keep the Update Time Offset
float g_fTimePickupUpdate = 0.3;
float g_fTimeGrenadeUpdate = 0.5;
float g_fTimeNextBombUpdate = 0.0; // Holds the time to allow the next Search Update
int g_iLastBombPoint; // Stores the last checked Bomb Waypoint
bool g_bBombPlanted; // Stores if the Bomb was planted
bool g_bBombSayString;
float g_fTimeBombPlanted = 0.0; // Holds the time when Bomb was planted
int g_rgiBombSpotsVisited[MAXNUMBOMBSPOTS]; // Stores visited Bombspots for Counters when Bomb has been planted
bool g_bUseSpeech = TRUE;
bool g_bUseExperience = TRUE;
bool g_bBotSpray = TRUE; // Bot Spraying on/off
bool g_bBotsCanPause = FALSE; // Stores if Bots should pause
bool g_bHostageRescued = FALSE; // Stores if Counter rescued a Hostage in a Round
int iRadioSelect[32];
int g_rgfLastRadio[2];
float g_rgfLastRadioTime[2] = {0.0, 0.0}; // Stores Time of RadioMessage - prevents too fast responds
char g_szWaypointMessage[512]; // String displayed to Host telling about Waypoints
int g_iNumLogos = 5; // Number of available Spraypaints
int state; // network message state machine state
int g_iDebugGoalIndex = -1; // Assigns a goal in debug mode
int g_iSearchGoalIndex;
Vector g_vecBomb = g_vecZero;
edict_t *pHostEdict = NULL; // Ptr to Hosting Edict
bool g_bIsOldCS15 = TRUE;
DLL_FUNCTIONS gFunctionTable;
DLL_FUNCTIONS gFunctionTable_Post;
const Vector g_vecZero = Vector (0, 0, 0);
enginefuncs_t g_engfuncs;
globalvars_t  *gpGlobals;
char g_argv[1024];
char szBotNames[100][32]; // ptr to Botnames are stored here
char szKillChat[100][256]; // ptr to Kill Messages go here
char szBombChat[100][256]; // ptr to BombPlant Messages go here
char szDeadChat[100][256]; // ptr to Deadchats go here
char szNoKwChat[100][256];
const char *szUsedBotNames[32];// ptr to already used Names
const char *szUsedDeadChat[8]; // ptr to Keywords & Replies for interactive Chat
replynode_t *pChatReplies = NULL; // ptr to Strings when no keyword was found
createbot_t BotCreateTab[32];
client_t clients[32]; // Array of connected Clients
bool g_bEditNoclip = FALSE; // Flag for noclip wpt editing
int m_spriteTexture = 0; // Index of Beam Sprite
bool isFakeClientCommand = FALSE; // Faked Client Command
int fake_arg_count;
int num_bots = 0;
bool g_GameRules = FALSE;
int iStoreAddbotSkill;
int iStoreAddbotTeam;
menutext_t *pUserMenu = NULL;
char g_szWPTDirname[256] = "wptdefault"; // Default Folder to load wpts from
FILE *fp;
bool file_opened = FALSE;
float previous_time = -1.0;
bot_t bots[32];
int msecnum = 0; // TheFatal's method for calculating the msec value
float msecdel = 0;
float msecval = 0;
void (*botMsgFunction) (void *, int) = NULL;
int botMsgIndex;
PATH *paths[MAX_WAYPOINTS];
experience_t *pBotExperienceData = NULL;
int *g_pFloydPathMatrix = NULL;
int *g_pWithHostageDistMatrix = NULL;
int *g_pWithHostagePathMatrix = NULL;
bool g_bEndJumpPoint = FALSE;
float g_fTimeJumpStarted = 0.0;
Vector vecLearnVelocity = g_vecZero;
Vector vecLearnPos = g_vecZero;
int g_iLastJumpWaypoint = -1;
Vector g_vecLastWaypoint;
float g_fTimeRestartServer = 0.0;


// Weapons and their specifications
bot_weapon_select_t cs_weapon_select[NUM_WEAPONS + 1] =
{
   // Knife
   {CS_WEAPON_KNIFE,     "weapon_knife",     "models/w_knife.mdl",     "",       "",                                0.0,   50.0, 0.0,    0.0,  TRUE,  TRUE,   0.0,    0, 0, -1, -1, FALSE},
   // Pistols
   {CS_WEAPON_USP,       "weapon_usp",       "models/w_usp.mdl",       "usp",    "buy;menuselect 1;menuselect 1",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   2.8,  500, 1, -1, -1, FALSE},
   {CS_WEAPON_GLOCK18,   "weapon_glock18",   "models/w_glock18.mdl",   "glock",  "buy;menuselect 1;menuselect 2",   0.0, 2048.0, 0.0, 1200.0,  TRUE, FALSE,   2.3,  400, 1, -1, -1, FALSE},
   {CS_WEAPON_DEAGLE,    "weapon_deagle",    "models/w_deagle.mdl",    "deagle", "buy;menuselect 1;menuselect 3",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   2.3,  650, 1,  2,  2,  TRUE},
   {CS_WEAPON_P228,      "weapon_p228",      "models/w_p228.mdl",      "p228",   "buy;menuselect 1;menuselect 4",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   2.8,  600, 1,  2,  2, FALSE},
   {CS_WEAPON_ELITE,     "weapon_elite",     "models/w_elite.mdl",     "elites", "buy;menuselect 1;menuselect 5",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   4.6, 1000, 1,  0,  0, FALSE},
   {CS_WEAPON_FIVESEVEN, "weapon_fiveseven", "models/w_fiveseven.mdl", "fn57",   "buy;menuselect 1;menuselect 6",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,  3.17,  750, 1,  1,  1, FALSE},
   // Shotguns
   {CS_WEAPON_M3,        "weapon_m3",        "models/w_m3.mdl",        "m3",     "buy;menuselect 2;menuselect 1",   0.0, 2048.0, 0.0, 1200.0,  TRUE, FALSE,   1.1, 1700, 1,  2, -1, FALSE},
   {CS_WEAPON_XM1014,    "weapon_xm1014",    "models/w_xm1014.mdl",    "xm1014", "buy;menuselect 2;menuselect 2",   0.0, 2048.0, 0.0, 1200.0,  TRUE, FALSE,   0.9, 3000, 1,  2, -1, FALSE},
   // Sub Machine Guns
   {CS_WEAPON_MP5NAVY,   "weapon_mp5navy",   "models/w_mp5.mdl",       "mp5",    "buy;menuselect 3;menuselect 1",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,  2.74, 1500, 1,  2,  1, FALSE},
   {CS_WEAPON_TMP,       "weapon_tmp",       "models/w_tmp.mdl",       "tmp",    "buy;menuselect 3;menuselect 2",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,   2.2, 1250, 1,  1,  1, FALSE},
   {CS_WEAPON_P90,       "weapon_p90",       "models/w_p90.mdl",       "p90",    "buy;menuselect 3;menuselect 3",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,   3.5, 2350, 1,  2,  1, FALSE},
   {CS_WEAPON_MAC10,     "weapon_mac10",     "models/w_mac10.mdl",     "mac10",  "buy;menuselect 3;menuselect 4",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,   3.3, 1400, 1,  0,  0, FALSE},
   {CS_WEAPON_UMP45,     "weapon_ump45",     "models/w_ump45.mdl",     "ump45",  "buy;menuselect 3;menuselect 5",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,  4.15, 1700, 1,  2,  2, FALSE},
   // Rifles
   {CS_WEAPON_AK47,      "weapon_ak47",      "models/w_ak47.mdl",      "ak47",   "buy;menuselect 4;menuselect 1",   0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   2.6, 2500, 1,  0,  0,  TRUE},
   {CS_WEAPON_SG552,     "weapon_sg552",     "models/w_sg552.mdl",     "sg552",  "buy;menuselect 4;menuselect 2",   0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   4.0, 3500, 1,  0, -1,  TRUE},
   {CS_WEAPON_M4A1,      "weapon_m4a1",      "models/w_m4a1.mdl",      "m4a1",   "buy;menuselect 4;menuselect 3",   0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   3.2, 3100, 1,  1,  1,  TRUE},
   {CS_WEAPON_GALIL,     "weapon_galil",     "models/w_galil.mdl",     "galil",  "",                                0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   2.6, 2500, 1,  0,  0,  TRUE},
   {CS_WEAPON_FAMAS,     "weapon_famas",     "models/w_famas.mdl",     "famas",  "",                                0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   3.2, 3100, 1,  1,  1,  TRUE},
   {CS_WEAPON_AUG,       "weapon_aug",       "models/w_aug.mdl",       "aug",    "buy;menuselect 4;menuselect 4",   0.0, 4096.0, 0.0, 1200.0,  TRUE,  TRUE,   3.5, 3500, 1,  1,  1,  TRUE},
   // Sniper Rifles
   {CS_WEAPON_SCOUT,     "weapon_scout",     "models/w_scout.mdl",     "scout",  "buy;menuselect 4;menuselect 5", 300.0, 2048.0, 0.0, 1200.0,  TRUE, FALSE,   2.2, 2750, 1,  2,  0, FALSE},
   {CS_WEAPON_AWP,       "weapon_awp",       "models/w_awp.mdl",       "awp",    "buy;menuselect 4;menuselect 6",   0.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   2.6, 4750, 1,  2,  0,  TRUE},
   {CS_WEAPON_G3SG1,     "weapon_g3sg1",     "models/w_g3sg1.mdl",     "g3sg1",  "buy;menuselect 4;menuselect 7", 300.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE,   4.9, 5000, 1,  0,  2,  TRUE},
   {CS_WEAPON_SG550,     "weapon_sg550",     "models/w_sg550.mdl",     "sg550",  "buy;menuselect 4;menuselect 8", 300.0, 4096.0, 0.0, 1200.0,  TRUE, FALSE, 4.182, 4200, 1,  1,  1,  TRUE},
   // Machine Guns
   {CS_WEAPON_M249,      "weapon_m249",      "models/w_m249.mdl",      "m249",   "buy;menuselect 5;menuselect 1",   0.0, 2048.0, 0.0, 1200.0,  TRUE,  TRUE,  4.85, 5750, 1,  2,  1,  TRUE},
   // Shield
   {CS_WEAPON_SHIELDGUN, "weapon_shield",    "models/w_shield.mdl",    "shield", "",                                0.0,    0.0, 0.0,    0.0,  TRUE, FALSE,   0.0, 2200, 0,  1,  1, FALSE},
    //terminator
   {0,                   "",                 "",                       "",       "",                                0.0,    0.0, 0.0,    0.0, FALSE, FALSE,   0.0,    0, 0,  0,  0, FALSE}
};


// weapon firing delay based on skill (min and max delay for each weapon)
// THESE MUST MATCH THE SAME ORDER AS THE WEAPON SELECT ARRAY ABOVE!!!
// Last 2 values are Burstfire Bullet Count & Pause Times
bot_fire_delay_t cs_fire_delay[NUM_WEAPONS + 1] =
{
   // Knife
   {CS_WEAPON_KNIFE,      0.3, {0.0, 0.2, 0.3, 0.4, 0.6, 0.8}, {0.1, 0.3, 0.5, 0.7, 1.0, 1.2}, 0.0, {0.0, 0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 0.0, 0.0}, 255,                      1.0},
   // Pistols
   {CS_WEAPON_USP,        0.2, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 0.3},
   {CS_WEAPON_GLOCK18,    0.2, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 0.3},
   {CS_WEAPON_DEAGLE,     0.3, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_P228,       0.2, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 0.3},
   {CS_WEAPON_ELITE,     0.15, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_FIVESEVEN, 0.18, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 0.5},
   // Shotguns
   {CS_WEAPON_M3,        0.86, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 1.0},
   {CS_WEAPON_XM1014,    0.28, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 1.0},
   // Sub Machine Guns
   {CS_WEAPON_MP5NAVY,    0.1, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_TMP,        0.1, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_P90,       0.06, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_MAC10,     0.08, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_UMP45,      0.2, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 0.5},
   // Rifles
   {CS_WEAPON_AK47,      0.13, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_SG552,     0.12, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_M4A1,      0.13, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_GALIL,     0.13, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_FAMAS,     0.13, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   5, MIN_BURST_DISTANCE / 0.5},
   {CS_WEAPON_AUG,       0.12, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 0.5},
   // Sniper Rifles
   {CS_WEAPON_SCOUT,      1.3, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 1.0},
   {CS_WEAPON_AWP,        1.6, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   2, MIN_BURST_DISTANCE / 1.5},
   {CS_WEAPON_G3SG1,     0.27, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 1.0},
   {CS_WEAPON_SG550,     0.26, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   3, MIN_BURST_DISTANCE / 1.0},
   // Machine Guns
   {CS_WEAPON_M249,       0.1, {0.0, 0.1, 0.2, 0.3, 0.4, 0.6}, {0.1, 0.2, 0.3, 0.4, 0.5, 0.7}, 0.2, {0.0, 0.0, 0.1, 0.1, 0.2}, {0.1, 0.1, 0.2, 0.2, 0.4},   6, MIN_BURST_DISTANCE / 1.0},
   // Shield
   {CS_WEAPON_SHIELDGUN,  0.0, {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}, 0.0, {0.0, 0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 0.0, 0.0},   0, MIN_BURST_DISTANCE / 1.0},
   // terminator
   {0,                    0.0, {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}, 0.0, {0.0, 0.0, 0.0, 0.0, 0.0}, {0.0, 0.0, 0.0, 0.0, 0.0},   0, MIN_BURST_DISTANCE / 1.0}
};


// This Array stores the Aiming Offsets, Headshot Frequency and the ShootThruWalls
// Probability (worst to best skill). Overridden by botskill.cfg
botaim_t BotAimTab[6] =
{
   { 40,  40,  50,   0,   0,   0},
   { 30,  30,  42,  10,   0,   0},
   { 20,  20,  32,  30,   0,  50},
   { 10,  10,  18,  50,  30,  80},
   {  5,   5,  10,  80,  50, 100},
   {  0,   0,   0, 100, 100, 100}
};



bot_weapon_t weapon_defs[MAX_WEAPONS] =
{
   // szClassname          iAmmo1   iAmmo1Max   iAmmo2   iAmmo2Max   iSlot iPosition   iId   iFlags
   {"",                    0,       0,          0,       0,          0,    0,          0,    0},
   {"weapon_p228",         9,       52,         0,       0,          1,    3,          1,    0},
   {"",                    0,       0,          0,       0,          0,    0,          2,    0},
   {"weapon_scout",        2,       90,         0,       0,          0,    9,          3,    0},
   {"weapon_hegrenade",    12,      1,          0,       0,          3,    1,          4,    0},
   {"weapon_xm1014",       5,       32,         0,       0,          0,    12,         5,    0},
   {"weapon_c4",           14,      1,          0,       0,          4,    3,          6,    0},
   {"weapon_mac10",        6,       100,        0,       0,          0,    13,         7,    0},
   {"weapon_aug",          4,       90,         0,       0,          0,    14,         8,    0},
   {"weapon_smokegrenade", 13,      1,          0,       0,          3,    3,          9,    0},
   {"weapon_elite",        10,      120,        0,       0,          1,    5,          10,   0},
   {"weapon_fiveseven",    7,       100,        0,       0,          1,    6,          11,   0},
   {"weapon_ump45",        6,       100,        0,       0,          0,    15,         12,   0},
   {"weapon_sg550",        4,       90,         0,       0,          0,    16,         13,   0},
   {"weapon_galil",        4,       90,         0,       0,          0,    0,          14,   0},
   {"weapon_famas",        4,       90,         0,       0,          0,    0,          15,   0},
   {"weapon_usp",          6,       100,        0,       0,          1,    4,          16,   0},
   {"weapon_glock18",      10,      120,        0,       0,          1,    2,          17,   0},
   {"weapon_awp",          1,       30,         0,       0,          0,    2,          18,   0},
   {"weapon_mp5navy",      10,      120,        0,       0,          0,    7,          19,   0},
   {"weapon_m249",         3,       200,        0,       0,          0,    4,          20,   0},
   {"weapon_m3",           5,       32,         0,       0,          0,    5,          21,   0},
   {"weapon_m4a1",         4,       90,         0,       0,          0,    6,          22,   0},
   {"weapon_tmp",          10,      120,        0,       0,          0,    11,         23,   0},
   {"weapon_g3sg1",        2,       90,         0,       0,          0,    3,          24,   0},
   {"weapon_flashbang",    11,      2,          0,       0,          3,    2,          25,   0},
   {"weapon_deagle",       8,       35,         0,       0,          1,    1,          26,   0},
   {"weapon_sg552",        4,       90,         0,       0,          0,    10,         27,   0},
   {"weapon_ak47",         2,       90,         0,       0,          0,    1,          28,   0},
   {"weapon_knife",        -1,      -1,         0,       0,          2,    1,          29,   0},
   {"weapon_p90",          7,       100,        0,       0,          0,    8,          30,   0},
   {"",                    0,       0,          0,       0,          0,    0,          31,   0},
};


// These are skill based Delays for an Enemy Surprise Delay
// and the Pause/Camping Delays (weak Bots are longer surprised and
// do Pause/Camp longer as well)
skilldelay_t BotSkillDelays[6] =
{
   {0.8, 1.0, 9.0, 30.0, 60.0},
   {0.6, 0.8, 8.0, 25.0, 55.0},
   {0.4, 0.6, 7.0, 20.0, 50.0},
   {0.2, 0.3, 6.0, 15.0, 45.0},
   {0.1, 0.2, 5.0, 10.0, 35.0},
   {0.0, 0.1, 3.0, 10.0, 20.0}
};


// Table with all available Actions for the Bots
// (filtered in & out in BotSetConditions)
// Some of them have subactions included
bottask_t taskFilters[] =
{
   {NULL, NULL, TASK_NORMAL, 0.0, -1, TRUE, 0.0},
   {NULL, NULL, TASK_PAUSE, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_MOVETOPOSITION, 0.0, -1,TRUE, 0.0},
   {NULL, NULL, TASK_FOLLOWUSER, 0.0, -1, TRUE, 0.0},
   {NULL, NULL, TASK_WAITFORGO, 0.0, -1, TRUE, 0.0},
   {NULL, NULL, TASK_PICKUPITEM, 0.0, -1, TRUE, 0.0},
   {NULL, NULL, TASK_CAMP, 0.0, -1, TRUE, 0.0},
   {NULL, NULL, TASK_PLANTBOMB, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_DEFUSEBOMB, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_ATTACK, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_ENEMYHUNT, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_SEEKCOVER, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_THROWHEGRENADE, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_THROWFLASHBANG, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_THROWSMOKEGRENADE, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_SHOOTBREAKABLE, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_HIDE, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_BLINDED, 0.0, -1, FALSE, 0.0},
   {NULL, NULL, TASK_SPRAYLOGO, 0.0, -1, FALSE, 0.0}
};


// Default Tables for Personality Weapon Prefs overridden by botweapons.cfg
int NormalWeaponPrefs[NUM_WEAPONS] =
{
   0, 1, 2, 3, 4, 5, 6, 7, 8, 18, 10, 12, 13, 11, 9, 22, 19, 20, 21, 16, 15, 17, 14, 24, 23
};

int AgressiveWeaponPrefs[NUM_WEAPONS] =
{
   0, 1, 2, 3, 4, 5, 6, 18, 19, 20, 21, 10, 12, 13, 11, 9, 7, 8, 16, 15, 17, 14, 22, 24, 23
};

int DefensiveWeaponPrefs[NUM_WEAPONS] =
{
   0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 11, 9, 22, 14, 16, 15, 17, 18, 21, 20, 19, 24, 23
};

int *ptrWeaponPrefs[] =
{
   (int *) &NormalWeaponPrefs,
   (int *) &AgressiveWeaponPrefs,
   (int *) &DefensiveWeaponPrefs
};


// Default Spaynames - overridden by BotLogos.cfg
char szSprayNames[NUM_SPRAYPAINTS][20] =
{
   "{biohaz",
   "{graf004",
   "{graf005",
   "{lambda06",
   "{target",
   "{hand1"
};

// Sentences used with "speak" to welcome a User
const char szSpeechSentences[16][80] =
{
   "speak \"hello user, communication is acquired\"\n",
   "speak \"your presence is acknowledged\"\n",
   "speak \"high man, your in command now\"\n",
   "speak \"blast your hostile for good\"\n",
   "speak \"high man, kill some idiot here\"\n",
   "speak \"check check, test, mike check, talk device is activated\"\n",
   "speak \"good, day mister, your administration is now acknowledged\"\n",
   "speak \"high amigo, shoot some but\"\n",
   "speak \"hello pal, at your service\"\n",
   "speak \"time for some bad ass explosion\"\n",
   "speak \"high man, at your command\"\n",
   "speak \"bad ass son of a breach device activated\"\n",
   "speak \"high, do not question this great service\"\n",
   "speak \"engine is operative, hello and goodbye\"\n",
   "speak \"high amigo, your administration has been great last day\"\n",
   "speak \"all command access granted, over and out\"\n"
};


// Welcome Message
const char *szWelcomeMessage = "Welcome to POD-Bot V2.6mm by Count Floyd\n"
                               "Visit http://www.nuclearbox.com/podbot/ or\n"
                               "      http://forums.bots-united.com/ for Updates\n";


// Text and Key Flags for Menues - \y & \w are special CS Colour Tags
menutext_t menuPODBotMain =
{
   0x2ff,
   " Please choose:\n"
   "\n"
   "\n"
   " 1. Quick add Bot\n"
   " 2. Add specific Bot\n"
   " 3. Kill all Bots\n"
   " 4. New Round\n"
   " 5. Fill Server\n"
   " 6. Kick Bot\n"
   " 7. Kick all Bots\n"
   " 8. Weapon Mode\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuPODBotAddBotSkill =
{
   0x23f,
   " Please choose a Skill:\n"
   "\n"
   "\n"
   " 1. Stupid (0-20)\n"
   " 2. Newbie (20-40)\n"
   " 3. Average (40-60)\n"
   " 4. Advanced (60-80)\n"
   " 5. Professional (80-99)\n"
   " 6. Godlike (100)\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuPODBotAddBotTeam =
{
   0x213,
   " Please choose a Team:\n"
   "\n"
   "\n"
   " 1. Terrorist\n"
   " 2. Counter-Terrorist\n"
   "\n"
   " 5. Auto-Assign\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuPODBotAddBotTModel =
{
   0x21f,
   " Please choose a Terrorist Model:\n"
   "\n"
   "\n"
   " 1. Phoenix Connektion\n"
   " 2. L337 Krew\n"
   " 3. Arctic Avengers\n"
   " 4. Guerilla Warfare\n"
   "\n"
   " 5. Random"
};

menutext_t menuPODBotAddBotCTModel =
{
   0x21f,
   " Please choose a CT Model:\n"
   "\n"
   "\n"
   " 1. Seal Team 6\n"
   " 2. GSG-9\n"
   " 3. SAS\n"
   " 4. GIGN\n"
   "\n"
   " 5. Random"
};

menutext_t menuPODBotFillServer =
{
   0x213,
   " Please choose a Team:\n"
   "\n"
   "\n"
   " 1. Terrorist\n"
   " 2. Counter-Terrorist\n"
   "\n"
   " 5. Auto-Assign\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuPODBotWeaponMode =
{
   0x27f,
   " Weapon Mode:\n"
   "\n"
   "\n"
   " 1. Knife only (JasonMode!)\n"
   " 2. Pistols\n"
   " 3. Shotguns\n"
   " 4. Machine Guns\n"
   " 5. Rifles\n"
   " 6. Sniper Weapons\n"
   " 7. All Weapons (Standard)\n"
   "\n"
   " 0. Cancel"
};

// ------------------------
// ABS new WP menus
menutext_t menuWpMain =
{
   0x3ff,
   " Waypoint Menus\n"
   "\n"
   "\n"
   " 1. Add\n"
   " 2. Delete \n"
   " 3. Set Radius\n"
   " 4. Set Flags\n"
   " 5. Add Path\n"
   " 6. Delete Path\n"
   "\n"
   " 7. Check\n"
   " 8. Save\n"
   " 9. Options\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpAdd =
{
   0x3ff,
   " Add Waypoint\n"
   "\n"
   "\n"
   " 1. Normal\n"
   " 2. T Important\n"
   " 3. CT Important\n"
   " 4. Ladder\n"
   " 5. Rescue\n"
   " 6. Camp Start\n"
   " 7. Camp End\n"
   " 8. Goal\n"
   " 9. Jump\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpDelete =
{
   0x203,
   " Delete Waypoint\n"
   " Are you sure ?\n"
   "\n"
   "\n"
   " 1. Yes\n"
   " 2. No\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpSetRadius =
{
   0x3ff,
   " Set Waypoint Radius\n"
   "\n"
   "\n"
   " 1. Radius 0\n"
   " 2. Radius 8\n"
   " 3. Radius 16\n"
   " 4. Radius 32\n"
   " 5. Radius 48\n"
   " 6. Radius 64\n"
   " 7. Radius 80\n"
   " 8. Radius 96\n"
   " 9. Radius 112\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpSetFlags =
{
   0x3ff,
   " Set Waypoint Flags\n"
   "\n"
   "\n"
   " 1. Use Button\n"
   " 2. Lift\n"
   " 3. Crouch\n"
   " 4. Goal\n"
   " 5. Ladder\n"
   " 6. Rescue\n"
   " 7. Camp\n"
   " 8. No Hostage\n"
   " 9. TEAM Specific\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpSetTeam =
{
   0x207,
   " TEAM Specific Waypoint\n"
   " Which Team ?\n"
   "\n"
   "\n"
   " 1. Terrorists\n"
   " 2. Counter-terrorists\n"
   " 3. Both Teams\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpAddPath =
{
   0x207,
   " Add Path\n"
   " Which Direction ?\n"
   "\n"
   "\n"
   " 1. Outgoing Path\n"
   " 2. Incoming Path\n"
   " 3. Bidirectional (Both Ways)\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpDeletePath =
{
   0x203,
   " Delete Path\n"
   " Are you sure ?\n"
   "\n"
   "\n"
   " 1. Yes\n"
   " 2. No\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpSave =
{
   0x203,
   " Save Waypoints\n"
   " Errors found!\n"
   "\n"
   "\n"
   "1. Save anyway\n"
   "2. Go back and fix errors\n"
   "\n"
   "0. Cancel"
};

menutext_t menuWpOptions =
{
   0x27f,
   " Waypointing Options\n"
   "\n"
   "\n"
   " 1. WP on/off \n"
   " 2. AutoWP on/off\n"
   " 3. NoClip on/off\n"
   " 4. PeaceMode on/off\n"
   " 5. Show/Hide Flags\n"
   " 6. AutoPath Max Distance\n"
   " 7. Cache this Waypoint\n"
   "\n"
   " 0. Cancel"
};

menutext_t menuWpAutoPathMaxDistance =
{
   0x27f,
   " Auto-path Max Distance\n"
   "\n"
   "\n"
   " 1. Dist 0\n"
   " 2. Dist 100\n"
   " 3. Dist 130\n"
   " 4. Dist 160\n"
   " 5. Dist 190\n"
   " 6. Dist 220\n"
   " 7. Dist 250 (Default)\n"
   " 8. Dist 400\n"
   "\n"
   " 0. Cancel"
};
