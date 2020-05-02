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
// dll.cpp
//
// Links Functions, handles Client Commands, initializes DLL and misc Stuff

#include "bot_globals.h"



// server command handler
void PODBot_ServerCommand (void);




// START of Metamod stuff

enginefuncs_t meta_engfuncs;
gamedll_funcs_t *gpGamedllFuncs;
mutil_funcs_t *gpMetaUtilFuncs;
meta_globals_t *gpMetaGlobals;

META_FUNCTIONS gMetaFunctionTable =
{
   NULL, // pfnGetEntityAPI()
   NULL, // pfnGetEntityAPI_Post()
   GetEntityAPI2, // pfnGetEntityAPI2()
   GetEntityAPI2_Post, // pfnGetEntityAPI2_Post()
   NULL, // pfnGetNewDLLFunctions()
   NULL, // pfnGetNewDLLFunctions_Post()
   GetEngineFunctions, // pfnGetEngineFunctions()
   NULL, // pfnGetEngineFunctions_Post()
};

plugin_info_t Plugin_info = {
   META_INTERFACE_VERSION, // interface version
   "POD-Bot", // plugin name
   "2.6mm", // plugin version
   __DATE__, // date of creation
   "Count Floyd & Bots United", // plugin author
   "http://www.bots-united.com", // plugin URL
   "PODBOT", // plugin logtag
   PT_CHANGELEVEL, // when loadable
   PT_ANYTIME, // when unloadable
};


C_DLLEXPORT int Meta_Query (char *ifvers, plugin_info_t **pPlugInfo, mutil_funcs_t *pMetaUtilFuncs)
{
   // this function is the first function ever called by metamod in the plugin DLL. Its purpose
   // is for metamod to retrieve basic information about the plugin, such as its meta-interface
   // version, for ensuring compatibility with the current version of the running metamod.

   // keep track of the pointers to metamod function tables metamod gives us
   gpMetaUtilFuncs = pMetaUtilFuncs;
   *pPlugInfo = &Plugin_info;

   // check for interface version compatibility
   if (strcmp (ifvers, Plugin_info.ifvers) != 0)
   {
      int mmajor = 0, mminor = 0, pmajor = 0, pminor = 0;

      LOG_CONSOLE (PLID, "%s: meta-interface version mismatch (metamod: %s, %s: %s)", Plugin_info.name, ifvers, Plugin_info.name, Plugin_info.ifvers);
      LOG_MESSAGE (PLID, "%s: meta-interface version mismatch (metamod: %s, %s: %s)", Plugin_info.name, ifvers, Plugin_info.name, Plugin_info.ifvers);

      // if plugin has later interface version, it's incompatible (update metamod)
      sscanf (ifvers, "%d:%d", &mmajor, &mminor);
      sscanf (META_INTERFACE_VERSION, "%d:%d", &pmajor, &pminor);

      if ((pmajor > mmajor) || ((pmajor == mmajor) && (pminor > mminor)))
      {
         LOG_CONSOLE (PLID, "metamod version is too old for this plugin; update metamod");
         LOG_ERROR (PLID, "metamod version is too old for this plugin; update metamod");
         return (FALSE);
      }

      // if plugin has older major interface version, it's incompatible (update plugin)
      else if (pmajor < mmajor)
      {
         LOG_CONSOLE (PLID, "metamod version is incompatible with this plugin; please find a newer version of this plugin");
         LOG_ERROR (PLID, "metamod version is incompatible with this plugin; please find a newer version of this plugin");
         return (FALSE);
      }
   }

   return (TRUE); // tell metamod this plugin looks safe
}


C_DLLEXPORT int Meta_Attach (PLUG_LOADTIME now, META_FUNCTIONS *pFunctionTable, meta_globals_t *pMGlobals, gamedll_funcs_t *pGamedllFuncs)
{
   // this function is called when metamod attempts to load the plugin. Since it's the place
   // where we can tell if the plugin will be allowed to run or not, we wait until here to make
   // our initialization stuff, like registering CVARs and dedicated server commands.

   // are we allowed to load this plugin now ?
   if (now > Plugin_info.loadable)
   {
      LOG_CONSOLE (PLID, "%s: plugin NOT attaching (can't load plugin right now)", Plugin_info.name);
      LOG_ERROR (PLID, "%s: plugin NOT attaching (can't load plugin right now)", Plugin_info.name);
      return (FALSE); // returning FALSE prevents metamod from attaching this plugin
   }

   // keep track of the pointers to engine function tables metamod gives us
   gpMetaGlobals = pMGlobals;
   memcpy (pFunctionTable, &gMetaFunctionTable, sizeof (META_FUNCTIONS));
   gpGamedllFuncs = pGamedllFuncs;

   // print a message to notify about plugin attaching
   LOG_CONSOLE (PLID, "%s: plugin attaching", Plugin_info.name);
   LOG_MESSAGE (PLID, "%s: plugin attaching", Plugin_info.name);

   // ask the engine to register the server commands this plugin uses
   REG_SVR_COMMAND ("pb", PODBot_ServerCommand);
   
   return (TRUE); // returning TRUE enables metamod to attach this plugin
}


C_DLLEXPORT int Meta_Detach (PLUG_LOADTIME now, PL_UNLOAD_REASON reason)
{
   // this function is called when metamod unloads the plugin. A basic check is made in order
   // to prevent unloading the plugin if its processing should not be interrupted.

   // is metamod allowed to unload the plugin ?
   if ((now > Plugin_info.unloadable) && (reason != PNL_CMD_FORCED))
   {
      LOG_CONSOLE (PLID, "%s: plugin NOT detaching (can't unload plugin right now)", Plugin_info.name);
      LOG_ERROR (PLID, "%s: plugin NOT detaching (can't unload plugin right now)", Plugin_info.name);
      return (FALSE); // returning FALSE prevents metamod from unloading this plugin
   }

   // Delete all allocated Memory
   BotFreeAllMemory();

   return (TRUE); // returning TRUE enables metamod to unload this plugin
}

// END of Metamod stuff


#ifndef __linux__
BOOL WINAPI DllMain (HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
   // Required DLL entry point

   return (TRUE);
}
#endif


void WINAPI GiveFnptrsToDll (enginefuncs_t* pengfuncsFromEngine, globalvars_t *pGlobals)
{
   // get the engine functions from the engine...

   memcpy (&g_engfuncs, pengfuncsFromEngine, sizeof (enginefuncs_t));
   gpGlobals = pGlobals;
}


void GameDLLInit (void)
{
   // First function called from HL in our replacement Server DLL

   unsigned char *tempbuf;
   int tempsize;
   g_bIsDedicatedServer = (IS_DEDICATED_SERVER () > 0);

   // Counter-Strike 1.5 detection
   tempbuf = LOAD_FILE_FOR_ME ("models/w_famas.mdl", &tempsize);
   if (tempbuf != NULL)
   {
      g_bIsOldCS15 = FALSE;
      FREE_FILE (tempbuf);
   }
   else
      g_bIsOldCS15 = TRUE;

   // Reset the bot creation tab
   memset (BotCreateTab, 0, sizeof (BotCreateTab));

   RETURN_META (MRES_IGNORED);
}


int Spawn (edict_t *pent)
{
   // Something gets spawned in the game

   if (strcmp (STRING (pent->v.classname), "worldspawn") == 0)
   {
      g_iMapType = 0; // reset g_iMapType as worldspawn is the first entity spawned
      PRECACHE_SOUND ("weapons/xbow_hit1.wav"); // waypoint add
      PRECACHE_SOUND ("weapons/mine_activate.wav"); // waypoint delete
      PRECACHE_SOUND ("common/wpn_hudon.wav"); // path add/delete done
      m_spriteTexture = PRECACHE_MODEL ("sprites/lgtning.spr");
   }

   else if (strcmp (STRING (pent->v.classname), "info_player_start") == 0)
   {
      SET_MODEL (pent, "models/player/urban/urban.mdl");
      pent->v.rendermode = kRenderTransAlpha; // set its render mode to transparency
      pent->v.renderamt = 127; // set its transparency amount
      pent->v.effects |= EF_NODRAW;
   }

   else if (strcmp (STRING (pent->v.classname), "info_player_deathmatch") == 0)
   {
      SET_MODEL (pent, "models/player/terror/terror.mdl");
      pent->v.rendermode = kRenderTransAlpha; // set its render mode to transparency
      pent->v.renderamt = 127; // set its transparency amount
      pent->v.effects |= EF_NODRAW;
   }

   else if (strcmp (STRING (pent->v.classname), "info_vip_start") == 0)
   {
      SET_MODEL (pent, "models/player/vip/vip.mdl");
      pent->v.rendermode = kRenderTransAlpha; // set its render mode to transparency
      pent->v.renderamt = 127; // set its transparency amount
      pent->v.effects |= EF_NODRAW;
   }

   else if ((strcmp (STRING (pent->v.classname), "func_vip_safetyzone") == 0)
            || (strcmp (STRING (pent->v.classname), "info_vip_safetyzone") == 0))
      g_iMapType |= MAP_AS; // assassination map

   else if (strcmp (STRING (pent->v.classname), "hostage_entity") == 0)
      g_iMapType |= MAP_CS; // rescue map

   else if ((strcmp (STRING (pent->v.classname), "func_bomb_target") == 0)
            || (strcmp (STRING (pent->v.classname), "info_bomb_target") == 0))
      g_iMapType |= MAP_DE; // defusion map

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


int Spawn_Post (edict_t *pent)
{
   // solves the bots unable to see through certain types of glass bug.
   // MAPPERS: NEVER EVER ALLOW A TRANSPARENT ENTITY TO WEAR THE FL_WORLDBRUSH FLAG !!!

   if (pent->v.rendermode == kRenderTransTexture)
      pent->v.flags &= ~FL_WORLDBRUSH; // clear the FL_WORLDBRUSH flag out of transparent ents

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


BOOL ClientConnect (edict_t *pEntity, const char *pszName, const char *pszAddress, char szRejectReason[ 128 ])
{
   // Client connects to this Server

   char cmd[80];
   int i;

   // check if this client is the listen server client
   if (strcmp (pszAddress, "loopback") == 0)
      pHostEdict = pEntity; // save the edict of the listen server client...

   // check if this is NOT a bot joining the server...
   if (strcmp (pszAddress, "127.0.0.1") != 0)
   {
      // if there are currently more than the minimum number of bots running
      // then kick one of the bots off the server...
      if ((num_bots > min_bots) && (min_bots != -1))
      {
         for (i = 0; i < 32; i++)
         {
            if (bots[i].is_used && !FNullEnt (bots[i].pEdict))  // is this slot used?
            {
               sprintf (cmd, "kick \"%s\"\n", STRING (bots[i].pEdict->v.netname));
               SERVER_COMMAND (cmd); // kick the bot using (kick "name")
               break;
            }
         }
      }
   }

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


void ClientDisconnect (edict_t *pEntity)
{
   // Client disconnects from this Server

   int i;

   i = ENTINDEX (pEntity) - 1;

   // Find & remove this Client from our list of Clients connected
   clients[i].welcome_time = 0;
   clients[i].wptmessage_time = 0;

   // Check if its a Bot
   if (bots[i].pEdict == pEntity)
   {
      // Delete Nodes from Pathfinding
      DeleteSearchNodes (&bots[i]);
      BotResetTasks (&bots[i]);
      bots[i].is_used = FALSE; // this slot is now free to use
      bots[i].f_kick_time = gpGlobals->time; // save the kicked time
   }

   // Check if its the Host disconnecting
   if (pEntity == pHostEdict)
      pHostEdict = NULL;

   RETURN_META (MRES_IGNORED);
}


void ClientPutInServer (edict_t *pEntity)
{
   // Client is finally put into the Server

   int i;

   i = ENTINDEX (pEntity) - 1;

   clients[i].welcome_time = gpGlobals->time + 10.0;
   clients[i].wptmessage_time = gpGlobals->time + 1.0;

   RETURN_META (MRES_IGNORED);
}


void ClientCommand (edict_t *pEntity)
{
   // Executed if a client typed some sort of command into the console

   static char pcmd[128];
   static char arg1[128];
   static char arg2[128];
   static char arg3[128];
   static char arg4[128];
   static char arg5[128];
   static char arg6[128];
   static char arg7[128];
   static char arg8[128];
   static char arg9[128];
   char kick_command[128];
   edict_t *pSpawnPoint = NULL;
   int iClientIndex;
   int iRadioCommand;
   int i;

   sprintf (pcmd, CMD_ARGV (0));
   sprintf (arg1, CMD_ARGV (1));
   sprintf (arg2, CMD_ARGV (2));
   sprintf (arg3, CMD_ARGV (3));
   sprintf (arg4, CMD_ARGV (4));
   sprintf (arg5, CMD_ARGV (5));
   sprintf (arg6, CMD_ARGV (6));
   sprintf (arg7, CMD_ARGV (7));
   sprintf (arg8, CMD_ARGV (8));
   sprintf (arg9, CMD_ARGV (9));

   // don't search ClientCommands of Bots or other Edicts than Host!
   if (!isFakeClientCommand && (pEntity == pHostEdict) && !g_bIsDedicatedServer)
   {
      // "addbot"
      if (FStrEq (pcmd, CONSOLE_CMD_ADDBOT))
      {
         BotCreate (atoi (arg1), atoi (arg2), atoi (arg3), arg4);
         RETURN_META (MRES_SUPERCEDE);
      }

      // "removebots"
      else if (FStrEq (pcmd, CONSOLE_CMD_REMOVEALLBOTS))
      {
         UserRemoveAllBots ();
         RETURN_META (MRES_SUPERCEDE);
      }

      // "killbots"
      else if (FStrEq (pcmd, CONSOLE_CMD_KILLALLBOTS))
      {
         UserKillAllBots ();
         RETURN_META (MRES_SUPERCEDE);
      }

      // Forces Bots to use a specified Waypoint as a Goal
      else if (FStrEq (pcmd, CONSOLE_CMD_DEBUGGOAL))
      {
         g_iDebugGoalIndex = atoi (arg1);

         // Bots ignore Enemies in Goal Debug Mode
         if ((g_iDebugGoalIndex >= 0) && (g_iDebugGoalIndex < g_iNumWaypoints))
            g_bIgnoreEnemies = TRUE;
         else
            g_bIgnoreEnemies = FALSE;

         UTIL_HostPrint ("Goal for Bot set to %d\n", g_iDebugGoalIndex);
         RETURN_META (MRES_SUPERCEDE);
      }

      // "waypoint"
      else if (FStrEq (pcmd, CONSOLE_CMD_WAYPOINT)
               || FStrEq (pcmd, CONSOLE_CMD_WP))
      {
         if (FStrEq (arg1, "stats"))
         {
            int iButtonPoints = 0;
            int iLiftPoints = 0;
            int iCrouchPoints = 0;
            int iCrossingPoints = 0;
            int iGoalPoints = 0;
            int iLadderPoints = 0;
            int iRescuePoints = 0;
            int iCampPoints = 0;
            int iNoHostagePoints = 0;
            int iTerroristPoints = 0;
            int iCounterPoints = 0;
            int iNormalPoints = 0;

            for (i = 0; i < g_iNumWaypoints; i++)
            {
               if (paths[i]->flags & W_FL_USE_BUTTON)
                  iButtonPoints++;
               if (paths[i]->flags & W_FL_LIFT)
                  iLiftPoints++;
               if (paths[i]->flags & W_FL_CROUCH)
                  iCrouchPoints++;
               if (paths[i]->flags & W_FL_CROSSING)
                  iCrossingPoints++;
               if (paths[i]->flags & W_FL_GOAL)
                  iGoalPoints++;
               if (paths[i]->flags & W_FL_LADDER)
                  iLadderPoints++;
               if (paths[i]->flags & W_FL_RESCUE)
                  iRescuePoints++;
               if (paths[i]->flags & W_FL_CAMP)
                  iCampPoints++;
               if (paths[i]->flags & W_FL_NOHOSTAGE)
                  iNoHostagePoints++;
               if (paths[i]->flags & W_FL_TERRORIST)
                  iTerroristPoints++;
               if (paths[i]->flags & W_FL_COUNTER)
                  iCounterPoints++;
               if (paths[i]->flags == 0)
                  iNormalPoints++;
            }

            UTIL_ServerPrint ("Waypoint Statistics:\n");
            UTIL_ServerPrint ("--------------------\n");
            UTIL_ServerPrint ("Waypoints classification per flag:\n");
            UTIL_ServerPrint ("W_FL_USE_BUTTON: %d\n", iButtonPoints);
            UTIL_ServerPrint ("W_FL_LIFT: %d\n", iLiftPoints);
            UTIL_ServerPrint ("W_FL_CROUCH: %d\n", iCrouchPoints);
            UTIL_ServerPrint ("W_FL_CROSSING: %d\n", iCrossingPoints);
            UTIL_ServerPrint ("W_FL_GOAL: %d\n", iGoalPoints);
            UTIL_ServerPrint ("W_FL_LADDER: %d\n", iLadderPoints);
            UTIL_ServerPrint ("W_FL_RESCUE: %d\n", iRescuePoints);
            UTIL_ServerPrint ("W_FL_CAMP: %d\n", iCampPoints);
            UTIL_ServerPrint ("W_FL_NOHOSTAGE: %d\n", iNoHostagePoints);
            UTIL_ServerPrint ("W_FL_TERRORIST: %d\n", iTerroristPoints);
            UTIL_ServerPrint ("W_FL_COUNTER: %d\n", iCounterPoints);
            UTIL_ServerPrint ("Not flagged: %d\n", iNormalPoints);
            UTIL_ServerPrint ("--------------------\n");
            UTIL_ServerPrint ("Total number of waypoints: %d\n", g_iNumWaypoints);
         }
         else if (FStrEq (arg1, "teleport"))
         {
            if ((atoi (arg2) >= 0) && (atoi (arg2) < g_iNumWaypoints))
            {
               TraceResult tr;
               TRACE_HULL (paths[atoi (arg2)]->origin + Vector (0, 0, 32),
                           paths[atoi (arg2)]->origin + Vector (0, 0, -32),
                           ignore_monsters, human_hull, pEntity, &tr);
               SET_ORIGIN (pEntity, tr.vecEndPos);
            }
         }
         else
         {
            UTIL_ServerPrint ("Unknown waypoint command.\n");
            UTIL_ServerPrint ("waypoint commands are: stats teleport\n");
         }

         RETURN_META (MRES_SUPERCEDE);
      }

      // "experience"
      else if (FStrEq (pcmd, CONSOLE_CMD_EXPERIENCE))
      {
         if (FStrEq (arg1, "save"))
         {
            SaveExperienceTab ();
            SaveVisTab ();
         }

         RETURN_META (MRES_SUPERCEDE);
      }

      // "botchat"
      else if (FStrEq (pcmd, CONSOLE_CMD_BOTCHAT))
      {
         if (FStrEq (arg1, "on"))
            g_bBotChat = TRUE;
         else if (FStrEq (arg1, "off"))
            g_bBotChat = FALSE;

         UTIL_HostPrint ("Bot Chat is %s\n", (g_bBotChat ? "ENABLED" : "DISABLED"));
         RETURN_META (MRES_SUPERCEDE);
      }

      // "jasonmode"
      else if (FStrEq (pcmd, CONSOLE_CMD_JASONMODE))
      {
         if (FStrEq (arg1, "on"))
            g_bJasonMode = TRUE;
         else if (FStrEq (arg1, "off"))
            g_bJasonMode = FALSE;

         UTIL_HostPrint ("Knife Mode is %s\n", (g_bJasonMode ? "ENABLED" : "DISABLED"));
         RETURN_META (MRES_SUPERCEDE);
      }

      // "danger_factor"
      else if (FStrEq (pcmd, CONSOLE_CMD_DANGERFACTOR))
      {
         if (atoi (arg1) > 0)
            g_iDangerFactor = atoi (arg1);

         UTIL_HostPrint ("Pathfinder danger factor is %d\n", g_iDangerFactor);
         RETURN_META (MRES_SUPERCEDE);
      }

      // "podbotmenu"
      else if (FStrEq (pcmd, CONSOLE_CMD_PODMENU))
      {
         UTIL_ShowMenu (&menuPODBotMain);
         RETURN_META (MRES_SUPERCEDE);
      }

      // "wpmenu"
      else if (FStrEq (pcmd, CONSOLE_CMD_WPMENU))
      {
         UTIL_ShowMenu (&menuWpMain);
         RETURN_META (MRES_SUPERCEDE);
      }

      // Care for Menus instead...
      else if (pUserMenu != NULL)
      {
         if (FStrEq (pcmd, "menuselect"))
         {
            // Waypoint Main Menu
            if (pUserMenu == &menuWpMain)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpAdd);
               }
               else if (FStrEq (arg1, "2"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpDelete);
               }
               else if (FStrEq (arg1, "3"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpSetRadius);
               }
               else if (FStrEq (arg1, "4"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpSetFlags);
               }
               else if (FStrEq (arg1, "5"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpAddPath);
               }
               else if (FStrEq (arg1, "6"))
               {
                  g_bWaypointOn = TRUE; // turn waypoints on if off
                  UTIL_ShowMenu (&menuWpDeletePath);
               }
               else if (FStrEq (arg1, "7"))
               {
                  if (WaypointNodesValid ())
                     UTIL_HostPrint ("All Nodes work fine !\n");
               }
               else if (FStrEq (arg1, "8"))
               {
                  if (WaypointNodesValid ())
                  {
                     WaypointSave ();
                     UTIL_HostPrint ("Waypoints saved!\n");
                  }
                  else
                     UTIL_ShowMenu (&menuWpSave);
               }
               else if (FStrEq (arg1, "9"))
                  UTIL_ShowMenu (&menuWpOptions);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Add Menu
            else if (pUserMenu == &menuWpAdd)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointAdd (WAYPOINT_ADD_NORMAL); // normal
               else if (FStrEq (arg1, "2"))
                  WaypointAdd (WAYPOINT_ADD_TERRORIST); // t important
               else if (FStrEq (arg1, "3"))
                  WaypointAdd (WAYPOINT_ADD_COUNTER); // ct important
               else if (FStrEq (arg1, "4"))
                  WaypointAdd (WAYPOINT_ADD_LADDER); // ladder
               else if (FStrEq (arg1, "5"))
                  WaypointAdd (WAYPOINT_ADD_RESCUE); // rescue
               else if (FStrEq (arg1, "6"))
                  WaypointAdd (WAYPOINT_ADD_CAMP_START); // camp start
               else if (FStrEq (arg1, "7"))
                  WaypointAdd (WAYPOINT_ADD_CAMP_END); // camp end
               else if (FStrEq (arg1, "8"))
                  WaypointAdd (WAYPOINT_ADD_GOAL); // goal
               else if (FStrEq (arg1, "9"))
               {
                  g_bLearnJumpWaypoint = TRUE;
                  UTIL_HostPrint ("Observation on !\n");
                  if (g_bUseSpeech)
                     SERVER_COMMAND ("speak \"movement check ok\"\n");
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Delete Menu
            else if (pUserMenu == &menuWpDelete)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointDelete ();

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint SetRadius Menu
            else if (pUserMenu == &menuWpSetRadius)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointChangeRadius (0);
               else if (FStrEq (arg1, "2"))
                  WaypointChangeRadius (8);
               else if (FStrEq (arg1, "3"))
                  WaypointChangeRadius (16);
               else if (FStrEq (arg1, "4"))
                  WaypointChangeRadius (32);
               else if (FStrEq (arg1, "5"))
                  WaypointChangeRadius (48);
               else if (FStrEq (arg1, "6"))
                  WaypointChangeRadius (64);
               else if (FStrEq (arg1, "7"))
                  WaypointChangeRadius (80);
               else if (FStrEq (arg1, "8"))
                  WaypointChangeRadius (96);
               else if (FStrEq (arg1, "9"))
                  WaypointChangeRadius (112);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint SetFlags Menu
            else if (pUserMenu == &menuWpSetFlags)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointChangeFlag (W_FL_USE_BUTTON, FLAG_TOGGLE);
               else if (FStrEq (arg1, "2"))
                  WaypointChangeFlag (W_FL_LIFT, FLAG_TOGGLE);
               else if (FStrEq (arg1, "3"))
                  WaypointChangeFlag (W_FL_CROUCH, FLAG_TOGGLE);
               else if (FStrEq (arg1, "4"))
                  WaypointChangeFlag (W_FL_GOAL, FLAG_TOGGLE);
               else if (FStrEq (arg1, "5"))
                  WaypointChangeFlag (W_FL_LADDER, FLAG_TOGGLE);
               else if (FStrEq (arg1, "6"))
                  WaypointChangeFlag (W_FL_RESCUE, FLAG_TOGGLE);
               else if (FStrEq (arg1, "7"))
                  WaypointChangeFlag (W_FL_CAMP, FLAG_TOGGLE);
               else if (FStrEq (arg1, "8"))
                  WaypointChangeFlag (W_FL_NOHOSTAGE, FLAG_TOGGLE);
               else if (FStrEq (arg1, "9"))
                  UTIL_ShowMenu (&menuWpSetTeam);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Set Team Menu
            else if (pUserMenu == &menuWpSetTeam)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
               {
                  WaypointChangeFlag (W_FL_TERRORIST, FLAG_SET);
                  WaypointChangeFlag (W_FL_COUNTER, FLAG_CLEAR);
               }
               else if (FStrEq (arg1, "2"))
               {
                  WaypointChangeFlag (W_FL_TERRORIST, FLAG_CLEAR);
                  WaypointChangeFlag (W_FL_COUNTER, FLAG_SET);
               }
               else if (FStrEq (arg1, "3"))
               {
                  WaypointChangeFlag (W_FL_TERRORIST, FLAG_CLEAR);
                  WaypointChangeFlag (W_FL_COUNTER, FLAG_CLEAR);
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Add Path Menu
            else if (pUserMenu == &menuWpAddPath)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointCreatePath (PATH_OUTGOING);
               else if (FStrEq (arg1, "2"))
                  WaypointCreatePath (PATH_INCOMING);
               else if (FStrEq (arg1, "3"))
                  WaypointCreatePath (PATH_BOTHWAYS);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Delete Path Menu
            else if (pUserMenu == &menuWpDeletePath)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
                  WaypointDeletePath ();

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Save Menu
            else if (pUserMenu == &menuWpSave)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
               {
                  WaypointSave ();
                  UTIL_HostPrint ("WARNING: Waypoints saved with errors!\n");
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint Options Menu
            else if (pUserMenu == &menuWpOptions)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1")) // wp on/off
               {
                  g_bWaypointOn ^= TRUE; // switch variable on/off (XOR it)

                  if (g_bWaypointOn)
                  {
                     UTIL_HostPrint ("Waypoints Editing is ON\n");

                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_player_start")))
                        pSpawnPoint->v.effects &= ~EF_NODRAW;
                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_player_deathmatch")))
                        pSpawnPoint->v.effects &= ~EF_NODRAW;
                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_vip_start")))
                        pSpawnPoint->v.effects &= ~EF_NODRAW;
                  }
                  else
                  {
                     UTIL_HostPrint ("Waypoint Editing turned OFF\n");

                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_player_start")))
                        pSpawnPoint->v.effects |= EF_NODRAW;
                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_player_deathmatch")))
                        pSpawnPoint->v.effects |= EF_NODRAW;
                     while (!FNullEnt (pSpawnPoint = FIND_ENTITY_BY_STRING (pSpawnPoint, "classname", "info_vip_start")))
                        pSpawnPoint->v.effects |= EF_NODRAW;

                     if (g_bWaypointsChanged && g_bWaypointsSaved)
                     {
                        UTIL_HostPrint ("The map will restart in 5 seconds!\n");
                        g_fTimeRestartServer = gpGlobals->time + 4.0;
                     }
                     else if (g_bWaypointsChanged)
                        UTIL_HostPrint ("Don't forget to SAVE your waypoints...\n");
                  }
               }
               else if (FStrEq (arg1, "2"))
               {
                  g_bAutoWaypoint ^= TRUE; // Switch Variable on/off (XOR it)
                  UTIL_HostPrint ("Auto-Waypointing is %s\n", (g_bAutoWaypoint ? "ENABLED" : "DISABLED"));
               }
               else if (FStrEq (arg1, "3"))
               {
                  g_bEditNoclip ^= TRUE; // Switch Variable on/off (XOR it)
                  if (g_bEditNoclip)
                     pHostEdict->v.movetype = MOVETYPE_NOCLIP;
                  else
                     pHostEdict->v.movetype = MOVETYPE_WALK;
                  UTIL_HostPrint ("No Clipping Cheat is %s\n", (g_bEditNoclip ? "ENABLED" : "DISABLED"));
               }
               else if (FStrEq (arg1, "4"))
               {
                  g_bIgnoreEnemies ^= TRUE; // Switch Variable on/off (XOR it)
                  UTIL_HostPrint ("Peace Mode is %s (Bots %signore Enemies)\n", (g_bIgnoreEnemies ? "ENABLED" : "DISABLED"), (g_bIgnoreEnemies ? "" : "DON'T "));
               }
               else if (FStrEq (arg1, "5"))
               {
                  g_bShowWpFlags ^= TRUE; // Switch Variable on/off (XOR it)
                  UTIL_HostPrint ("Waypoint Flag display is %s\n", (g_bShowWpFlags ? "ENABLED" : "DISABLED"));
               }
               else if (FStrEq (arg1, "6"))
                  UTIL_ShowMenu (&menuWpAutoPathMaxDistance);
               else if (FStrEq (arg1, "7"))
                  WaypointCache ();

               RETURN_META (MRES_SUPERCEDE);
            }

            // Waypoint AutoPathMaxDistance Menu 
            else if (pUserMenu == &menuWpAutoPathMaxDistance)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               UTIL_DisplayWpMenuWelcomeMessage ();

               if (FStrEq (arg1, "1"))
               {
                  g_fAutoPathMaxDistance = 0;
                  UTIL_HostPrint ("Auto-path disabled\n");
               }
               else if (FStrEq (arg1, "2"))
               {
                  g_fAutoPathMaxDistance = 100;
                  UTIL_HostPrint ("Auto-path Max Distance set to 100\n");
               }
               else if (FStrEq (arg1, "3"))
               {
                  g_fAutoPathMaxDistance = 130;
                  UTIL_HostPrint ("Auto-path Max Distance set to 130\n");
               }
               else if (FStrEq (arg1, "4"))
               {
                  g_fAutoPathMaxDistance = 160;
                  UTIL_HostPrint ("Auto-path Max Distance set to 160\n");
               }
               else if (FStrEq (arg1, "5"))
               {
                  g_fAutoPathMaxDistance = 190;
                  UTIL_HostPrint ("Auto-path Max Distance set to 190\n");
               }
               else if (FStrEq (arg1, "6"))
               {
                  g_fAutoPathMaxDistance = 220;
                  UTIL_HostPrint ("Auto-path Max Distance set to 220\n");
               }
               else if (FStrEq (arg1, "7"))
               {
                  g_fAutoPathMaxDistance = 250;
                  UTIL_HostPrint ("Auto-path Max Distance set to 250\n");
               }
               else if (FStrEq (arg1, "8"))
               {
                  g_fAutoPathMaxDistance = 400;
                  UTIL_HostPrint ("Auto-path Max Distance set to 400\n");
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Main PODBot Menu ?
            else if (pUserMenu == &menuPODBotMain)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if (FStrEq (arg1, "1"))
                  BotCreate (0, 0, 0, NULL);
               else if (FStrEq (arg1, "2"))
                  UTIL_ShowMenu (&menuPODBotAddBotSkill);
               else if (FStrEq (arg1, "3"))
                  UserKillAllBots ();
               else if (FStrEq (arg1, "4"))
                  UserNewroundAll ();
               else if (FStrEq (arg1, "5"))
                  UTIL_ShowMenu (&menuPODBotFillServer);
               else if (FStrEq (arg1, "6"))
               {
                  for (i = 0; i < gpGlobals->maxClients; i++)
                     if (bots[i].is_used && !FNullEnt (bots[i].pEdict))  // is this slot used?
                     {
                        sprintf (kick_command, "kick \"%s\"\n", STRING (bots[i].pEdict->v.netname));
                        SERVER_COMMAND (kick_command); // kick the bot using (kick "name")
                        break;
                     }
               }
               else if (FStrEq (arg1, "7"))
                  UserRemoveAllBots ();
               else if (FStrEq (arg1, "8"))
                  UTIL_ShowMenu (&menuPODBotWeaponMode);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Bot Skill menu ?
            else if (pUserMenu == &menuPODBotAddBotSkill)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if (FStrEq (arg1, "1"))
               {
                  iStoreAddbotSkill = RANDOM_LONG (0, 20);
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }
               else if (FStrEq (arg1, "2"))
               {
                  iStoreAddbotSkill = RANDOM_LONG (20, 40);
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }
               else if (FStrEq (arg1, "3"))
               {
                  iStoreAddbotSkill = RANDOM_LONG (40, 60);
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }
               else if (FStrEq (arg1, "4"))
               {
                  iStoreAddbotSkill = RANDOM_LONG (60, 80);
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }
               else if (FStrEq (arg1, "5"))
               {
                  iStoreAddbotSkill = RANDOM_LONG (80, 99);
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }
               else if (FStrEq (arg1, "6"))
               {
                  iStoreAddbotSkill = 100;
                  UTIL_ShowMenu (&menuPODBotAddBotTeam);
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Bot Team Select Menu ?
            else if (pUserMenu == &menuPODBotAddBotTeam)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if (FStrEq (arg1, "1"))
               {
                  iStoreAddbotTeam = 1;
                  UTIL_ShowMenu (&menuPODBotAddBotTModel);
               }
               else if (FStrEq (arg1, "2"))
               {
                  iStoreAddbotTeam = 2;
                  UTIL_ShowMenu (&menuPODBotAddBotCTModel);
               }
               else if (FStrEq (arg1, "5"))
               {
                  iStoreAddbotTeam = 5;
                  BotCreate (iStoreAddbotSkill, iStoreAddbotTeam, 5, NULL);
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Model Selection Menu ?
            else if ((pUserMenu == &menuPODBotAddBotTModel)
                     || (pUserMenu == &menuPODBotAddBotCTModel))
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if ((atoi (arg1) >= 1) && (atoi (arg1) <= 5))
                  BotCreate (iStoreAddbotSkill, iStoreAddbotTeam, atoi (arg1), NULL);

               RETURN_META (MRES_SUPERCEDE);
            }

            // Fill Server Menu Select ?
            else if (pUserMenu == &menuPODBotFillServer)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if ((atoi (arg1) == 1) || (atoi (arg1) == 2) || (atoi (arg1) == 5))
               {
                  if (atoi (arg1) != 5)
                  {
                     CVAR_SET_STRING ("mp_limitteams", "0");
                     CVAR_SET_STRING ("mp_autoteambalance", "0");
                  }

                  for (i = 0; i < gpGlobals->maxClients; i++)
                     if (!BotCreateTab[i].bNeedsCreation)
                     {
                        memset (&BotCreateTab[i], 0, sizeof (createbot_t));
                        BotCreateTab[i].bNeedsCreation = TRUE;
                        BotCreateTab[i].bot_team = atoi (arg1);
                     }

                  botcreation_time = gpGlobals->time;
               }

               RETURN_META (MRES_SUPERCEDE);
            }

            // Weapon Mode Selection Menu ?
            else if (pUserMenu == &menuPODBotWeaponMode)
            {
               UTIL_ShowMenu (NULL); // reset menu display

               if ((atoi (arg1) >= 1) && (atoi (arg1) <= 7))
                  UserSelectWeaponMode (atoi (arg1));

               RETURN_META (MRES_SUPERCEDE);
            }
         }

         RETURN_META (MRES_SUPERCEDE);
      }
   }

   // Check Radio Commands
   iClientIndex = ENTINDEX (pEntity) - 1;

   if ((iRadioSelect[iClientIndex] != 0) && FStrEq (pcmd, "menuselect"))
   {
      iRadioCommand = atoi (arg1);

      if (iRadioCommand != 0)
      {
         iRadioCommand += 10 * (iRadioSelect[iClientIndex] - 1);

         if ((iRadioCommand != RADIO_AFFIRMATIVE)
             && (iRadioCommand != RADIO_NEGATIVE)
             && (iRadioCommand != RADIO_REPORTINGIN))
         {
            for (i = 0; i < gpGlobals->maxClients; i++)
            {
               if (bots[i].is_used && (bots[i].bot_team == clients[iClientIndex].iTeam)
                   && (pEntity != bots[i].pEdict))
               {
                  if (bots[i].iRadioOrder == 0)
                  {
                     bots[i].iRadioOrder = iRadioCommand;
                     bots[i].pRadioEntity = pEntity;
                  }
               }
            }
         }

         g_rgfLastRadioTime[clients[iClientIndex].iTeam - 1] = gpGlobals->time;
      }

      iRadioSelect[iClientIndex] = 0;
   }

   else if (strncmp (pcmd, "radio", 5) == 0)
      iRadioSelect[iClientIndex] = atoi (pcmd + 5);
   // End Radio Commands

   RETURN_META (MRES_IGNORED);
}


void ServerActivate (edict_t *pEdictList, int edictCount, int clientMax)
{
   FILE *fp;
   char line_buffer[256];
   int i, c;
   int iChatType;
   replynode_t *pTempReply = NULL;
   replynode_t **pReply;
   char arg0[80];
   char arg1[80];
   int *ptrWeaponPrefs;
   int iParseWeapons;
   int iWeaponPrefsType;
   char *pszStart;
   char *pszEnd;
   STRINGNODE **pNode;
   STRINGNODE *pTempNode;

   // Load & Initialise Botnames from 'Botnames.txt'
   fp = fopen ("cstrike/addons/podbot/botnames.txt", "r");
   if (fp == NULL)
      UTIL_ServerPrint ("POD-Bot couldn't find botnames.txt!\n");
   else
   {
      memset (szBotNames, 0, sizeof (szBotNames));
      iNumBotNames = 0;

      while (fgets (line_buffer, 256, fp) != NULL)
      {
         if ((line_buffer[0] == '#') || (line_buffer[0] == 0) || (line_buffer[0] == '\r') || (line_buffer[0] == '\n'))
            continue; // ignore comments or blank lines

         i = strlen (line_buffer);
         if (line_buffer[i - 1] == '\n')
            line_buffer[i - 1] = 0;
         line_buffer[21] = 0;
   
         strcpy (szBotNames[iNumBotNames], line_buffer);
         iNumBotNames++;
      }

      fclose (fp);
   }
   // End Botnames

   // Load & Initialise Botchats from 'Botchat.txt'
   fp = fopen ("cstrike/addons/podbot/botchat.txt", "r");
   if (fp == NULL)
      UTIL_ServerPrint ("POD-Bot couldn't find botchat.txt!\n");
   else
   {
      memset (szKillChat, 0, sizeof (szKillChat));
      memset (szBombChat, 0, sizeof (szKillChat));
      memset (szDeadChat, 0, sizeof (szKillChat));
      memset (szNoKwChat, 0, sizeof (szKillChat));
      iNumKillChats = 0;
      iNumBombChats = 0;
      iNumDeadChats = 0;
      iNumNoKwChats = 0;

      iChatType = -1;

      while (fgets (line_buffer, 256, fp) != NULL)
      {
         if ((line_buffer[0] == '#') || (line_buffer[0] == 0) || (line_buffer[0] == '\r') || (line_buffer[0] == '\n'))
            continue; // ignore comments or blank lines

         strcpy (arg0, GetField (line_buffer, 0));

         // Killed Chat Section ?
         if (FStrEq (arg0, "[KILLED]"))
         {
            iChatType = 0;
            continue;
         }

         // Bomb Chat Section ?
         else if (FStrEq (arg0, "[BOMBPLANT]"))
         {
            iChatType = 1;
            continue;
         }

         // Dead Chat Section ?
         else if (FStrEq (arg0, "[DEADCHAT]"))
         {
            iChatType = 2;
            continue;
         }

         // Keyword Chat Section ?
         else if (FStrEq (arg0, "[REPLIES]"))
         {
            iChatType = 3;
            pReply = &pChatReplies;
            continue;
         }

         // Unknown Keyword Section ?
         else if (FStrEq (arg0, "[UNKNOWN]"))
         {
            iChatType = 4;
            continue;
         }

         if (iChatType == 0)
         {
            strcat (line_buffer, "\n");
            line_buffer[79] = 0;

            strcpy (szKillChat[iNumKillChats], line_buffer);
            iNumKillChats++;
         }

         else if (iChatType == 1)
         {
            strcat (line_buffer, "\n");
            line_buffer[79] = 0;

            strcpy (szBombChat[iNumBombChats], line_buffer);
            iNumBombChats++;
         }

         else if (iChatType == 2)
         {
            strcat (line_buffer, "\n");
            line_buffer[79] = 0;

            strcpy (szDeadChat[iNumDeadChats], line_buffer);
            iNumDeadChats++;
         }

         else if (iChatType == 3)
         {
            if (strstr (line_buffer, "@KEY") != NULL)
            {
               pTempReply = new replynode_t;
               *pReply = pTempReply;
               pTempReply->pNextReplyNode = NULL;
               pTempReply->pReplies = NULL;
               pTempReply->cNumReplies = 0;
               pTempReply->cLastReply = 0;
               pNode = &pTempReply->pReplies;
               pTempNode = NULL;
               memset (pTempReply->szKeywords, 0, sizeof (pTempReply->szKeywords));

               c = 0;

               for (i = 0; i < 256; i++)
               {
                  if (line_buffer[i] == '\"')
                  {
                     i++;
                     while (line_buffer[i] != '\"')
                        pTempReply->szKeywords[c++] = line_buffer[i++];
                     pTempReply->szKeywords[c++] = '@';
                  }
                  else if (line_buffer[i] == 0)
                     break;
               }
               pReply = &pTempReply->pNextReplyNode;
            }
            else if (pTempReply)
            {
               strcat (line_buffer, "\n");
               line_buffer[255] = 0;

               pTempNode = new STRINGNODE;
               if (pTempNode == NULL)
                  UTIL_ServerPrint ("POD-Bot out of Memory!\n");
               else
               {
                  *pNode = pTempNode;
                  pTempNode->Next = NULL;
                  strcpy (pTempNode->szString, line_buffer);

                  pTempReply->cNumReplies++;
                  pNode = &pTempNode->Next;
               }
            }
         }

         else if (iChatType == 4)
         {
            strcat (line_buffer, "\n");
            line_buffer[79] = 0;

            strcpy (szNoKwChat[iNumNoKwChats], line_buffer);
            iNumNoKwChats++;
         }
      }

      fclose (fp);
   }
   // End Botchats

   // Load & Initialise Botskill.cfg
   fp = fopen ("cstrike/addons/podbot/botskill.cfg", "r");
   if (fp == NULL)
      UTIL_ServerPrint ("No Botskill.cfg ! Using defaults...\n");
   else
   {
      i = 0;

      while (fgets (line_buffer, 256, fp) != NULL)
      {
         if ((line_buffer[0] == '#') || (line_buffer[0] == 0) || (line_buffer[0] == '\r') || (line_buffer[0] == '\n'))
            continue; // ignore comments or blank lines

         strcpy (arg0, GetField (line_buffer, 0));
         strcpy (arg1, GetField (line_buffer, 1));

         if (FStrEq (arg0, "MIN_DELAY"))
            BotSkillDelays[i].fMinSurpriseDelay = (float) atof (arg1);
         else if (FStrEq (arg0, "MAX_DELAY"))
            BotSkillDelays[i].fMaxSurpriseDelay = (float) atof (arg1);
         else if (FStrEq (arg0, "HEADSHOT_ALLOW"))
            BotAimTab[i].iHeadShot_Frequency = atoi (arg1);
         else if (FStrEq (arg0, "HEAR_SHOOTTHRU"))
            BotAimTab[i].iHeardShootThruProb = atoi (arg1);
         else if (FStrEq (arg0, "SEEN_SHOOTTHRU"))
         {
            BotAimTab[i].iSeenShootThruProb = atoi (arg1);

            if (i < 5)
               i++; // Prevent Overflow if Errors in cfg
         }
      }

      fclose (fp);
   }
   // End Botskill.cgf

   // Load & Initialise BotLogos from BotLogos.cfg
   fp = fopen ("cstrike/addons/podbot/botlogos.cfg", "r");
   if (fp == NULL)
      UTIL_ServerPrint ("No BotLogos.cfg ! Using Defaults...\n");
   else
   {
      g_iNumLogos = 0;

      while (fgets (line_buffer, 256, fp) != NULL)
      {
         if ((line_buffer[0] == '#') || (line_buffer[0] == 0) || (line_buffer[0] == '\r') || (line_buffer[0] == '\n'))
            continue; // ignore comments or blank lines

         strcpy (szSprayNames[g_iNumLogos], GetField (line_buffer, 0));
         g_iNumLogos++;
      }

      fclose (fp);
   }
   // End BotLogos

   // Load & initialise Weapon Stuff from 'BotWeapons.cfg'
   fp = fopen ("cstrike/addons/podbot/botweapons.cfg", "r");
   if (fp == NULL)
      UTIL_ServerPrint ("No BotWeapons.cfg ! Using Defaults...\n");
   else
   {
      iParseWeapons = 0;
      ptrWeaponPrefs = NULL;

      while (fgets (line_buffer, 256, fp) != NULL)
      {
         if ((line_buffer[0] == '#') || (line_buffer[0] == 0) || (line_buffer[0] == '\r') || (line_buffer[0] == '\n'))
            continue; // ignore comments or blank lines

         strcpy (arg0, GetField (line_buffer, 0));

         if (iParseWeapons < 2)
         {
            if (FStrEq (arg0, "[STANDARD]"))
               iWeaponPrefsType = MAP_DE;
            else if (FStrEq (arg0, "[AS]"))
               iWeaponPrefsType = MAP_AS;
            else
            {
               pszStart = &line_buffer[0];
               pszEnd = NULL;

               if (iWeaponPrefsType == MAP_DE)
               {
                  for (i = 0; i < NUM_WEAPONS; i++)
                  {
                     pszEnd = strchr (pszStart, ',');
                     cs_weapon_select[i].iTeamStandard = atoi (pszStart);
                     pszStart = pszEnd + 1;
                  }
               }
               else
               {
                  for (i = 0; i < NUM_WEAPONS; i++)
                  {
                     pszEnd = strchr (pszStart, ',');
                     cs_weapon_select[i].iTeamAS = atoi (pszStart);
                     pszStart = pszEnd + 1;
                  }
               }

               iParseWeapons++;
            }
         }
         else
         {
            if (FStrEq (arg0, "[NORMAL]"))
               ptrWeaponPrefs = &NormalWeaponPrefs[0];
            else if (FStrEq (arg0, "[AGRESSIVE]"))
               ptrWeaponPrefs = &AgressiveWeaponPrefs[0];
            else if (FStrEq (arg0, "[DEFENSIVE]"))
               ptrWeaponPrefs = &DefensiveWeaponPrefs[0];
            else
            {
               pszStart = &line_buffer[0];

               for (i = 0; i < NUM_WEAPONS; i++)
               {
                  pszEnd = strchr (pszStart, ',');
                  *ptrWeaponPrefs++ = atoi (pszStart);
                  pszStart = pszEnd + 1;
               }
            }
         }
      }

      fclose (fp);
   }

   // Load the Waypoints for this Map
   WaypointLoad ();
   InitVisTab ();
   InitExperienceTab ();

   // Initialise the Client Struct for welcoming and keeping track who's connected
   memset (clients, 0, sizeof (clients));

   // Initialize the bots array of structures
   memset (bots, 0, sizeof (bots));

   // open the bot config file
   file_opened = FALSE;
   g_GameRules = TRUE;

   // a new map has started...
   botcreation_time = gpGlobals->time + 5.0;

   // set the respawn time
   g_fTimeRoundStart = gpGlobals->time + CVAR_GET_FLOAT ("mp_freezetime");

   RETURN_META (MRES_IGNORED);
}


void ServerDeactivate (void)
{
   int index;
   int tab_index;

   tab_index = 0;
   for (index = 0; index < gpGlobals->maxClients; index++)
      if (bots[index].is_used)
      {
         BotCreateTab[tab_index].bNeedsCreation = TRUE;
         strcpy (BotCreateTab[tab_index].bot_name, bots[index].name);
         BotCreateTab[tab_index].bot_skill = bots[index].bot_skill;
         BotCreateTab[tab_index].bot_team = bots[index].bot_team;
         BotCreateTab[tab_index].bot_class = bots[index].bot_class;
         tab_index++;
      }

   // Save collected Experience on Shutdown
   SaveExperienceTab ();
   SaveVisTab ();

   // Free everything that's freeable
   BotFreeAllMemory ();

   RETURN_META (MRES_IGNORED);
}


// Called each Server frame at the very beginning
void StartFrame (void)
{
   edict_t *pPlayer;
   static int i, player_index, bot_index;
   static FILE *bot_cfg_fp = NULL;
   static char cmd_line[1024];
   static char cmd[128];
   static char arg1[128];
   static char arg2[128];
   static char arg3[128];
   static char arg4[128];
   static float pause_time;

   // Should the Map restart now ?
   if ((g_fTimeRestartServer > 0) && (g_fTimeRestartServer < gpGlobals->time))
   {
      g_fTimeRestartServer = 0; // don't keep restarting over and over again
      SERVER_COMMAND ("restart\n"); // restart the map
   }

   // Record some Stats of all Players on the Server
   for (player_index = 0; player_index < gpGlobals->maxClients; player_index++)
   {
      pPlayer = INDEXENT (player_index + 1);

      if (!FNullEnt (pPlayer) && (pPlayer->v.flags & FL_CLIENT))
      {
         clients[player_index].pEdict = pPlayer;
         clients[player_index].IsUsed = TRUE;
         clients[player_index].IsAlive = IsAlive (pPlayer);

         if (clients[player_index].IsAlive)
         {
            clients[player_index].iTeam = UTIL_GetTeam (pPlayer);
            clients[player_index].vOrigin = pPlayer->v.origin;
            SoundSimulateUpdate (player_index);
         }

         // Does Client need to be shocked by the ugly red welcome message ?
         if ((clients[player_index].welcome_time > 0) && (clients[player_index].welcome_time < gpGlobals->time))
         {
            // Real Clients only
            if (!(pPlayer->v.flags & FL_FAKECLIENT))
            {
               // Hacked together Version of HUD_DrawString
               MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, NULL, pPlayer);
               WRITE_BYTE (TE_TEXTMESSAGE);
               WRITE_BYTE (1);
               WRITE_SHORT (FixedSigned16 (-1, 1 << 13));
               WRITE_SHORT (FixedSigned16 (0, 1 << 13));
               WRITE_BYTE (2);
               WRITE_BYTE (255);
               WRITE_BYTE (0);
               WRITE_BYTE (0);
               WRITE_BYTE (0);
               WRITE_BYTE (255);
               WRITE_BYTE (255);
               WRITE_BYTE (255);
               WRITE_BYTE (200);
               WRITE_SHORT (FixedUnsigned16 (0.0078125, 1 << 8));
               WRITE_SHORT (FixedUnsigned16 (2, 1 << 8));
               WRITE_SHORT (FixedUnsigned16 (6, 1 << 8));
               WRITE_SHORT (FixedUnsigned16 (0.1, 1 << 8));
               WRITE_STRING (szWelcomeMessage);
               MESSAGE_END ();

               // If this is the Host, scare him even more with a spoken Message
               if (g_bUseSpeech && (pPlayer == pHostEdict))
                  SERVER_COMMAND ((char *) &szSpeechSentences[RANDOM_LONG (0, 15)]);
            }

            clients[player_index].welcome_time = 0.0;
         }

         // Does Client need to be shocked by the ugly yellow waypoint message ?
         if ((clients[player_index].wptmessage_time > 0) && (clients[player_index].wptmessage_time < gpGlobals->time)
             && !(pPlayer->v.flags & FL_SPECTATOR))
         {
            // Real Clients only
            if (!(pPlayer->v.flags & FL_FAKECLIENT))
            {
               if (GET_USER_MSG_ID (PLID, "TextMsg", NULL) == 0)
                  REG_USER_MSG ("TextMsg", -1);

               MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, GET_USER_MSG_ID (PLID, "TextMsg", NULL), NULL, pPlayer);
               WRITE_BYTE (HUD_PRINTCENTER);
               WRITE_STRING (g_szWaypointMessage);
               MESSAGE_END ();
            }

            clients[player_index].wptmessage_time = 0.0;
         }
      }
      else
      {
         clients[player_index].pEdict = NULL;
         clients[player_index].IsUsed = FALSE;
         clients[player_index].IsAlive = FALSE;
      }
   }

   // Estimate next Frame's duration
   EstimateNextFrameDuration ();

   // Go through all active Bots, calling their Think fucntion
   num_bots = 0;
   for (bot_index = 0; bot_index < gpGlobals->maxClients; bot_index++)
   {
      if (bots[bot_index].is_used
          && !FNullEnt (bots[bot_index].pEdict))
      {
         BotThink (&bots[bot_index]);
         num_bots++;
      }
   }

   // Show Waypoints to host if turned on and no dedicated Server
   if (!g_bIsDedicatedServer && g_bWaypointOn && !FNullEnt (pHostEdict))
      WaypointThink ();

   if (g_bMapInitialised && g_bRecalcVis)
      WaypointCalcVisibility ();

   // are we currently spawning bots and is it time to spawn one yet?
   if ((botcreation_time > 0) && (botcreation_time < gpGlobals->time))
   {
      // find bot needing to be spawned...
      for (bot_index = 0; bot_index < gpGlobals->maxClients; bot_index++)
         if (BotCreateTab[bot_index].bNeedsCreation)
            break;

      if (bot_index < gpGlobals->maxClients)
      {
         BotCreate (BotCreateTab[bot_index].bot_skill, BotCreateTab[bot_index].bot_team, BotCreateTab[bot_index].bot_class, BotCreateTab[bot_index].bot_name);
         BotCreateTab[bot_index].bNeedsCreation = FALSE;
         botcreation_time = gpGlobals->time + 0.5; // set next spawn time
      }
      else if (num_bots < min_bots)
      {
         BotCreate (0, 0, 0, NULL);
         botcreation_time = gpGlobals->time + 0.5; // set next spawn time
      }
      else
         botcreation_time = 0.0;
   }

  // Executing the .cfg file - most work already done by Botman
  // Command Names are the same as in ClientCommand
  if (g_GameRules)
  {
      if (!file_opened)  // have we open podbot.cfg file yet?
      {
         UTIL_ServerPrint ("Executing podbot.cfg\n");

         bot_cfg_fp = fopen ("cstrike/addons/podbot/podbot.cfg", "r");
         if (bot_cfg_fp == NULL)
            UTIL_ServerPrint ("podbot.cfg File not found\n");

         file_opened = TRUE;
         pause_time = gpGlobals->time;
      }

      // if the bot.cfg file is still open and time to execute command...
      while ((bot_cfg_fp != NULL) && !feof (bot_cfg_fp) && (pause_time < gpGlobals->time))
      {
         if (fgets (cmd_line, 1024, bot_cfg_fp) != NULL)
         {
            if ((cmd_line[0] == '#') || (cmd_line[0] == '\r') || (cmd_line[0] == '\n') || (cmd_line[0] == 0))
               continue; // ignore comments or blank lines

            sprintf (cmd, GetField (cmd_line, 0));
            sprintf (arg1, GetField (cmd_line, 1));
            sprintf (arg2, GetField (cmd_line, 2));
            sprintf (arg3, GetField (cmd_line, 3));
            sprintf (arg4, GetField (cmd_line, 4));

            if (FStrEq (cmd, CONSOLE_CMD_PAUSE))
            {
               pause_time = gpGlobals->time + atoi (arg1);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_ADDBOT))
            {
               // check if some bots are already marked for respawn
               for (bot_index = 0; bot_index < gpGlobals->maxClients; bot_index++)
                  if (BotCreateTab[bot_index].bNeedsCreation)
                     break;

               // add bots through config file only if no bots are marked for respawn
               if (bot_index == gpGlobals->maxClients)
               {
                  BotCreate (atoi (arg1), atoi (arg2), atoi (arg3), arg4);
                  pause_time = gpGlobals->time + 0.5;
               }
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MINBOTS))
            {
               min_bots = atoi (arg1);
               if (min_bots < 0)
                  min_bots = 0;
               if (min_bots > max_bots)
                  min_bots = max_bots;

               UTIL_ServerPrint ("min_bots set to %d\n", min_bots);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MAXBOTS))
            {
               max_bots = atoi (arg1);
               if (max_bots > 32)
                  max_bots = 32;
               if (max_bots < min_bots)
                  max_bots = min_bots;

               UTIL_ServerPrint ("max_bots set to %d\n", max_bots);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MINBOTSKILL))
            {
               g_iMinBotSkill = atoi (arg1);
               if (g_iMinBotSkill < 1)
                  g_iMinBotSkill = 1;
               if (g_iMinBotSkill > g_iMaxBotSkill)
                  g_iMinBotSkill = g_iMaxBotSkill;

               UTIL_ServerPrint ("MinBotSkill set to %d\n", g_iMinBotSkill);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MAXBOTSKILL))
            {
               g_iMaxBotSkill = atoi (arg1);
               if (g_iMaxBotSkill > 100)
                  g_iMaxBotSkill = 100;
               if (g_iMaxBotSkill < g_iMinBotSkill)
                  g_iMaxBotSkill = g_iMinBotSkill;

               UTIL_ServerPrint ("MaxBotSkill set to %d\n", g_iMaxBotSkill);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_BOTCHAT))
            {
               if (FStrEq (arg1, "on"))
                  g_bBotChat = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bBotChat = FALSE;

               UTIL_ServerPrint ("BotChat turned %s\n", (g_bBotChat ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_JASONMODE))
            {
               if (FStrEq (arg1, "on"))
                  g_bJasonMode = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bJasonMode = FALSE;

               UTIL_ServerPrint ("JasonMode turned %s\n", (g_bJasonMode ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_WPTFOLDER))
            {
               strcpy (g_szWPTDirname, arg1);

               UTIL_ServerPrint ("Waypoint Folder set to '%s'\n", g_szWPTDirname);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_DETAILNAMES))
            {
               if (FStrEq (arg1, "on"))
                  g_bDetailNames = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bDetailNames = FALSE;

               UTIL_ServerPrint ("DetailedNames turned %s\n", (g_bDetailNames ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_INHUMANTURNS))
            {
               if (FStrEq (arg1, "on"))
                  g_bInstantTurns = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bInstantTurns = FALSE;

               UTIL_ServerPrint ("Inhumanturns turned %s\n", (g_bInstantTurns ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MAXBOTSFOLLOW))
            {
               g_iMaxNumFollow = atoi (arg1);
               if (g_iMaxNumFollow < 0)
                  g_iMaxNumFollow = 3;

               UTIL_ServerPrint ("Max. Number of Bots following set to: %d\n", g_iMaxNumFollow);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_MAXWEAPONPICKUP))
            {
               g_iMaxWeaponPickup = atoi (arg1);
               if (g_iMaxWeaponPickup < 0)
                  g_iMaxWeaponPickup = 1;

               UTIL_ServerPrint ("Bots pickup a maximum of %d weapons\n", g_iMaxWeaponPickup);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_COLLECTEXP))
            {
               if (FStrEq (arg1, "on"))
                  g_bUseExperience = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bUseExperience = FALSE;

               UTIL_ServerPrint ("Experience Collection turned %s\n", (g_bUseExperience ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_SHOOTTHRU))
            {
               if (FStrEq (arg1, "on"))
                  g_bShootThruWalls = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bShootThruWalls = FALSE;

               UTIL_ServerPrint ("Shooting thru Walls turned %s\n", (g_bShootThruWalls ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_TIMESOUND))
            {
               g_fTimeSoundUpdate = atof (arg1);
               if (g_fTimeSoundUpdate < 0.1)
                  g_fTimeSoundUpdate = 0.1;

               UTIL_ServerPrint ("Sound Update Timer set to %f secs\n", g_fTimeSoundUpdate);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_TIMEPICKUP))
            {
               g_fTimeSoundUpdate = atof (arg1);
               if (g_fTimePickupUpdate < 0.1)
                  g_fTimePickupUpdate = 0.1;

               UTIL_ServerPrint ("Pickup Update Timer set to %f secs\n", g_fTimePickupUpdate);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_TIMEGRENADE))
            {
               g_fTimeGrenadeUpdate = atof (arg1);
               if (g_fTimeGrenadeUpdate < 0.1)
                  g_fTimeGrenadeUpdate = 0.1;

               UTIL_ServerPrint ("Grenade Check Timer set to %f secs\n", g_fTimeGrenadeUpdate);
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_SPEECH))
            {
               if (FStrEq (arg1, "on"))
                  g_bUseSpeech = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bUseSpeech = FALSE;

               UTIL_ServerPrint ("POD Speech turned %s\n", (g_bUseSpeech ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_ALLOWSPRAY))
            {
               if (FStrEq (arg1, "on"))
                  g_bBotSpray = TRUE;
               else if (FStrEq (arg1, "off"))
                  g_bBotSpray = FALSE;

               UTIL_ServerPrint ("Bot Logo spraying turned %s\n", (g_bBotSpray ? "on" : "off"));
               break;
            }
            else if (FStrEq (cmd, CONSOLE_CMD_DANGERFACTOR))
            {
               g_iDangerFactor = atoi (arg1);
               if (g_iDangerFactor < 1)
                  g_iDangerFactor = 1;

               UTIL_ServerPrint ("Pathfinder danger factor set to %d\n", g_iDangerFactor);
               break;
            }
            else
            {
               UTIL_ServerPrint ("executing server command: %s\n", cmd_line);

               SERVER_COMMAND (cmd_line);
               break;
            }
         }
      }

      // if bot.cfg file is open and reached end of file, then close and free it
      if ((bot_cfg_fp != NULL) && feof (bot_cfg_fp))
      {
         fclose (bot_cfg_fp);
         bot_cfg_fp = NULL;
         g_GameRules = FALSE;

         // print the waypoint message to console
         UTIL_ServerPrint (g_szWaypointMessage);
      }
   }

   previous_time = gpGlobals->time;

   RETURN_META (MRES_IGNORED);
}


void FakeClientCommand (edict_t *pFakeClient, const char *fmt, ...)
{
   // the purpose of this function is to provide fakeclients (bots) with the same client
   // command-scripting advantages (putting multiple commands in one line between semicolons)
   // as real players. It is an improved version of botman's FakeClientCommand, in which you
   // supply directly the whole string as if you were typing it in the bot's "console". It
   // is supposed to work exactly like the pfnClientCommand (server-sided client command).

   va_list argptr;
   static char command[256];
   int length, fieldstart, fieldstop, i, index, stringindex = 0;
   int iClientIndex;
   int iRadioCommand;

   if (FNullEnt (pFakeClient))
      return; // reliability check

   // concatenate all the arguments in one string
   va_start (argptr, fmt);
   vsprintf (command, fmt, argptr);
   va_end (argptr);

   if ((command == NULL) || (*command == 0))
      return; // if nothing in the command buffer, return

   isFakeClientCommand = TRUE; // set the "fakeclient command" flag
   length = strlen (command); // get the total length of the command string

   // process all individual commands (separated by a semicolon) one each a time
   while (stringindex < length)
   {
      fieldstart = stringindex; // save field start position (first character)
      while ((stringindex < length) && (command[stringindex] != ';'))
         stringindex++; // reach end of field
      if (command[stringindex - 1] == '\n')
         fieldstop = stringindex - 2; // discard any trailing '\n' if needed
      else
         fieldstop = stringindex - 1; // save field stop position (last character before semicolon or end)
      for (i = fieldstart; i <= fieldstop; i++)
         g_argv[i - fieldstart] = command[i]; // store the field value in the g_argv global string
      g_argv[i - fieldstart] = 0; // terminate the string
      stringindex++; // move the overall string index one step further to bypass the semicolon

      index = 0;
      fake_arg_count = 0; // let's now parse that command and count the different arguments

      // count the number of arguments
      while (index < i - fieldstart)
      {
         while ((index < i - fieldstart) && (g_argv[index] == ' '))
            index++; // ignore spaces

         // is this field a group of words between quotes or a single word ?
         if (g_argv[index] == '"')
         {
            index++; // move one step further to bypass the quote
            while ((index < i - fieldstart) && (g_argv[index] != '"'))
               index++; // reach end of field
            index++; // move one step further to bypass the quote
         }
         else
            while ((index < i - fieldstart) && (g_argv[index] != ' '))
               index++; // this is a single word, so reach the end of field

         fake_arg_count++; // we have processed one argument more
      }

      // Check Radio Commands (fix): do it here since metamod won't call our own ClientCommand()
      iClientIndex = ENTINDEX (pFakeClient) - 1;

      if ((iRadioSelect[iClientIndex] != 0) && (strncmp (g_argv, "menuselect", 10) == 0))
      {
         iRadioCommand = atoi (g_argv + 11);

         if (iRadioCommand != 0)
         {
            iRadioCommand += 10 * (iRadioSelect[iClientIndex] - 1);

            if ((iRadioCommand != RADIO_AFFIRMATIVE)
                && (iRadioCommand != RADIO_NEGATIVE)
                && (iRadioCommand != RADIO_REPORTINGIN))
            {
               for (i = 0; i < gpGlobals->maxClients; i++)
               {
                  if (bots[i].is_used && (bots[i].bot_team == clients[iClientIndex].iTeam)
                      && (pFakeClient != bots[i].pEdict))
                  {
                     if (bots[i].iRadioOrder == 0)
                     {
                        bots[i].iRadioOrder = iRadioCommand;
                        bots[i].pRadioEntity = pFakeClient;
                     }
                  }
               }
            }

            g_rgfLastRadioTime[clients[iClientIndex].iTeam - 1] = gpGlobals->time;
         }

         iRadioSelect[iClientIndex] = 0;
      }
      else if (strncmp (g_argv, "radio", 5) == 0)
         iRadioSelect[iClientIndex] = atoi (g_argv + 5);

      // End Radio Commands

      MDLL_ClientCommand (pFakeClient); // tell now the MOD DLL to execute this ClientCommand...
   }

   g_argv[0] = 0; // when it's done, reset the g_argv field
   isFakeClientCommand = FALSE; // reset the "fakeclient command" flag
   fake_arg_count = 0; // and the argument count
}


const char *GetField (const char *string, int field_number)
{
   // This function gets and returns a particuliar field in a string where several fields are
   // concatenated. Fields can be words, or groups of words between quotes ; separators may be
   // white space or tabs. A purpose of this function is to provide bots with the same Cmd_Argv
   // convenience the engine provides to real clients. This way the handling of real client
   // commands and bot client commands is exactly the same, just have a look in engine.cpp
   // for the hooking of pfnCmd_Argc, pfnCmd_Args and pfnCmd_Argv, which redirects the call
   // either to the actual engine functions (when the caller is a real client), either on
   // our function here, which does the same thing, when the caller is a bot.

   static char field[256];
   int length, i, index = 0, field_count = 0, fieldstart, fieldstop;

   field[0] = 0; // reset field
   length = strlen (string); // get length of string

   while ((length > 0) && ((string[length - 1] == '\n') || (string[length - 1] == '\r')))
      length--; // discard trailing newlines

   // while we have not reached end of line
   while ((index < length) && (field_count <= field_number))
   {
      while ((index < length) && ((string[index] == ' ') || (string[index] == '\t')))
         index++; // ignore spaces or tabs

      // is this field multi-word between quotes or single word ?
      if (string[index] == '"')
      {
         index++; // move one step further to bypass the quote
         fieldstart = index; // save field start position
         while ((index < length) && (string[index] != '"'))
            index++; // reach end of field
         fieldstop = index - 1; // save field stop position
         index++; // move one step further to bypass the quote
      }
      else
      {
         fieldstart = index; // save field start position
         while ((index < length) && ((string[index] != ' ') && (string[index] != '\t')))
            index++; // reach end of field
         fieldstop = index - 1; // save field stop position
      }

      // is this field we just processed the wanted one ?
      if (field_count == field_number)
      {
         for (i = fieldstart; i <= fieldstop; i++)
            field[i - fieldstart] = string[i]; // store the field value in a string
         field[i - fieldstart] = 0; // terminate the string
         break; // and stop parsing
      }

      field_count++; // we have parsed one field more
   }

   return (&field[0]); // returns the wanted field
}


void PODBot_ServerCommand (void)
{
   // This is cleaner than polling a CVAR, eh ? :) -- PM

   char servercmd[40];
   int index;
   int iSelection;

   if (FStrEq (CMD_ARGV (1), CONSOLE_CMD_ADDBOT))
   {
      UTIL_ServerPrint ("Adding new bot...\n");
      BotCreate (atoi (CMD_ARGV (2)), atoi (CMD_ARGV (3)), atoi (CMD_ARGV (4)), CMD_ARGV (5));
   }
   else if (FStrEq (CMD_ARGV (1), CONSOLE_CMD_REMOVEALLBOTS))
   {
      for (index = 0; index < gpGlobals->maxClients; index++)
      {
         if (bots[index].is_used && !FNullEnt (bots[index].pEdict))  // is this slot used?
         {
            sprintf (servercmd, "kick \"%s\"\n", STRING (bots[index].pEdict->v.netname));
            SERVER_COMMAND (servercmd); // kick the bot using (kick "name")
         }
      }
      UTIL_ServerPrint ("All Bots removed !\n");
   }
   else if (FStrEq (CMD_ARGV (1), CONSOLE_CMD_KILLALLBOTS))
   {
      for (index = 0; index < gpGlobals->maxClients; index++)
      {
         if (bots[index].is_used && !bots[index].bDead && !FNullEnt (bots[index].pEdict))
         {
            bots[index].pEdict->v.frags++;
            MDLL_ClientKill (bots[index].pEdict);
         }
      }
      UTIL_ServerPrint ("All Bots killed !\n");
   }
   else if (FStrEq (CMD_ARGV (1), "fillserver"))
   {
      if ((CMD_ARGV (2) != NULL) && (*CMD_ARGV (2) != 0))
         iSelection = atoi (CMD_ARGV (2));

      if ((iSelection == 1) || (iSelection == 2))
      {
         CVAR_SET_STRING ("mp_limitteams", "0");
         CVAR_SET_STRING ("mp_autoteambalance", "0");
      }
      else
         iSelection = 5;

      for (index = 0; index < gpGlobals->maxClients; index++)
      {
         if (!BotCreateTab[index].bNeedsCreation)
         {
            memset (&BotCreateTab[index], 0, sizeof (createbot_t));
            BotCreateTab[index].bot_team = iSelection;
            BotCreateTab[index].bNeedsCreation = TRUE;
         }
      }

      botcreation_time = gpGlobals->time;
   }
}


C_DLLEXPORT int GetEntityAPI2 (DLL_FUNCTIONS *pFunctionTable, int *interfaceVersion)
{
   gFunctionTable.pfnGameInit = GameDLLInit;
   gFunctionTable.pfnSpawn = Spawn;
   gFunctionTable.pfnClientConnect = ClientConnect;
   gFunctionTable.pfnClientDisconnect = ClientDisconnect;
   gFunctionTable.pfnClientPutInServer = ClientPutInServer;
   gFunctionTable.pfnClientCommand = ClientCommand;
   gFunctionTable.pfnServerActivate = ServerActivate;
   gFunctionTable.pfnServerDeactivate = ServerDeactivate;
   gFunctionTable.pfnStartFrame = StartFrame;

   memcpy (pFunctionTable, &gFunctionTable, sizeof (DLL_FUNCTIONS));
   return (TRUE);
}


C_DLLEXPORT int GetEntityAPI2_Post (DLL_FUNCTIONS *pFunctionTable, int *interfaceVersion)
{
   gFunctionTable_Post.pfnSpawn = Spawn_Post;

   memcpy (pFunctionTable, &gFunctionTable_Post, sizeof (DLL_FUNCTIONS));
   return (TRUE);
}
