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
// waypoint.h
//
// Contains Defines and Structures for the Waypoint Code

#ifndef WAYPOINT_H
#define WAYPOINT_H

#define MAP_AS (1 << 0)
#define MAP_CS (1 << 1)
#define MAP_DE (1 << 2)

// defines for waypoint flags field (32 bits are available)
#define W_FL_USE_BUTTON (1 << 0) // use a nearby button (lifts, doors, etc.)
#define W_FL_LIFT (1 << 1) // wait for lift to be down before approaching this waypoint
#define W_FL_CROUCH (1 << 2) // must crouch to reach this waypoint
#define W_FL_CROSSING (1 << 3)   // a target waypoint
#define W_FL_GOAL (1 << 4) // mission goal point (bomb, hostage etc.)
#define W_FL_LADDER (1 << 5) // waypoint is on ladder
#define W_FL_RESCUE (1 << 6) // waypoint is a Hostage Rescue Point
#define W_FL_CAMP (1 << 7) // waypoint is a Camping Point
#define W_FL_NOHOSTAGE (1 << 8)   // only use this waypoint if no hostage
#define W_FL_TERRORIST (1 << 29) // It's a specific Terrorist Point
#define W_FL_COUNTER (1 << 30) // It's a specific Counter Terrorist Point

#define WAYPOINT_ADD_NORMAL 0
#define WAYPOINT_ADD_USE_BUTTON 1
#define WAYPOINT_ADD_LIFT 2
#define WAYPOINT_ADD_CROUCH 3
#define WAYPOINT_ADD_CROSSING 4
#define WAYPOINT_ADD_GOAL 5
#define WAYPOINT_ADD_LADDER 6
#define WAYPOINT_ADD_RESCUE 7
#define WAYPOINT_ADD_CAMP_START 8
#define WAYPOINT_ADD_CAMP_END 9
#define WAYPOINT_ADD_NOHOSTAGE 10
#define WAYPOINT_ADD_TERRORIST 11
#define WAYPOINT_ADD_COUNTER 12
#define WAYPOINT_ADD_JUMP_START 13
#define WAYPOINT_ADD_JUMP_END 14

#define PATH_OUTGOING 0
#define PATH_INCOMING 1
#define PATH_BOTHWAYS 2

#define FLAG_CLEAR 0
#define FLAG_SET 1
#define FLAG_TOGGLE 2

// defines for waypoint connection flags field (16 bits are available)
#define C_FL_JUMP (1 << 0) // Must Jump for this Connection

#define WAYPOINT_VERSION7 7
#define WAYPOINT_VERSION6 6
#define WAYPOINT_VERSION5 5

#define EXPERIENCE_VERSION 2
#define VISTABLE_VERSION 1


// define the waypoint file header structure...
typedef struct
{
   char filetype[8]; // should be "PODWAY!\0"
   int waypoint_file_version;
   int number_of_waypoints;
   char mapname[32]; // name of map for these waypoints
   char creatorname[32]; // Name of Waypoint File Creator
} WAYPOINT_HDR;


// define the experience file header structure...
typedef struct
{
   char filetype[8]; // should be "PODEXP!\0"
   int experiencedata_file_version;
   int number_of_waypoints;
} EXPERIENCE_HDR;


// define the vistable file header structure...
typedef struct
{
   char filetype[8]; // should be "PODVIS!\0"
   int vistable_file_version;
   int number_of_waypoints;
} VISTABLE_HDR;


#define MAX_PATH_INDEX 8
#define OLDMAX_PATH_INDEX 4


// define the structure for waypoint paths (paths are connections between
// two waypoint nodes that indicates the bot can get from point A to point B.
// note that paths DON'T have to be two-way.  sometimes they are just one-way
// connections between two points.  There is an array called "paths" that
// contains head pointers to these structures for each waypoint index.
typedef struct path
{
   int iPathNumber;
   int flags; // button, lift, flag, health, ammo, etc.
   Vector origin; // location

   float Radius; // Maximum Distance WPT Origin can be varied

   float fcampstartx;
   float fcampstarty;
   float fcampendx;
   float fcampendy;
   short int index[MAX_PATH_INDEX]; // indexes of waypoints (index -1 means not used)
   unsigned short connectflag[MAX_PATH_INDEX];
   Vector vecConnectVel[MAX_PATH_INDEX];
   int distance[MAX_PATH_INDEX];
   struct path *next; // link to next structure
} PATH;


// Path Structure used by Version 6
typedef struct path6
{
   int iPathNumber;
   int flags; // button, lift, flag, health, ammo, etc.
   Vector origin; // location

   float Radius; // Maximum Distance WPT Origin can be varied

   float fcampstartx;
   float fcampstarty;
   float fcampendx;
   float fcampendy;
   short int index[MAX_PATH_INDEX]; // indexes of waypoints (index -1 means not used)
   int distance[MAX_PATH_INDEX];
   struct path6 *next; // link to next structure
} PATH6;


// Path Structure used by Version 5
typedef struct path5
{
   int iPathNumber;
   int flags; // button, lift, flag, health, ammo, etc.
   Vector origin;   // location

   float Radius; // Maximum Distance WPT Origin can be varied

   float fcampstartx;
   float fcampstarty;
   float fcampendx;
   float fcampendy;
   short int index[OLDMAX_PATH_INDEX]; // indexes of waypoints (index -1 means not used)
   int distance[OLDMAX_PATH_INDEX];
   struct path5 *next; // link to next structure
} PATH5;


// waypoint function prototypes...
int WaypointFindNearest (void);
int WaypointFindNearestToMove (Vector vOrigin);
void WaypointFindInRadius (Vector vecPos, float fRadius, int *pTab, int *iCount);
void WaypointAdd (int iFlags);
void WaypointDelete (void);
void WaypointCache (void);
void WaypointChangeRadius (float radius);
void WaypointChangeFlag (int flag, char status);
void WaypointCreatePath (char direction);
void WaypointDeletePath (void);
void WaypointCalcVisibility (void);
bool WaypointIsVisible (int iSourceIndex, int iDestIndex);
bool ConnectedToWaypoint (int a, int b);
void CalculateWaypointWayzone (void);
void SaveExperienceTab (void);
void InitExperienceTab (void);
void SaveVisTab (void);
void InitVisTab (void);
bool WaypointLoad (void);
void WaypointSave (void);
bool WaypointReachable (Vector v_srv, Vector v_dest, edict_t *pEntity);
void WaypointThink (void);
void WaypointDrawBeam (Vector start, Vector end, int width, int red, int green, int blue);
bool WaypointNodesValid (void);
bool WaypointNodeReachable (Vector v_src, Vector v_dest);
int GetAimingWaypoint (bot_t *pBot,Vector vecTargetPos, int iCount);
float GetTravelTime (float fMaxSpeed, Vector vecSource,Vector vecPosition);


// Floyd Search Prototypes
void DeleteSearchNodes (bot_t *pBot);
void InitPathMatrix (void);
int GetPathDistance (int iSourceWaypoint, int iDestWaypoint);
PATHNODE *FindShortestPath (int iSourceIndex, int iDestIndex, bool *bValid);


// A* Stuff
#define OPEN 1
#define CLOSED 2


int gfunctionKillsT (PATHNODE *p);
int gfunctionKillsCT (PATHNODE *p);
int gfunctionKillsCTWithHostage (PATHNODE *p);
int gfunctionKillsDistT (PATHNODE *p);
int gfunctionKillsDistCT (PATHNODE *p);
int gfunctionKillsDistCTWithHostage (PATHNODE *p);
int hfunctionNone (PATHNODE *p);
int hfunctionSquareDist (PATHNODE *p);
int goal (PATHNODE *p);
PATHNODE *makeChildren (PATHNODE *parent);
int nodeEqual (PATHNODE *a, PATHNODE *b);
void TestAPath (edict_t *pPlayer, int iSourceIndex, int iDestIndex, unsigned char byPathType);
PATHNODE *FindLeastCostPath (bot_t *pBot, int iSourceIndex, int iDestIndex);


// function prototypes
PATHNODE *AStarSearch (PATHNODE *root, int (*gcalc) (PATHNODE *), int (*hcalc) (PATHNODE *),
                       int (*goalNode) (PATHNODE *), PATHNODE * (*children) (PATHNODE *),
                       int (*nodeEqual) (PATHNODE *, PATHNODE *));


int Encode (char *filename, unsigned char* header, int headersize, unsigned char *buffer, int bufsize);
int Decode (char *filename, int headersize, unsigned char *buffer, int bufsize);

#endif // WAYPOINT_H
