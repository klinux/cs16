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
// bot.h
//
// Contains the Bot Structures and Function Prototypes

#ifndef BOT_H
#define BOT_H


#include <assert.h>


typedef struct bottask_s
{
   bottask_s *pPreviousTask;
   bottask_s *pNextTask;
   int iTask; // Major Task/Action carried out
   float fDesire; // Desire (filled in) for this Task
   int iData; // Additional Data (Waypoint Index)
   float fTime; // Time Task expires
   bool bCanContinue; // If Task can be continued if interrupted
} bottask_t;


// Task Filter functions

inline struct bottask_s *clampdesire (bottask_t *t1, float fMin, float fMax)
{
   if (t1->fDesire < fMin)
      t1->fDesire = fMin;
   else if (t1->fDesire > fMax)
      t1->fDesire = fMax;

   return (t1);
}

inline struct bottask_s *maxdesire (bottask_t *t1,bottask_t *t2)
{
   if (t1->fDesire > t2->fDesire)
      return (t1);

   return (t2);
}

inline bottask_s *subsumedesire (bottask_t *t1,bottask_t *t2)
{
   if (t1->fDesire > 0)
      return (t1);

   return (t2);
}

inline bottask_s *thresholddesire (bottask_t *t1, float t, float d)
{
   if (t1->fDesire >= t)
      return (t1);
   else
   {
      t1->fDesire = d;
      return (t1);
   }
}

inline float hysteresisdesire (float x, float min, float max, float oldval)
{
   if ((x <= min) || (x >= max))
      oldval = x;

   return (oldval);
}


// Some more function prototypes
void FakeClientCommand (edict_t *pFakeClient, const char *fmt, ...);
const char *GetField (const char *string, int field_number);


// define Console/CFG Commands
#define CONSOLE_CMD_ADDBOT "addbot\0"
#define CONSOLE_CMD_KILLALLBOTS "killbots\0"
#define CONSOLE_CMD_WAYPOINT "waypoint\0"
#define CONSOLE_CMD_WP "wp\0"
#define CONSOLE_CMD_DEBUGGOAL "debuggoal\0"
#define CONSOLE_CMD_REMOVEALLBOTS "removebots\0"
#define CONSOLE_CMD_MINBOTS "min_bots\0"
#define CONSOLE_CMD_MAXBOTS "max_bots\0"
#define CONSOLE_CMD_MINBOTSKILL "minbotskill\0"
#define CONSOLE_CMD_MAXBOTSKILL "maxbotskill\0"
#define CONSOLE_CMD_PAUSE "pause\0"
#define CONSOLE_CMD_BOTCHAT "botchat\0"
#define CONSOLE_CMD_JASONMODE "jasonmode\0"
#define CONSOLE_CMD_PODMENU "podbotmenu\0"
#define CONSOLE_CMD_WPTFOLDER "wptfolder\0"
#define CONSOLE_CMD_DETAILNAMES "detailnames\0"
#define CONSOLE_CMD_INHUMANTURNS "inhumanturns\0"
#define CONSOLE_CMD_MAXBOTSFOLLOW "botsfollowuser\0"
#define CONSOLE_CMD_MAXWEAPONPICKUP "maxweaponpickup\0"
#define CONSOLE_CMD_EXPERIENCE "experience\0"
#define CONSOLE_CMD_COLLECTEXP "collectexperience\0"
#define CONSOLE_CMD_SHOOTTHRU "shootthruwalls\0"
#define CONSOLE_CMD_TIMESOUND "timer_sound\0"
#define CONSOLE_CMD_TIMEPICKUP "timer_pickup\0"
#define CONSOLE_CMD_TIMEGRENADE "timer_grenade\0"
#define CONSOLE_CMD_SPEECH "usespeech\0"
#define CONSOLE_CMD_ALLOWSPRAY "botspray\0"
#define CONSOLE_CMD_DANGERFACTOR "danger_factor\0"
#define CONSOLE_CMD_WPMENU "wpmenu\0"



#define BOT_NAME_LEN 32 // Max Botname len

#define WANDER_LEFT 1
#define WANDER_RIGHT 2

#define BOT_YAW_SPEED 20
#define BOT_PITCH_SPEED 20  // degrees per frame for rotation

// Collision States
#define COLLISION_NOTDECIDED 0
#define COLLISION_PROBING 1
#define COLLISION_NOMOVE 2
#define COLLISION_JUMP 3
#define COLLISION_DUCK 4
#define COLLISION_STRAFELEFT 5
#define COLLISION_STRAFERIGHT 6

#define PROBE_JUMP (1 << 0) // Probe Jump when colliding
#define PROBE_DUCK (1 << 1) // Probe Duck when colliding
#define PROBE_STRAFE (1 << 2) // Probe Strafing when colliding


// game start messages for CS...
#define MSG_CS_IDLE 1
#define MSG_CS_TEAM_SELECT 2
#define MSG_CS_CT_SELECT 3
#define MSG_CS_T_SELECT 4

// teams for CS...
#define TEAM_CS_TERRORIST 1
#define TEAM_CS_COUNTER 2

// Misc Message Queue Defines
#define MSG_CS_RADIO 200
#define MSG_CS_SAY 10000


// Radio Messages
#define RADIO_COVERME 1
#define RADIO_YOUTAKEPOINT 2
#define RADIO_HOLDPOSITION 3
#define RADIO_REGROUPTEAM 4
#define RADIO_FOLLOWME 5
#define RADIO_TAKINGFIRE 6

#define RADIO_GOGOGO 11
#define RADIO_FALLBACK 12
#define RADIO_STICKTOGETHER 13
#define RADIO_GETINPOSITION 14
#define RADIO_STORMTHEFRONT 15
#define RADIO_REPORTTEAM 16

#define RADIO_AFFIRMATIVE 21
#define RADIO_ENEMYSPOTTED 22
#define RADIO_NEEDBACKUP 23
#define RADIO_SECTORCLEAR 24
#define RADIO_IMINPOSITION 25
#define RADIO_REPORTINGIN 26
#define RADIO_SHESGONNABLOW 27
#define RADIO_NEGATIVE 28
#define RADIO_ENEMYDOWN 29


// Sensing States
#define STATE_SEEINGENEMY (1 << 0) // Seeing an Enemy
#define STATE_HEARINGENEMY (1 << 1) // Hearing an Enemy
#define STATE_PICKUPITEM (1 << 2) // Pickup Item Nearby
#define STATE_THROWHEGREN (1 << 3) // Could throw HE Grenade
#define STATE_THROWFLASHBANG (1 << 4) // Could throw Flashbang
#define STATE_THROWSMOKEGREN (1 << 5) // Could throw SmokeGrenade
#define STATE_SUSPECTENEMY (1 << 6) // Suspect Enemy behind Obstacle

// Positions to aim at
#define AIM_DEST (1 << 0) // Aim at Nav Point
#define AIM_CAMP (1 << 1) // Aim at Camp Vector
#define AIM_PREDICTPATH (1 << 2) // Aim at predicted Path
#define AIM_LASTENEMY (1 << 3) // Aim at Last Enemy
#define AIM_ENTITY (1 << 4) // Aim at Entity like Buttons,Hostages
#define AIM_ENEMY (1 << 5) // Aim at Enemy
#define AIM_GRENADE (1 << 6) // Aim for Grenade Throw
#define AIM_OVERRIDE (1 << 7) // Overrides all others (blinded)

// Tasks to do
#define TASK_NONE -1
#define TASK_NORMAL 0
#define TASK_PAUSE 1
#define TASK_MOVETOPOSITION 2
#define TASK_FOLLOWUSER 3
#define TASK_WAITFORGO 4
#define TASK_PICKUPITEM 5
#define TASK_CAMP 6
#define TASK_PLANTBOMB 7
#define TASK_DEFUSEBOMB 8
#define TASK_ATTACK 9
#define TASK_ENEMYHUNT 10
#define TASK_SEEKCOVER 11
#define TASK_THROWHEGRENADE 12
#define TASK_THROWFLASHBANG 13
#define TASK_THROWSMOKEGRENADE 14
#define TASK_SHOOTBREAKABLE 15
#define TASK_HIDE 16
#define TASK_BLINDED 17
#define TASK_SPRAYLOGO 18


// Some hardcoded Desire Defines used to override calculated ones
#define TASKPRI_NORMAL 35.0
#define TASKPRI_PAUSE 36.0
#define TASKPRI_CAMP 37.0
#define TASKPRI_SPRAYLOGO 38.0
#define TASKPRI_FOLLOWUSER 39.0
#define TASKPRI_MOVETOPOSITION 50.0
#define TASKPRI_DEFUSEBOMB 89.0
#define TASKPRI_PLANTBOMB 89.0
#define TASKPRI_ATTACK 90.0
#define TASKPRI_SEEKCOVER 91.0
#define TASKPRI_HIDE 92.0
#define TASKPRI_THROWGRENADE 99.0
#define TASKPRI_BLINDED 100.0
#define TASKPRI_SHOOTBREAKABLE 100.0

#define WPMENU_WELCOMEMSG "\n\n\n     Welcome to Austin & SoUlFaThEr's\n     Waypoint Editor for POD-bot\n"

// Defines for Pickup Items
#define PICKUP_NONE  0
#define PICKUP_WEAPON 1
#define PICKUP_DROPPED_C4 2
#define PICKUP_PLANTED_C4 3
#define PICKUP_HOSTAGE 4
#define PICKUP_SHIELD 5
#define PICKUP_DEFUSEKIT 6

// Enemy Body Parts Seen
#define HEAD_VISIBLE (1 << 0)
#define WAIST_VISIBLE (1 << 1)
#define CUSTOM_VISIBLE (1 << 2)


#define MAX_HOSTAGES 8
#define MAX_DAMAGE_VAL 2040
#define MAX_GOAL_VAL 2040
#define TIME_GRENPRIME 1.2
#define MAX_KILL_HIST 16

#define BOMBMAXHEARDISTANCE 2048.0


// This Structure links Waypoints returned from Pathfinder
typedef struct pathnode
{
   int id;
   int iIndex;
   int depth;
   int state; // {OPEN, NEW, CLOSED}
   double g;
   double h;
   double f;
   pathnode *parent;
   pathnode *NextNode;
   pathnode *prev;
} PATHNODE;


// This Structure holds String Messages
typedef struct stringnode
{
   char szString[256];
   struct stringnode *Next;
} STRINGNODE;


// Links Keywords and replies together
typedef struct replynode
{
   char szKeywords[256];
   struct replynode *pNextReplyNode;
   char cNumReplies;
   char cLastReply;
   struct stringnode *pReplies;
} replynode_t;


typedef struct
{
   int iId; // weapon ID
   int iClip; // amount of ammo in the clip
   int iAmmo1; // amount of ammo in primary reserve
   int iAmmo2; // amount of ammo in secondary reserve
} bot_current_weapon_t;


typedef struct
{
   int iId; // the weapon ID value
   char weapon_name[64]; // name of the weapon when selecting it
   char model_name[64]; // Model Name to separate CS Weapons
   char buy_shortcut[64]; // Buy Shortcut (CS 1.6 specific)
   char buy_command[64]; // Buy Script to get this Weapon (equivalent of the above but for CS 1.5)
   float primary_min_distance; // 0 = no minimum
   float primary_max_distance; // 9999 = no maximum
   float secondary_min_distance; // 0 = no minimum
   float secondary_max_distance; // 9999 = no maximum
   bool  can_use_underwater; // can use this weapon underwater
   bool  primary_fire_hold; // hold down primary fire button to use?
   float primary_charge_delay; // time to charge weapon
   int iPrice; // Price when buying
   int min_primary_ammo;
   int iTeamStandard; // Used by Team (Number) (standard map)
   int iTeamAS; // Used by Team (AS map)
   bool  bShootsThru; // Can shoot thru Walls
} bot_weapon_select_t;


typedef struct
{
   float fMinSurpriseDelay; // time in secs
   float fMaxSurpriseDelay; // time in secs
   int iPauseProbality; // % Probability to pause after reaching a waypoint
   float fBotCampStartDelay; // time in secs
   float fBotCampEndDelay; // time in secs
} skilldelay_t;


typedef struct
{
   float fAim_X; // X Max Offset
   float fAim_Y; // Y Max Offset
   float fAim_Z; // Z Max Offset
   int iHeadShot_Frequency; // % to aim at Haed
   int iHeardShootThruProb; // % to shoot thru Wall when heard
   int iSeenShootThruProb; // % to shoot thru Wall when seen
} botaim_t;


// Struct for Menus
typedef struct
{
   int ValidSlots; // Ored together Bits for valid Keys
   char *szMenuText; // Ptr to actual String
} menutext_t;


// Records some Player Stats each Frame and holds sound events playing
typedef struct
{
   bool IsUsed; // Player used in the Game
   bool IsAlive; // Alive or Dead
   edict_t *pEdict; // Ptr to actual Edict
   int iTeam; // What Team
   Vector vOrigin; // Position in the world
   Vector vecSoundPosition; // Position Sound was played
   float fHearingDistance; // Distance this Sound is heared
   float fTimeSoundLasting; // Time sound is played/heared
   float welcome_time;
   float wptmessage_time;
} client_t;


// Experience Data hold in memory while playing
typedef struct
{
   unsigned short uTeam0Damage; // Amount of Damage
   unsigned short uTeam1Damage; // "
   signed short iTeam0_danger_index; // Index of Waypoint
   signed short iTeam1_danger_index; // "
   signed short wTeam0Value; // Goal Value
   signed short wTeam1Value; // "
} experience_t;


// Experience Data when saving/loading
typedef struct
{
   unsigned char uTeam0Damage;
   unsigned char uTeam1Damage;
   signed char cTeam0Value;
   signed char cTeam1Value;
} experiencesave_t;


// Array to hold Params for creation of a Bot
typedef struct
{
   bool bNeedsCreation;
   char bot_name[BOT_NAME_LEN + 1];
   int bot_skill;
   int bot_team;
   int bot_class;
} createbot_t;


typedef struct
{
   char cChatProbability;
   float fChatDelay;
   float fTimeNextChat;
   int iEntityIndex;
   char szSayText[512];
} saytext_t;


// Main Bot Structure
typedef struct
{
   bool is_used; // Bot used in the Game
   edict_t *pEdict; // ptr to actual Player edict
   int not_started; // team/class not chosen yet

   int start_action; // Team/Class selection state
   bool bDead; // dead or alive
   char name[BOT_NAME_LEN + 1]; // botname
   int bot_skill; // skill

   float fBaseAgressionLevel; // Base Levels used when initializing
   float fBaseFearLevel;
   float fAgressionLevel; // Dynamic Levels used ingame
   float fFearLevel;
   float fNextEmotionUpdate; // Next time to sanitize emotions

   float oldcombatdesire; // holds old desire for filtering

   unsigned char bot_personality; // Personality 0-2
   int iSprayLogo; // Index of Logo to use

   unsigned int iStates; // Sensing BitStates
   bottask_t *pTasks; // Ptr to active Tasks/Schedules

   float fTimePrevThink; // Last time BotThink was called
   float fTimeFrameInterval; // Interval Time between BotThink calls

   // things from pev in CBasePlayer...
   int bot_team;
   int bot_class;
   int bot_money; // money in Counter-Strike

   bool bIsVIP; // Bot is VIP
   bool bIsLeader; // Bot is leader of his Team;
   float fTimeTeamOrder; // Time of Last Radio command

   float f_move_speed; // Current Speed forward/backward
   float f_sidemove_speed; // Current Speed sideways
   float fMinSpeed; // Minimum Speed in Normal Mode
   bool bCheckTerrain;

   bool bOnLadder;
   bool bInWater;
   bool bJumpDone;
   float f_timeDoorOpen;
   bool bCheckMyTeam;

   float prev_time; // Time previously checked movement speed
   float prev_speed; // Speed some frames before
   Vector v_prev_origin; // Origin " " "

   bool bCanJump; // Bot can jump over obstacle
   bool bCanDuck; // Bot can duck under obstacle

   float f_view_distance; // Current View distance
   float f_maxview_distance; // Maximum View distance

   int iActMessageIndex; // Current processed Message
   int iPushMessageIndex; // Offset for next pushed Message

   int aMessageQueue[32]; // Stack for Messages
   char szMiscStrings[160]; // Space for Strings (SayText...)
   int iRadioSelect; // Radio Entry

   // Holds the Index & the actual Message of the last
   // unprocessed Text Message of a Player
   saytext_t SaytextBuffer;

   float f_itemcheck_time; // Time next Search for Items needs to be done
   edict_t *pBotPickupItem; // Ptr to Entity of Item to use/pickup
   edict_t *pItemIgnore; // Ptr to Entity to ignore for pickup
   int iPickupType; // Type of Entity which needs to be used/picked up

   edict_t *pShootBreakable; // Ptr to Breakable Entity
   Vector vecBreakable; // Origin of Breakable

   int iNumWeaponPickups; // Counter of Pickups done

   float f_spawn_time; // Time this Bot spawned
   float f_kick_time; // "  "  " was kicked

   float f_lastchattime; // Time Bot last chatted

   bool bLogoSprayed; // Logo sprayed this round
   bool bDefendedBomb; // Defend Action issued

   float f_firstcollide_time; // Time of first collision
   float f_probe_time; // Time of probing different moves
   float fNoCollTime; // Time until next collision check
   float f_CollisionSidemove; // Amount to move sideways
   char cCollisionState; // Collision State
   char cCollisionProbeBits; // Bits of possible Collision Moves
   char cCollideMoves[4]; // Sorted Array of Movements
   char cCollStateIndex; // Index into cCollideMoves

   Vector wpt_origin; // Origin of Current Waypoint
   Vector dest_origin; // Origin of move destination

   PATHNODE *pWaypointNodes; // Ptr to current Node from Path
   PATHNODE *pWayNodesStart; // Ptr to start of Pathfinding Nodes
   unsigned char byPathType; // Which Pathfinder to use
   int prev_goal_index; // Holds destination Goal wpt
   int chosengoal_index; // Used for experience, same as above
   float f_goal_value; // Ranking Value for this waypoint
   int curr_wpt_index; // Current wpt index
   int prev_wpt_index[5]; // Previous wpt indices from waypointfind
   int iWPTFlags;
   unsigned short curr_travel_flags; // Connection Flags like jumping
   Vector vecDesiredVelocity; // Desired Velocity for jump waypoints
   float f_wpt_timeset; // Time waypoint chosen by Bot

   edict_t *pBotEnemy; // ptr to Enemy Entity
   float fEnemyUpdateTime; // Time to check for new enemies
   float fEnemyReachableTimer; // Time to recheck if Enemy reachable
   bool bEnemyReachable; // Direct Line to Enemy

   float f_bot_see_enemy_time; // Time Bot sees Enemy
   float f_enemy_surprise_time; // Time of surprise
   float f_ideal_reaction_time; // Time of base reaction
   float f_actual_reaction_time; // Time of current reaction time

   float rgfYawHistory[2];
   float rgfPitchHistory[2];

   edict_t *pLastEnemy; // ptr to last Enemy Entity
   Vector vecLastEnemyOrigin; // Origin
   Vector vecEnemyVelocity; // Velocity of Enemy 1 Frame before
   unsigned char ucVisibility; // Which Parts are visible
   edict_t *pLastVictim; // ptr to killed Entity
   edict_t *pTrackingEdict; // ptr to last tracked Player when camping/hiding
   float fTimeNextTracking; // Time Waypoint Index for tracking Player is recalculated

   unsigned int iAimFlags; // Aiming Conditions
   Vector vecLookAt; // Vector Bot should look at
   Vector vecThrow; // Origin of Waypoint to Throw Grens

   Vector vecEnemy; // Target Origin chosen for shooting
   Vector vecGrenade; // Calculated Vector for Grenades
   Vector vecEntity; // Origin of Entities like Buttons etc.
   Vector vecCamp; // Aiming Vector when camping.

   float fTimeWaypointMove; // Last Time Bot followed Waypoints

   bool bWantsToFire; // Bot needs consider firing
   float f_shootatdead_time; // Time to shoot at dying players
   edict_t *pAvoidGrenade; // ptr to Grenade Entity to avoid
   char cAvoidGrenade; // which direction to strafe away

   Vector vecPosition; // Position to Move To (TASK_MOVETOPOSITION)

   edict_t *pBotUser; // ptr to User Entity (using a Bot)
   float f_bot_use_time; // Time last seen User

   edict_t *pRadioEntity; // ptr to Entity issuing a Radio Command
   int iRadioOrder; // actual Command

   edict_t *pHostages[MAX_HOSTAGES]; // ptr to used Hostage Entities

   float f_hostage_check_time; // Next time to check if Hostage should be used

   bool bIsReloading; // Bot is reloading a gun
   float f_zoomchecktime; // Time to check Zoom again

   int iBurstShotsFired; // Shots fired in 1 interval
   float fTimeLastFired;
   float fTimeFirePause;
   float f_shoot_time;

   bool  bCheckWeaponSwitch;
   float fTimeWeaponSwitch;

   int charging_weapon_id;
   float f_primary_charging;
   float f_secondary_charging;

   float f_grenade_check_time; // Time to check Grenade Usage
   bool bUsingGrenade;

   unsigned char byCombatStrafeDir; // Direction to strafe
   unsigned char byFightStyle; // Combat Style to use
   float f_lastfightstylecheck; // Time checked style
   float f_StrafeSetTime; // Time strafe direction was set

   float f_blind_time; // Time Bot is blind
   float f_blindmovespeed_forward; // Mad speeds when Bot is blind
   float f_blindmovespeed_side;

   int iLastDamageType; // Stores Last Damage

   float f_sound_update_time; // Time next sound next soundcheck
   float f_heard_sound_time; // Time enemy has been heard
   float fTimeCamping; // Time to Camp
   int iCampDirection; // Camp Facing direction
   float fNextCampDirectionTime; // Time next Camp Direction change
   int iCampButtons; // Buttons to press while camping

   float f_jumptime; // Time last jump happened

   bool b_bomb_blinking; // Time to hold Button for planting
   bool b_has_defuse_kit; // Bot has Defuse Kit
   bool b_can_buy; // Buy Zone Icon is lit

   int iBuyCount; // Current Count in Buying
   float f_buy_time; // Time of next Buying

   bot_weapon_select_t *pSelected_weapon; // Weapon chosen to be selected
   bot_current_weapon_t current_weapon; // one current weapon for each bot
   int m_rgAmmo[MAX_AMMO_SLOTS]; // total ammo amounts (1 array for each bot)
} bot_t;


// bot.cpp functions...
void EstimateNextFrameDuration (void);
void BotSpawnInit (bot_t *pBot);
void BotCreate (int bot_skill, int bot_team, int bot_class, const char *bot_name);
void UserRemoveAllBots (void);
void UserKillAllBots (void);
void UserNewroundAll (void);
void UserSelectWeaponMode (int iSelection);
bool BotCheckWallOnLeft (bot_t *pBot);
void UpdateGlobalExperienceData (void);
void BotCollectGoalExperience (bot_t *pBot, int iDamage);
void BotCollectExperienceData (edict_t *pVictimEdict,edict_t *pAttackerEdict, int iDamage);
void BotPushTask (bot_t *pBot,bottask_t *pTask);
void BotTaskComplete (bot_t *pBot);
void BotResetTasks (bot_t *pBot);
bottask_t *BotGetSafeTask (bot_t *pBot);
void BotRemoveCertainTask (bot_t *pBot, int iTaskNum);
void BotThink (bot_t *pBot);
bool BotEnemyIsThreat (bot_t *pBot);
bool BotReactOnEnemy (bot_t *pBot);
void BotResetCollideState (bot_t *pBot);
bool BotCheckWallOnRight (bot_t *pBot);
bool BotHasHostage (bot_t *pBot);
int GetBestWeaponCarried (bot_t *pBot);
Vector GetBombPosition (void);
int BotFindDefendWaypoint (bot_t *pBot, Vector vecPosition);
bool BotFindWaypoint (bot_t *pBot);
bool BotEntityIsVisible (bot_t *pBot, Vector dest);
int BotGetMessageQueue (bot_t *pBot);
void BotPushMessageQueue (bot_t *pBot, int iMessage);
void BotPlayRadioMessage (bot_t *pBot, int iMessage);
bool IsDeadlyDrop (bot_t *pBot, Vector vecTargetPos);
void BotFreeAllMemory (void);
STRINGNODE *GetNodeSTRING (STRINGNODE* pNode, int NodeNum);
void TestDecal (edict_t *pEdict, char *pszDecalName);

// bot_combat.cpp functions...
int NumTeammatesNearPos (bot_t *pBot, Vector vecPosition, int iRadius);
int NumEnemiesNearPos (bot_t *pBot, Vector vecPosition, int iRadius);
bool BotFindEnemy (bot_t *pBot);
bool IsShootableThruObstacle (edict_t *pEdict, Vector vecDest);
bool BotFireWeapon (Vector v_enemy, bot_t *pBot);
void BotFocusEnemy (bot_t *pBot);
void BotDoAttackMovement (bot_t *pBot);
bool BotHasPrimaryWeapon (bot_t *pBot);
bool BotHasShield (bot_t *pBot);
bool BotHasShieldDrawn (bot_t *pBot);
bool WeaponShootsThru (int iId);
bool BotUsesRifle (bot_t *pBot);
bool BotUsesSniper (bot_t *pBot);
int BotCheckGrenades (bot_t *pBot);
int HighestWeaponOfEdict (edict_t *pEdict);
void BotSelectBestWeapon (bot_t *pBot);
void SelectWeaponByName (bot_t *pBot, char *pszName);
void SelectWeaponbyNumber (bot_t *pBot, int iNum);
void BotCommandTeam (bot_t *pBot);
bool IsGroupOfEnemies (bot_t *pBot, Vector vLocation);
Vector VecCheckToss (edict_t *pEdict, const Vector &vecSpot1, Vector vecSpot2);
Vector VecCheckThrow (edict_t *pEdict, const Vector &vecSpot1, Vector vecSpot2, float flSpeed);

// bot_sound.cpp functions...
void SoundAttachToThreat (edict_t *pEdict, const char *pszSample, float fVolume);
void SoundSimulateUpdate (int iPlayerIndex);

// bot_chat.cpp functions...
void BotPrepareChatMessage (bot_t *pBot, char *pszText);
bool BotRepliesToPlayer (bot_t *pBot);

// bot_client.cpp functions...
void BotClient_CS_VGUI (void *p, int bot_index);
void BotClient_CS_ShowMenu (void *p, int bot_index);
void BotClient_CS_StatusIcon (void *p, int bot_index);
void BotClient_CS_WeaponList (void *p, int bot_index);
void BotClient_CS_CurrentWeapon (void *p, int bot_index);
void BotClient_CS_AmmoX (void *p, int bot_index);
void BotClient_CS_AmmoPickup (void *p, int bot_index);
void BotClient_CS_Damage (void *p, int bot_index);
void BotClient_CS_Money (void *p, int bot_index);
void BotClient_CS_DeathMsg (void *p, int bot_index);
void BotClient_CS_ScreenFade (void *p, int bot_index);
void BotClient_CS_SayText (void *p, int bot_index);
void BotClient_CS_HLTV (void *p, int bot_index);
void BotClient_CS_BombDrop (void *p, int bot_index);
void BotClient_CS_BombPickup (void *p, int bot_index);
void BotClient_CS_TextMsgAll (void *p, int bot_index);

// new util.cpp functions...
unsigned short FixedUnsigned16 (float value, float scale);
short FixedSigned16 (float value, float scale);
int UTIL_GetTeam (edict_t *pEntity);
bot_t *UTIL_GetBotPointer (edict_t *pEdict);
bool IsAlive (edict_t *pEdict);
bool FInViewCone (Vector *pOrigin, edict_t *pEdict);
float GetShootingConeDeviation (edict_t *pEdict, Vector *pvecPosition);
bool IsShootableBreakable (edict_t *pent);
bool FBoxVisible (edict_t *pEdict, edict_t *pTargetEdict, Vector *pvHit, unsigned char *ucBodyPart);
bool FVisible (const Vector &vecOrigin, edict_t *pEdict);
Vector Center (edict_t *pEdict);
Vector GetGunPosition (edict_t *pEdict);
Vector VecBModelOrigin (edict_t *pEdict);
void UTIL_ShowMenu (menutext_t *pMenu);
void UTIL_DisplayWpMenuWelcomeMessage (void);
void UTIL_DecalTrace (TraceResult *pTrace, char *pszDecalName);
int UTIL_GetNearestPlayerIndex (Vector vecOrigin);
void UTIL_HostPrint (const char *fmt, ...);
void UTIL_ServerPrint (const char *fmt, ...);
void UTIL_ClampAngle (float *fAngle);
void UTIL_ClampVector (Vector *vecAngles);
void UTIL_RoundStart (void);
int printf (const char *fmt, ...);

#endif // BOT_H