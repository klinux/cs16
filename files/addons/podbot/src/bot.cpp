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
// bot.cpp
//
// Features the core AI of the bot

#include "bot_globals.h"


void EstimateNextFrameDuration (void)
{
   // Rich 'TheFatal' Whitehouse's method for computing the msec value

   if (msecdel <= gpGlobals->time)
   {
      if (msecnum > 0)
         msecval = 450.0 / msecnum;

      msecdel = gpGlobals->time + 0.5; // next check in half a second
      msecnum = 0;
   }
   else
      msecnum++;

   if (msecval < 1)
      msecval = 1; // don't allow the msec delay to be null
   else if (msecval > 100)
      msecval = 100; // don't allow it to last longer than 100 milliseconds either

   return;
}


void BotSpawnInit (bot_t *pBot)
{
   // Initialises a Bot after Creation & at the start of each Round

   int i;

   // Delete all allocated Path Nodes
   DeleteSearchNodes (pBot);

   pBot->wpt_origin = g_vecZero;
   pBot->dest_origin = g_vecZero;
   pBot->curr_wpt_index = -1;
   pBot->curr_travel_flags = 0;
   pBot->bJumpDone = FALSE;
   pBot->vecDesiredVelocity = g_vecZero;
   pBot->prev_goal_index = -1;
   pBot->chosengoal_index = -1;
   pBot->prev_wpt_index[0] = -1;
   pBot->prev_wpt_index[1] = -1;
   pBot->prev_wpt_index[2] = -1;
   pBot->prev_wpt_index[3] = -1;
   pBot->prev_wpt_index[4] = -1;
   pBot->f_wpt_timeset = 0;

   switch (pBot->bot_personality)
   {
   case 0: // Normal
      if (RANDOM_LONG (1, 100) > 50)
         pBot->byPathType = 1;
      else
         pBot->byPathType = 2;
      break;
   case 1: // Psycho
      pBot->byPathType = 0;
      break;
   case 2: // Coward
      pBot->byPathType = 2;
      break;
   }

   // Clear all States & Tasks
   pBot->iStates = 0;
   BotResetTasks (pBot);

   pBot->bCheckMyTeam = TRUE;

   pBot->bIsVIP = FALSE;
   pBot->bIsLeader = FALSE;
   pBot->fTimeTeamOrder = 0.0;

   pBot->fMinSpeed = 260.0;
   pBot->prev_speed = 0.0; // fake "paused" since bot is NOT stuck
   pBot->v_prev_origin = Vector (9999.0, 9999.0, 9999.0);
   pBot->prev_time = gpGlobals->time;

   pBot->bCanDuck = FALSE;
   pBot->f_view_distance = 4096.0;
   pBot->f_maxview_distance = 4096.0;

   pBot->pBotPickupItem = NULL;
   pBot->pItemIgnore = NULL;
   pBot->f_itemcheck_time = 0.0;
   pBot->f_timeDoorOpen = 0.0;

   pBot->pShootBreakable = NULL;
   pBot->vecBreakable = g_vecZero;

   BotResetCollideState (pBot);

   pBot->pBotEnemy = NULL;
   pBot->pLastVictim = NULL;
   pBot->pLastEnemy = NULL;
   pBot->vecLastEnemyOrigin = g_vecZero;
   pBot->pTrackingEdict = NULL;
   pBot->fTimeNextTracking = 0.0;

   pBot->fEnemyUpdateTime = 0.0;
   pBot->f_bot_see_enemy_time = 0.0;
   pBot->f_shootatdead_time = 0.0;
   pBot->oldcombatdesire = 0.0;

   pBot->pAvoidGrenade = NULL;
   pBot->cAvoidGrenade = 0;

   // Reset Damage
   pBot->iLastDamageType = -1;

   pBot->vecPosition = g_vecZero;

   pBot->f_ideal_reaction_time = BotSkillDelays[pBot->bot_skill / 20].fMinSurpriseDelay;
   pBot->f_actual_reaction_time = BotSkillDelays[pBot->bot_skill / 20].fMinSurpriseDelay;

   pBot->pBotUser = NULL;
   pBot->f_bot_use_time = 0.0;

   for (i = 0; i < MAX_HOSTAGES; i++)
      pBot->pHostages[i] = NULL;

   pBot->f_hostage_check_time = gpGlobals->time;

   pBot->bIsReloading = FALSE;
   pBot->f_shoot_time = gpGlobals->time;
   pBot->fTimeLastFired = 0.0;
   pBot->iBurstShotsFired = 0;
   pBot->fTimeFirePause = 0.0;

   pBot->f_primary_charging = -1.0;
   pBot->f_secondary_charging = -1.0;

   pBot->f_grenade_check_time = 0.0;
   pBot->bUsingGrenade = FALSE;

   pBot->charging_weapon_id = 0;

   pBot->f_blind_time = 0.0;
   pBot->f_jumptime = 0.0;

   pBot->f_sound_update_time = gpGlobals->time;
   pBot->f_heard_sound_time = 0.0;

   pBot->fTimePrevThink = gpGlobals->time;
   pBot->fTimeFrameInterval = 0.0;

   pBot->b_bomb_blinking = FALSE;

   pBot->SaytextBuffer.fTimeNextChat = gpGlobals->time;
   pBot->SaytextBuffer.iEntityIndex = -1;
   pBot->SaytextBuffer.szSayText[0] = 0x0;

   pBot->iBuyCount = 1;
   pBot->f_buy_time = gpGlobals->time + RANDOM_FLOAT (1.5, 2.0);

   pBot->f_zoomchecktime = 0.0;
   pBot->iNumWeaponPickups = 0;

   pBot->f_StrafeSetTime = 0.0;
   pBot->byCombatStrafeDir = 0;
   pBot->byFightStyle = 0;
   pBot->f_lastfightstylecheck = 0.0;

   pBot->bCheckWeaponSwitch = TRUE;

   pBot->pRadioEntity = NULL;
   pBot->iRadioOrder = 0;

   pBot->bLogoSprayed = FALSE;
   pBot->bDefendedBomb = FALSE;

   pBot->f_spawn_time = gpGlobals->time;
   pBot->f_lastchattime = gpGlobals->time;
   pBot->pEdict->v.v_angle.y = pBot->pEdict->v.ideal_yaw;

   for (i = 0; i < 2; i++)
   {
      pBot->rgfYawHistory[i] = 0;
      pBot->rgfPitchHistory[i] = 0;
   }

   // Clear its Message Queue
   for (i = 0; i < 32; i++)
      pBot->aMessageQueue[i] = 0;

   pBot->iActMessageIndex = 0;
   pBot->iPushMessageIndex = 0;

   bottask_t TempTask = {NULL, NULL, TASK_NORMAL, TASKPRI_NORMAL, -1, 0.0, TRUE};
   BotPushTask (pBot, &TempTask);
}


void BotCreate (int bot_skill, int bot_team, int bot_class, const char *bot_name)
{
   // This Function creates the Fakeclient (Bot) - passed Arguments:
   // arg1 - Skill
   // arg2 - Team
   // arg3 - Class (Model)
   // arg4 - Botname

   edict_t *pPlayer;
   edict_t *BotEnt;
   bot_t *pBot;
   char c_name[BOT_NAME_LEN + 1];
   int skill;
   int index;
   int name_index;
   char ptr[128]; // allocate space for message from ClientConnect
   char *infobuffer;
   int iPersonality;
   int iUsedCount;
   bool is_used;

   // Don't allow creating Bots when no waypoints are loaded
   if (g_iNumWaypoints < 1)
   {
      UTIL_ServerPrint ("No Waypoints for this Map, can't create Bot !\n");
      memset (BotCreateTab, 0, sizeof (BotCreateTab));
      botcreation_time = 0.0;
      return;
   }

   // Don't allow creating Bots when max_bots is reached
   else if (num_bots == max_bots)
   {
      UTIL_ServerPrint ("Max Bots reached, can't create Bot !\n");
      memset (BotCreateTab, 0, sizeof (BotCreateTab));
      botcreation_time = 0.0;
      return;
   }

   // if Waypoints have changed don't allow it because Distance Tables are messed up
   else if (g_bWaypointsChanged)
   {
      UTIL_ServerPrint ("Waypoints changed/not initialised, can't create Bot !\n");
      memset (BotCreateTab, 0, sizeof (BotCreateTab));
      botcreation_time = 0.0;
      return;
   }

   // If Skill is given, assign it
   if ((bot_skill > 0) && (bot_skill <= 100))
      skill = bot_skill;
   else
      skill = RANDOM_LONG (g_iMinBotSkill, g_iMaxBotSkill); // else give random skill

   assert ((skill > 0) && (skill <= 100));

   // Create Random Personality
   iPersonality = RANDOM_LONG (0, 2);

   // If No Name is given, do our name stuff
   if ((bot_name == NULL) || (*bot_name == 0))
   {
      // If as many Bots as NumBotnames, don't allow Bot Creation
      if (num_bots >= iNumBotNames)
      {
         UTIL_ServerPrint ("Not enough Bot Names in botnames.txt, can't create Bot !\n");
         memset (BotCreateTab, 0, sizeof (BotCreateTab));
         botcreation_time = 0.0;
         return;
      }

      // Clear Array of used Botnames
      memset (szUsedBotNames, 0, sizeof (szUsedBotNames));

      // Cycle through all Players in Game and pick up Bots Names
      iUsedCount = 0;
      for (index = 1; index < gpGlobals->maxClients; index++)
      {
         pPlayer = INDEXENT (index);

         if (!FNullEnt (pPlayer)
             && (pPlayer->v.flags & FL_FAKECLIENT)
             && (STRING (pPlayer->v.netname)[0] != 0))
            szUsedBotNames[iUsedCount++] = STRING (pPlayer->v.netname);
      }

      // Find a Botname from Botnames.txt which isn't used yet
      do
      {
         name_index = RANDOM_LONG (0, iNumBotNames - 1);

         if (iUsedCount == 0)
            is_used = FALSE;
         else
         {
            is_used = FALSE;

            for (index = 0; index < iUsedCount; index++)
               if (strstr (szUsedBotNames[index], szBotNames[name_index]) != NULL)
                  is_used = TRUE;
         }
      }
      while (is_used);

      // If Detailnames are on, attach Clan Tag
      if (g_bDetailNames)
      {
         if (iPersonality == 0)
            sprintf (c_name, "[POD]%s (%d)", szBotNames[name_index], skill);
         else if (iPersonality == 1)
            sprintf (c_name, "[P*D]%s (%d)", szBotNames[name_index], skill);
         else
            sprintf (c_name, "[P0D]%s (%d)", szBotNames[name_index], skill);
      }
      else
         strncpy (c_name, bot_name, 32);
   }

   // a name has been given
   else
   {
      // If Detailnames are on, attach Clan Tag
      if (g_bDetailNames)
      {
         if (iPersonality == 0)
            sprintf (c_name, "[POD]%s (%d)", bot_name, skill);
         else if (iPersonality == 1)
            sprintf (c_name, "[P*D]%s (%d)", bot_name, skill);
         else
            sprintf (c_name, "[P0D]%s (%d)", bot_name, skill);
      }
      else
         strncpy (c_name, bot_name, 32);
   }

   // This call creates the Fakeclient
   BotEnt = (*g_engfuncs.pfnCreateFakeClient) (c_name);

   // Did the Call succeed ?
   if (FNullEnt (BotEnt))
   {
      UTIL_ServerPrint ("Max. Players reached.  Can't create bot!\n");
      memset (BotCreateTab, 0, sizeof (BotCreateTab));
      botcreation_time = 0.0;
      return;
   }

   // YEP! Our little Bot has spawned !

   // Notify calling Player of the creation
   UTIL_ServerPrint ("Creating bot...\n");

   if (BotEnt->pvPrivateData != NULL)
      FREE_PRIVATE (BotEnt);
   BotEnt->pvPrivateData = NULL;
   BotEnt->v.frags = 0;

   // create the player entity by calling MOD's player function
   CALL_GAME_ENTITY (PLID, "player", &BotEnt->v);

   // Find a free slot in our Table of Bots
   index = ENTINDEX (BotEnt) - 1;

   // Set all Infobuffer Keys for this Bot
   infobuffer = GET_INFOKEYBUFFER (BotEnt);
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "model", "gordon");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "rate", "3500.000000");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "cl_updaterate", "20");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "cl_lw", "1");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "cl_lc", "1");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "tracker", "0");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "cl_dlmax", "128");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "lefthand", "1");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "friends", "0");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "dm", "0");
   SET_CLIENT_KEYVALUE (index + 1, infobuffer, "ah", "1");
   // - End Infobuffer -

   // Connect this client with the local loopback
   MDLL_ClientConnect (BotEnt, c_name, "127.0.0.1", ptr);

   // Pieter van Dijk - use instead of DispatchSpawn() - Hip Hip Hurray!
   MDLL_ClientPutInServer (BotEnt);

   // PMB - do this because MDLL_ClientPutInServer() does NOT call our own ClientPutInServer()
   clients[index].pEdict = BotEnt;

   // set the third party bot flag
   BotEnt->v.flags |= FL_FAKECLIENT;
   BotEnt->v.spawnflags |= FL_FAKECLIENT;

   // initialize all the variables for this bot...
   pBot = &bots[index];
   pBot->pEdict = BotEnt;

   sprintf (pBot->name, STRING (pBot->pEdict->v.netname));
   pBot->is_used = TRUE;
   pBot->not_started = 1; // hasn't joined game yet
   pBot->start_action = MSG_CS_IDLE;
   pBot->bot_money = 0;
   pBot->bDead = TRUE;
   pBot->bot_skill = skill;
   pBot->bot_personality = iPersonality;

   // Assign a random Spraypaint
   pBot->iSprayLogo = RANDOM_LONG (0, g_iNumLogos - 1);

   // Assign how talkative this Bot will be
   pBot->SaytextBuffer.fChatDelay = RANDOM_FLOAT (4.0, 10.0);
   pBot->SaytextBuffer.cChatProbability = RANDOM_LONG (1, 100);

   BotEnt->v.idealpitch = BotEnt->v.v_angle.x;
   BotEnt->v.ideal_yaw = BotEnt->v.v_angle.y;
   BotEnt->v.yaw_speed = BOT_YAW_SPEED;
   BotEnt->v.pitch_speed = BOT_PITCH_SPEED;

   // Set the Base Fear/Agression Levels for this Personality
   switch (iPersonality)
   {
      // Normal
   case 0:
      pBot->fBaseAgressionLevel = RANDOM_FLOAT (0.5, 0.6);
      pBot->fBaseFearLevel = RANDOM_FLOAT (0.5, 0.6);
      break;
      // Psycho
   case 1:
      pBot->fBaseAgressionLevel = RANDOM_FLOAT (0.7, 1.0);
      pBot->fBaseFearLevel = RANDOM_FLOAT (0.0, 0.4);
      break;
      // Coward
   case 2:
      pBot->fBaseAgressionLevel = RANDOM_FLOAT (0.0, 0.4);
      pBot->fBaseFearLevel = RANDOM_FLOAT (0.7, 1.0);
      break;
   }

   // Copy them over to the temp Level Variables
   pBot->fAgressionLevel = pBot->fBaseAgressionLevel;
   pBot->fFearLevel = pBot->fBaseFearLevel;
   pBot->fNextEmotionUpdate = gpGlobals->time + 0.5;

   // Just to be sure
   pBot->iActMessageIndex = 0;
   pBot->iPushMessageIndex = 0;

   // Assign Team & Class
   pBot->bot_team = bot_team;
   pBot->bot_class = bot_class;

   BotSpawnInit (pBot);

   return;
}


void BotStartGame (bot_t *pBot)
{
   // Handles the selection of Teams & Class

   // handle Counter-Strike stuff here...
   if (pBot->start_action == MSG_CS_TEAM_SELECT)
   {
      pBot->start_action = MSG_CS_IDLE; // switch back to idle

      if ((pBot->bot_team < 1) || (pBot->bot_team > 2))
         pBot->bot_team = 5;

      FakeClientCommand (pBot->pEdict, "menuselect %d\n", pBot->bot_team);
      return;
   }

   else if ((pBot->start_action == MSG_CS_CT_SELECT)
            || (pBot->start_action == MSG_CS_T_SELECT))
   {
      pBot->start_action = MSG_CS_IDLE; // switch back to idle

      if ((pBot->bot_class < 1) || (pBot->bot_class > 4))
         pBot->bot_class = RANDOM_LONG (1, 4); // use random if invalid

      FakeClientCommand (pBot->pEdict, "menuselect %d\n", pBot->bot_class);

      // bot has now joined the game (doesn't need to be started)
      pBot->not_started = FALSE;
      return;
   }
}


void UserRemoveAllBots (void)
{
   // Called from Usercommand "removebots"
   // Removes all Bots from the Server, sets minbots/maxbots to 0

   int index;
   char cmd[40];

   for (index = 0; index < gpGlobals->maxClients; index++)
   {
      // Reset our Creation Tab if there are still Bots waiting to be spawned
      memset (&BotCreateTab[index], 0, sizeof (createbot_t));

      // is this slot used?
      if (bots[index].is_used && !FNullEnt (bots[index].pEdict))
      {
         sprintf (cmd, "kick \"%s\"\n", STRING (bots[index].pEdict->v.netname));
         SERVER_COMMAND (cmd); // kick the bot using (kick "name")
      }
   }

   UTIL_HostPrint ("All Bots removed !\n");
}


void UserKillAllBots (void)
{
   // Called by UserCommand "killbots"
   // Kills all Bots

   int i;
   bot_t *pBot;

   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      pBot = &bots[i];

      if (pBot->is_used && !pBot->bDead)
      {
         // If a Bot gets killed it decreases his frags, so add 1 here to not give human
         // players an advantage using this command
         pBot->pEdict->v.frags++;
         MDLL_ClientKill (pBot->pEdict);
      }
   }

   UTIL_HostPrint ("All Bots killed !\n");
}


void UserNewroundAll (void)
{
   // Called by UserCommand "newround"
   // Kills all Clients in Game including humans

   edict_t *pPlayer;

   for (int i = 1; i <= gpGlobals->maxClients; i++)
   {
      pPlayer = INDEXENT (i);

      // is this player slot valid
      if (!FNullEnt (pPlayer) && (pPlayer->v.flags & FL_CLIENT) && IsAlive (pPlayer))
      {
         pPlayer->v.frags++;
         MDLL_ClientKill (pPlayer);
      }
   }

   UTIL_HostPrint ("Round Restarted !\n");
}


void UserSelectWeaponMode (int iSelection)
{
   int i;
   int rgiWeaponTab[7][NUM_WEAPONS] =
   {
      {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}, // Knife only
      {-1,-1,-1, 2, 2, 0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}, // Pistols only
      {-1,-1,-1,-1,-1,-1,-1, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}, // Shotgun only
      {-1,-1,-1,-1,-1,-1,-1,-1,-1, 2, 2, 2, 2, 2,-1,-1,-1,-1,-1,-1,-1,-1, 2,-1,-1,-1}, // Machine Guns only
      {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1, 0, 0, 1, 1,-1,-1,-1,-1,-1, 0, 1,-1}, // Rifles only
      {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1, 2, 2, 0, 1,-1,-1,-1,-1}, // Snipers only
      {-1,-1,-1, 2, 2, 0, 1, 2, 2, 2, 1, 2, 0, 2, 0, 0, 1, 1, 2, 2, 0, 1, 2, 0, 1, 0}  // Standard
   };

   char szMode[7][12] =
   {
      {"Knife"},
      {"Pistol"},
      {"Shotgun"},
      {"Machine Gun"},
      {"Rifle"},
      {"Sniper"},
      {"Standard"}
   };

   iSelection--;
   for (i = 0; i < NUM_WEAPONS; i++)
   {
      cs_weapon_select[i].iTeamStandard = rgiWeaponTab[iSelection][i];
      cs_weapon_select[i].iTeamAS = rgiWeaponTab[iSelection][i];
   }

   if (iSelection == 0)
      g_bJasonMode = TRUE;
   else
      g_bJasonMode = FALSE;

   UTIL_HostPrint ("%s Weapon Mode selected!\n", &szMode[iSelection][0]);
}


int BotGetMessageQueue (bot_t *pBot)
{
   // Get the current Message from the Bots Message Queue

   int iMSG;

   iMSG = pBot->aMessageQueue[pBot->iActMessageIndex++];
   pBot->iActMessageIndex &= 0x1f; // Wraparound

   return (iMSG);
}


void BotPushMessageQueue (bot_t *pBot, int iMessage)
{
   // Put a Message into the Message Queue

   pBot->aMessageQueue[pBot->iPushMessageIndex++] = iMessage;
   pBot->iPushMessageIndex &= 0x1f; // Wraparound

   return;
}



int BotInFieldOfView (bot_t *pBot, Vector dest)
{
   int angle;
   float entity_angle;
   float view_angle;

   // find angles from source to destination...
   entity_angle = UTIL_VecToAngles (dest).y;

   // make yaw angle 0 to 360 degrees if negative...
   if (entity_angle < 0)
      entity_angle += 360;

   // get bot's current view angle...
   view_angle = pBot->pEdict->v.v_angle.y;

   // make view angle 0 to 360 degrees if negative...
   if (view_angle < 0)
      view_angle += 360;

   // return the absolute value of angle to destination entity
   // zero degrees means straight ahead,  45 degrees to the left or
   // 45 degrees to the right is the limit of the normal view angle

   // rsm - START angle bug fix
   angle = abs ((int) view_angle - (int) entity_angle);

   if (angle > 180)
      angle = 360 - angle;

   return (angle);
   // rsm - END
}


bool BotItemIsVisible (bot_t *pBot, Vector vecDest, char *pszItemName)
{
   TraceResult tr;

   // trace a line from bot's eyes to destination...
   TRACE_LINE (pBot->pEdict->v.origin + pBot->pEdict->v.view_ofs, vecDest, ignore_monsters, pBot->pEdict, &tr);

   // check if line of sight to object is not blocked (i.e. visible)
   if (tr.flFraction != 1.0)
   {
      if (strcmp (STRING (tr.pHit->v.classname), pszItemName) == 0)
         return (TRUE);

      return (FALSE);
   }

   return (TRUE);
}


bool BotEntityIsVisible (bot_t *pBot, Vector vecDest)
{
   TraceResult tr;

   // trace a line from bot's eyes to destination...
   TRACE_LINE (pBot->pEdict->v.origin + pBot->pEdict->v.view_ofs, vecDest, ignore_monsters, pBot->pEdict, &tr);

   // check if line of sight to object is not blocked (i.e. visible)
   if (tr.flFraction != 1.0)
      return (FALSE);

   return (TRUE);
}


void BotCheckSmokeGrenades (bot_t *pBot)
{
   // Check if Bot 'sees' a SmokeGrenade to simulate the effect of being blinded by smoke
   // + notice Bot of Grenades flying towards him
   // TODO: Split this up and make it more reliable

   edict_t *pEdict = pBot->pEdict;
   edict_t *pent = pBot->pAvoidGrenade;
   Vector vecView = pEdict->v.origin + pEdict->v.view_ofs;
   float fDistance;

   // Check if old ptr to Grenade is invalid
   if (FNullEnt (pent))
   {
      pBot->pAvoidGrenade = NULL;
      pBot->cAvoidGrenade = 0;
   }

   else if ((pent->v.flags & FL_ONGROUND) || (pent->v.effects & EF_NODRAW))
   {
      pBot->pAvoidGrenade = NULL;
      pBot->cAvoidGrenade = 0;
   }

   pent = NULL;

   // Find all Grenades on the map
   while (!FNullEnt (pent = FIND_ENTITY_BY_STRING (pent, "classname", "grenade")))
   {
      // If Grenade is invisible don't care for it
      if (pent->v.effects & EF_NODRAW)
         continue;

      // Check if visible to the Bot
      if (!BotEntityIsVisible (pBot, pent->v.origin)
          && BotInFieldOfView (pBot, pent->v.origin - vecView) > pEdict->v.fov / 2)
         continue;

      if (FNullEnt (pBot->pAvoidGrenade))
      {
         // Is this a flying Grenade ?
         if ((pent->v.flags & FL_ONGROUND) == 0)
         {
            fDistance = (pent->v.origin - pEdict->v.origin).Length ();
            float fDistanceMoved = ((pent->v.origin + pent->v.velocity * pBot->fTimeFrameInterval) - pEdict->v.origin).Length ();

            // Is the Grenade approaching this Bot ?
            if ((fDistanceMoved < fDistance) && (fDistance < 600))
            {
               Vector2D vec2DirToPoint;
               Vector2D vec2RightSide;

               // to start strafing, we have to first figure out if the target is on the left side or right side
               MAKE_VECTORS (pEdict->v.angles);

               vec2DirToPoint = (pEdict->v.origin - pent->v.origin).Make2D ().Normalize ();
               vec2RightSide = gpGlobals->v_right.Make2D ().Normalize ();

               if (DotProduct (vec2DirToPoint, vec2RightSide) > 0)
                  pBot->cAvoidGrenade = -1;
               else
                  pBot->cAvoidGrenade = 1;

               pBot->pAvoidGrenade = pent;
               return;
            }
         }
      }

      // Is this a SmokeGrenade and on Ground (smoking) ?
      if (!FStrEq (STRING (pent->v.model), "models/w_smokegrenade.mdl")
          || (pent->v.flags & FL_ONGROUND) == 0)
         continue;

      fDistance = (pent->v.origin - pEdict->v.origin).Length ();

      // Shrink Bots Viewing Distance to Smoke Grens Distance
      if (pBot->f_view_distance > fDistance)
         pBot->f_view_distance = fDistance;
   }
}


int GetBestWeaponCarried (bot_t *pBot)
{
   // Returns the best weapon of this Bot (based on Personality Prefs)

   int *ptrWeaponTab = ptrWeaponPrefs[pBot->bot_personality];
   bot_weapon_select_t *pWeaponTab = &cs_weapon_select[0];
   int iWeaponIndex;
   int i;

   int iWeapons = pBot->pEdict->v.weapons;

   if (BotHasShield (pBot))
      iWeapons |= (1 << CS_WEAPON_SHIELDGUN);

   for (i = 0; i < NUM_WEAPONS; i++)
   {
      if ((pBot->pEdict->v.weapons & (1 << pWeaponTab[*ptrWeaponTab].iId)))
         iWeaponIndex = i;
      ptrWeaponTab++;
   }

   return iWeaponIndex;
}


int BotRateGroundWeapon (bot_t *pBot, edict_t *pent)
{
   // Compares Weapons on the Ground to the one the Bot is using

   int i;
   int iHasWeapon = GetBestWeaponCarried (pBot);
   int *ptrWeaponTab = ptrWeaponPrefs[pBot->bot_personality];
   bot_weapon_select_t *pWeaponTab = &cs_weapon_select[0];

   int iGroundIndex = 0;
   char szModelName[40];

   strcpy (szModelName, STRING (pent->v.model));

   for (i = 0; i < NUM_WEAPONS; i++)
   {
      if (FStrEq (pWeaponTab[*ptrWeaponTab].model_name, szModelName))
      {
         iGroundIndex = i;
         break;
      }

      ptrWeaponTab++;
   }

   // Don't care for pistols
   // TODO Include Pistols as well...
   if (iGroundIndex < 7)
      iGroundIndex = 0;

   return (iGroundIndex - iHasWeapon);
}


bool BotFindBreakable (bot_t *pBot)
{
   // Checks if Bot is blocked by a Shootable Breakable in his moving direction

   TraceResult tr;
   edict_t *pEdict = pBot->pEdict;

   Vector v_src = pEdict->v.origin;
   Vector vecDirection = (pBot->dest_origin - v_src).Normalize ();
   Vector v_dest = v_src + vecDirection * 50;

   TRACE_LINE (v_src, v_dest, dont_ignore_monsters, pEdict, &tr);
   if ((tr.flFraction != 1.0)
       && (strcmp ("func_breakable", STRING (tr.pHit->v.classname)) == 0)
       && IsShootableBreakable (tr.pHit))
   {
      pBot->vecBreakable = tr.vecEndPos;
      return (TRUE);
   }

   v_src = pEdict->v.origin + pEdict->v.view_ofs;
   vecDirection = (pBot->dest_origin - v_src).Normalize ();
   v_dest = v_src + vecDirection * 50;

   TRACE_LINE (v_src, v_dest, dont_ignore_monsters, pEdict, &tr);
   if ((tr.flFraction != 1.0)
       && (strcmp ("func_breakable", STRING (tr.pHit->v.classname)) == 0)
       && IsShootableBreakable (tr.pHit))
   {
      pBot->vecBreakable = tr.vecEndPos;
      return (TRUE);
   }

   pBot->pShootBreakable = NULL;
   pBot->vecBreakable = g_vecZero;
   return (FALSE);
}


void BotFindItem (bot_t *pBot)
{
   // Finds Items to collect or use in the near of a Bot

   edict_t *pEdict = pBot->pEdict;
   edict_t *pent = NULL;
   edict_t *pPickupEntity = NULL;
   edict_t *pTrigger = NULL;
   bool bItemExists;
   Vector vecPosition;
   int iPickType = 0;
   Vector pickup_origin;
   Vector entity_origin;
   bool bCanPickup;
   float distance;
   float min_distance = 9999;
   float rescue_distance;
   float rescue_min_distance = 9999;
   float fTraveltime;
   float fTimeMidBlowup;
   float fTimeBlowup;
   Vector vecEnd;
   int iIndex;
   int i;
   int h;

   // Don't try to pickup anything while on ladder...
   if (pBot->bOnLadder)
   {
      pBot->pBotPickupItem = NULL;
      pBot->iPickupType = PICKUP_NONE;
      return;
   }

   if (!FNullEnt (pBot->pBotPickupItem))
   {
      bItemExists = FALSE;
      pPickupEntity = pBot->pBotPickupItem;

      while (!FNullEnt (pent = FIND_ENTITY_IN_SPHERE (pent, pEdict->v.origin, 500)))
      {
         if (pent->v.effects & EF_NODRAW)
            continue; // someone owns this weapon or it hasn't respawned yet

         if (pent == pPickupEntity)
         {
            if (pent->v.absmin != g_vecZero)
               vecPosition = VecBModelOrigin (pent);
            else
               vecPosition = pent->v.origin;

            if (BotItemIsVisible (pBot, vecPosition, (char *) STRING (pent->v.classname)))
               bItemExists = TRUE;

            break;
         }
      }

      if (bItemExists)
         return;

      else
      {
         pBot->pBotPickupItem = NULL;
         pBot->iPickupType = PICKUP_NONE;
      }
   }

   pent = NULL;
   pPickupEntity = NULL;

   pBot->pBotPickupItem = NULL;
   pBot->iPickupType = PICKUP_NONE;
   
   while (!FNullEnt (pent = FIND_ENTITY_IN_SPHERE (pent, pEdict->v.origin, 500)))
   {
      bCanPickup = FALSE; // assume can't use it until known otherwise

      if ((pent->v.effects & EF_NODRAW) || (pent == pBot->pItemIgnore))
         continue; // someone owns this weapon or it hasn't respawned yet

      // see if this is a "func_" type of entity (func_button, etc.)...
      if (pent->v.absmin != g_vecZero)
         entity_origin = VecBModelOrigin (pent);
      else
         entity_origin = pent->v.origin;
      
      vecEnd = entity_origin;
      
      // check if line of sight to object is not blocked (i.e. visible)
      if (BotItemIsVisible (pBot, vecEnd, (char *) STRING (pent->v.classname)))
      {
         if ((strcmp ("hostage_entity", STRING (pent->v.classname)) == 0)
                  && (pent->v.velocity == g_vecZero))
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_HOSTAGE;
         }

         else if (strcmp ("weapon_shield", STRING (pent->v.classname)) == 0)
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_SHIELD;
         }

         else if (((strcmp ("weaponbox", STRING (pent->v.classname)) == 0)
                   || (strcmp ("armoury_entity", STRING (pent->v.classname)) == 0))
                  && (strcmp ("models/w_backpack.mdl", STRING (pent->v.model)) != 0)
                  && !pBot->bUsingGrenade && !BotHasShield (pBot))
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_WEAPON;
         }

         else if ((strcmp ("weaponbox", STRING (pent->v.classname)) == 0)
                  && (strcmp ("models/w_backpack.mdl", STRING (pent->v.model)) == 0))
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_DROPPED_C4;
         }

         else if ((strcmp ("grenade", STRING (pent->v.classname)) == 0)
                  && (strcmp ("models/w_c4.mdl", STRING (pent->v.model)) == 0))
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_PLANTED_C4;
         }
         else if ((strcmp ("item_thighpack", STRING (pent->v.classname)) == 0)
                  && (pBot->bot_team == TEAM_CS_COUNTER) && !pBot->b_has_defuse_kit)
         {
            bCanPickup = TRUE;
            iPickType = PICKUP_DEFUSEKIT;
         }
      }

      // if the bot found something it can pickup...
      if (bCanPickup)
      {
         distance = (entity_origin - pEdict->v.origin).Length ();

         // see if it's the closest item so far...
         if (distance < min_distance)
         {
            // Found weapon on ground ?
            if (iPickType == PICKUP_WEAPON)
            {
               if (pBot->bIsVIP || (BotRateGroundWeapon (pBot, pent) <= 0)
                   || (pBot->iNumWeaponPickups > g_iMaxWeaponPickup))
                  bCanPickup = FALSE;
            }

            // Found shield on ground ? (code courtesy of Wei Mingzhi)
            else if (iPickType == PICKUP_SHIELD)
            {
               if ((pEdict->v.weapons & (1 << CS_WEAPON_ELITE))
                   || BotHasShield (pBot) || pBot->bIsVIP
                   || (BotHasPrimaryWeapon (pBot) && (BotRateGroundWeapon (pBot, pent) <= 0)))
                  bCanPickup = FALSE;
            }

            // Terrorist Team specific
            else if (pBot->bot_team == TEAM_CS_TERRORIST)
            {
               if (iPickType == PICKUP_HOSTAGE)
               {
                  if (g_bHostageRescued)
                  {
                     if (RANDOM_LONG (1, 100) > 20)
                        bCanPickup = FALSE;
                  }
                  else
                  {
                     if (pBot->f_hostage_check_time + 10.0 < gpGlobals->time)
                     {
                        // Check if Hostage has been moved away
                        for (i = 0; i < g_iNumWaypoints; i++)
                        {
                           if (paths[i]->flags & W_FL_GOAL)
                           {
                              rescue_distance = (paths[i]->origin - entity_origin).Length ();

                              if (rescue_distance < rescue_min_distance)
                              {
                                 rescue_min_distance = rescue_distance;

                                 if (rescue_min_distance < 300)
                                 {
                                    bCanPickup = FALSE;
                                    break;
                                 }
                              }
                           }
                        }

                        pBot->f_hostage_check_time = gpGlobals->time;
                     }
                     else
                        bCanPickup = FALSE;
                  }

                  if (bCanPickup)
                  {
                     for (i = 0; i < gpGlobals->maxClients; i++)
                     {
                        if (bots[i].is_used && !bots[i].bDead)
                        {
                           for (h = 0; h < MAX_HOSTAGES; h++)
                           {
                              if (bots[i].pHostages[h] == pent)
                              {
                                 bCanPickup = FALSE;
                                 break;
                              }
                           }
                        }
                     }
                  }
               }

               else if (iPickType == PICKUP_PLANTED_C4)
               {
                  bCanPickup = FALSE;

                  if (!pBot->bDefendedBomb)
                  {
                     pBot->bDefendedBomb = TRUE;

                     iIndex = BotFindDefendWaypoint (pBot, entity_origin);
                     fTraveltime = GetTravelTime (pBot->pEdict->v.maxspeed, pEdict->v.origin, paths[iIndex]->origin);
                     fTimeMidBlowup = g_fTimeBombPlanted + (CVAR_GET_FLOAT ("mp_c4timer") / 2) - fTraveltime;

                     if (fTimeMidBlowup > gpGlobals->time)
                     {
                        // Remove any Move Tasks
                        BotRemoveCertainTask (pBot, TASK_MOVETOPOSITION);

                        // Push camp task on to stack
                        bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, fTimeMidBlowup, TRUE};
                        BotPushTask (pBot, &TempTask);

                        // Push Move Command
                        TempTask.iTask = TASK_MOVETOPOSITION;
                        TempTask.fDesire = TASKPRI_MOVETOPOSITION;
                        TempTask.iData = iIndex;
                        BotPushTask (pBot, &TempTask);

                        pBot->iCampButtons|=IN_DUCK;
                     }
                     else
                        BotPlayRadioMessage (pBot, RADIO_SHESGONNABLOW); // Issue an additional Radio Message
                  }
               }
            }

            // CT Team specific
            else
            {
               if (iPickType == PICKUP_HOSTAGE)
               {
                  for (i = 0; i < gpGlobals->maxClients; i++)
                  {
                     if (bots[i].is_used && !bots[i].bDead)
                     {
                        for (h = 0; h < MAX_HOSTAGES; h++)
                        {
                           if (bots[i].pHostages[h] == pent)
                           {
                              bCanPickup = FALSE;
                              break;
                           }
                        }
                     }
                  }
               }

               else if (iPickType == PICKUP_PLANTED_C4)
               {
                  edict_t *pPlayer;

                  // search the world for players...
                  for (i = 0; i < gpGlobals->maxClients; i++)
                  {
                     if (!clients[i].IsUsed
                         || !clients[i].IsAlive
                         || (clients[i].iTeam != pBot->bot_team)
                         || (clients[i].pEdict == pEdict))
                        continue;

                     pPlayer = clients[i].pEdict;

                     // find the distance to the target waypoint
                     if ((pPlayer->v.origin - entity_origin).Length() < 60)
                     {
                        bCanPickup = FALSE;

                        if (!pBot->bDefendedBomb)
                        {
                           pBot->bDefendedBomb = TRUE;

                           iIndex = BotFindDefendWaypoint (pBot, entity_origin);
                           fTraveltime = GetTravelTime (pBot->pEdict->v.maxspeed, pEdict->v.origin, paths[iIndex]->origin);
                           fTimeBlowup = g_fTimeBombPlanted + CVAR_GET_FLOAT ("mp_c4timer") - fTraveltime;

                           // Remove any Move Tasks
                           BotRemoveCertainTask (pBot, TASK_MOVETOPOSITION);

                           // Push camp task on to stack
                           bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, fTimeBlowup, TRUE};

                           BotPushTask (pBot, &TempTask);

                           // Push Move Command
                           TempTask.iTask = TASK_MOVETOPOSITION;
                           TempTask.fDesire = TASKPRI_MOVETOPOSITION;
                           TempTask.iData = iIndex;
                           BotPushTask (pBot, &TempTask);
                           pBot->iCampButtons |= IN_DUCK;

                           return;
                        }
                     }
                  }
               }

               else if (iPickType == PICKUP_DROPPED_C4)
               {
                  pBot->pItemIgnore = pent;
                  bCanPickup = FALSE;

                  if ((pBot->pEdict->v.health < 50) || (RANDOM_LONG (1, 100) > 50))
                  {
                     // Push camp task on to stack
                     bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, gpGlobals->time + RANDOM_FLOAT (20.0, 40.0), TRUE};
                     BotPushTask (pBot, &TempTask);

                     // Push Move Command
                     TempTask.iTask = TASK_MOVETOPOSITION;
                     TempTask.fDesire = TASKPRI_MOVETOPOSITION;
                     TempTask.iData = BotFindDefendWaypoint (pBot, entity_origin);
                     BotPushTask (pBot, &TempTask);
                     pBot->iCampButtons |= IN_DUCK;

                     return;
                  }
               }
            }

            if (bCanPickup)
            {
               min_distance = distance; // update the minimum distance
               pPickupEntity = pent; // remember this entity
               pickup_origin = entity_origin; // remember location of entity
               pBot->iPickupType = iPickType;
            }
            else
               iPickType = PICKUP_NONE;
         }
      }
   } // end while loop

   if (pPickupEntity != NULL)
   {
      for (i = 0; i < gpGlobals->maxClients; i++)
      {
         if (bots[i].is_used && !bots[i].bDead)
         {
            if (bots[i].pBotPickupItem == pPickupEntity)
            {
               pBot->pBotPickupItem = NULL;
               pBot->iPickupType = PICKUP_NONE;

               return;
            }
         }
      }

      // Check if Item is too high to reach
      if (pickup_origin.z > (pEdict->v.origin + pEdict->v.view_ofs).z)
      {
         pBot->pBotPickupItem = NULL;
         pBot->iPickupType = PICKUP_NONE;

         return;
      }

      // Check if getting the item would hurt Bot      
      if (IsDeadlyDrop (pBot, pickup_origin))
      {
         pBot->pBotPickupItem = NULL;
         pBot->iPickupType = PICKUP_NONE;

         return;
      }

      pBot->pBotPickupItem = pPickupEntity; // save the item bot is trying to get
   }
}


void BotChangePitch (bot_t *pBot, float speed)
{
   edict_t *pEdict = pBot->pEdict;
   float ideal;
   float current;
   float current_180; // current +/- 180 degrees
   float diff;
   float fOld = 0;

   UTIL_ClampAngle (&pEdict->v.idealpitch);

   if (g_bInstantTurns)
   {
      pEdict->v.v_angle.x = pEdict->v.idealpitch;
      return;
   }

   // turn from the current v_angle pitch to the idealpitch by selecting
   // the quickest way to turn to face that direction
   current = pEdict->v.v_angle.x;
   ideal = pEdict->v.idealpitch;

   // find the difference in the current and ideal angle
   diff = fabs (current - ideal);

   // check if difference is less than the max degrees per turn
   if (diff < speed)
      speed = diff; // just need to turn a little bit (less than max)

   // Sum up old Pitch Changes
   fOld += pBot->rgfPitchHistory[0];
   fOld += pBot->rgfPitchHistory[1];

   fOld += speed;
   fOld /= 3;

   pBot->rgfPitchHistory[1] = pBot->rgfPitchHistory[0];
   pBot->rgfPitchHistory[0] = speed;

   speed = fOld;

   // here we have four cases, both angle positive, one positive and
   // the other negative, one negative and the other positive, or
   // both negative.  handle each case separately...

   if ((current >= 0) && (ideal >= 0))  // both positive
   {
      if (current > ideal)
         speed = -speed;
   }
   else if ((current >= 0) && (ideal < 0))
   {
      current_180 = current - 180;

      if (current_180 <= ideal)
         speed = -speed;
   }
   else if ((current < 0) && (ideal >= 0))
   {
      current_180 = current + 180;
      if (current_180 <= ideal)
         speed = -speed;
   }
   else // (current < 0) && (ideal < 0)  both negative
   {
      if (current > ideal)
         speed = -speed;
   }

   current += speed;
   pEdict->v.v_angle.x = current;
}



void BotChangeYaw (bot_t *pBot, float speed)
{
   edict_t *pEdict = pBot->pEdict;
   float ideal;
   float current;
   float current_180; // current +/- 180 degrees
   float diff;
   float fOld = 0;

   UTIL_ClampAngle (&pEdict->v.ideal_yaw);
   if (g_bInstantTurns)
   {
      pEdict->v.v_angle.y = pEdict->v.ideal_yaw;
      return;
   }

   // turn from the current v_angle yaw to the ideal_yaw by selecting
   // the quickest way to turn to face that direction
   current = pEdict->v.v_angle.y;
   ideal = pEdict->v.ideal_yaw;

   // find the difference in the current and ideal angle
   diff = fabs (current - ideal);

   // check if difference is less than the max degrees per turn
   if (diff < speed)
      speed = diff; // just need to turn a little bit (less than max)

   // Sum up old Yaw Changes
   fOld += pBot->rgfYawHistory[0];
   fOld += pBot->rgfYawHistory[1];

   fOld += speed;
   fOld /= 3;

   pBot->rgfYawHistory[1] = pBot->rgfYawHistory[0];
   pBot->rgfYawHistory[0] = speed;

   speed = fOld;

   // here we have four cases, both angle positive, one positive and
   // the other negative, one negative and the other positive, or
   // both negative.  handle each case separately...

   if ((current >= 0) && (ideal >= 0))  // both positive
   {
      if (current > ideal)
         speed = -speed;
   }
   else if ((current >= 0) && (ideal < 0))
   {
      current_180 = current - 180;

      if (current_180 <= ideal)
         speed = -speed;
   }
   else if ((current < 0) && (ideal >= 0))
   {
      current_180 = current + 180;
      if (current_180 <= ideal)
         speed = -speed;
   }
   else  // (current < 0) && (ideal < 0)  both negative
   {
      if (current > ideal)
         speed = -speed;
   }

   current += speed;
   pEdict->v.v_angle.y = current;
}


bool BotFindWaypoint (bot_t *pBot)
{
   // Finds a Waypoint in the near of the Bot if he lost his Path or if Pathfinding needs
   // to be started over again

   int i, c, wpt_index[3], select_index;
   int covered_wpt = -1;
   float distance, min_distance[3];
   Vector v_src, v_dest;
   TraceResult tr;
   bool bWaypointInUse;
   bot_t *pOtherBot;
   edict_t *pEdict = pBot->pEdict;
   bool bHasHostage = BotHasHostage (pBot);

   for (i = 0; i < 3; i++)
   {
      wpt_index[i] = -1;
      min_distance[i] = 9999.0;
   }

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      // ignore current waypoint and previous recent waypoints...
      if ((i == pBot->curr_wpt_index)
          || (i == pBot->prev_wpt_index[0])
          || (i == pBot->prev_wpt_index[1])
          || (i == pBot->prev_wpt_index[2])
          || (i == pBot->prev_wpt_index[3])
          || (i == pBot->prev_wpt_index[4]))
         continue;

      if (WaypointReachable (pEdict->v.origin, paths[i]->origin, pEdict))
      {
         // Don't use duck Waypoints if Bot got a hostage
         if (bHasHostage && (paths[i]->flags & W_FL_NOHOSTAGE))
            continue;

         bWaypointInUse = FALSE;

         // check if this Waypoint is already in use by another bot
         for (c = 0; c < gpGlobals->maxClients; c++)
         {
            pOtherBot = &bots[c];

            if (pOtherBot->is_used && !pOtherBot->bDead
                && (pOtherBot != pBot) && (pOtherBot->curr_wpt_index == i))
            {
               covered_wpt = i;
               bWaypointInUse = TRUE;
               break;
            }
         }

         if (bWaypointInUse)
            continue;

         distance = (paths[i]->origin - pEdict->v.origin).Length ();

         if (distance < min_distance[0])
         {
            wpt_index[0] = i;
            min_distance[0] = distance;
         }
         else if (distance < min_distance[1])
         {
            wpt_index[1] = i;
            min_distance[1] = distance;
         }
         else if (distance < min_distance[2])
         {
            wpt_index[2] = i;
            min_distance[2] = distance;
         }
      }
   }

   select_index = -1;

   if (wpt_index[2] != -1)
      i = RANDOM_LONG (0, 2);
   else if (wpt_index[1] != -1)
      i = RANDOM_LONG (0, 1);
   else if (wpt_index[0] != -1)
      i = 0;
   else if (covered_wpt != -1)
   {
      wpt_index[0] = covered_wpt;
      i = 0;
   }
   else
   {
      wpt_index[0] = RANDOM_LONG (0, g_iNumWaypoints - 1);
      i = 0;
   }

   select_index = wpt_index[i];

   pBot->prev_wpt_index[4] = pBot->prev_wpt_index[3];
   pBot->prev_wpt_index[3] = pBot->prev_wpt_index[2];
   pBot->prev_wpt_index[2] = pBot->prev_wpt_index[1];
   pBot->prev_wpt_index[1] = pBot->prev_wpt_index[0];
   pBot->prev_wpt_index[0] = pBot->curr_wpt_index;

   pBot->curr_wpt_index = select_index;
   pBot->f_wpt_timeset = gpGlobals->time;

   return (TRUE);
}


inline void GetValidWaypoint (bot_t *pBot)
{
   // Checks if the last Waypoint the Bot was heading for is still valid

   edict_t *pEdict = pBot->pEdict;

   // If Bot hasn't got a Waypoint we need a new one anyway
   if (pBot->curr_wpt_index == -1)
   {
      DeleteSearchNodes (pBot);
      BotFindWaypoint (pBot);
      pBot->wpt_origin = paths[pBot->curr_wpt_index]->origin;

      // FIXME
      // Do some error checks if we got a waypoint
   }

   // If time to get there expired get new one as well
   else if ((pBot->f_wpt_timeset + 3.0 < gpGlobals->time) && FNullEnt (pBot->pBotEnemy))
   {
      DeleteSearchNodes (pBot);
      BotFindWaypoint (pBot);
      pBot->wpt_origin = paths[pBot->curr_wpt_index]->origin;
   }
}


void CTBombPointClear (int iIndex)
{
   // Little Helper routine to tell that a Bomb Waypoint just got visited

   int i;

   for (i = 0; i < MAXNUMBOMBSPOTS; i++)
   {
      if (g_rgiBombSpotsVisited[i] == -1)
      {
         g_rgiBombSpotsVisited[i] = iIndex;
         return;
      }

      else if (g_rgiBombSpotsVisited[i] == iIndex)
         return;
   }
}


bool WasBombPointVisited (int iIndex)
{
   // Little Helper routine to check if a Bomb Waypoint got visited

   int i;

   for (i = 0; i < MAXNUMBOMBSPOTS; i++)
   {
      if (g_rgiBombSpotsVisited[i] == -1)
         return (FALSE);

      else if (g_rgiBombSpotsVisited[i] == iIndex)
         return (TRUE);
   }

   return (FALSE);
}


Vector GetBombPosition (void)
{
   // Stores the Bomb Position as a Vector

   Vector vecBomb = g_vecZero;
   edict_t *pent = NULL;

   while (!FNullEnt (pent = FIND_ENTITY_BY_STRING (pent, "classname", "grenade")))
   {
      if (FStrEq (STRING (pent->v.model), "models/w_c4.mdl"))
      {
         vecBomb = pent->v.origin;
         break;
      }
   }

   assert (vecBomb != g_vecZero);
   return (vecBomb);
}


bool BotHearsBomb (Vector vecBotPos)
{
   // Returns if Bomb is hearable and if so the exact Position as a Vector

   if (g_vecBomb == g_vecZero)
      g_vecBomb = GetBombPosition ();

   if ((vecBotPos - g_vecBomb).Length () < BOMBMAXHEARDISTANCE)
      return (TRUE);

   return (FALSE);
}


int BotChooseBombWaypoint (bot_t *pBot)
{
   // Finds the Best Goal (Bomb) Waypoint for CTs when searching for a planted Bomb

   float min_distance = 9999.0;
   float act_distance;
   int iGoal = 0;
   int iCount = 0;
   int i;
   edict_t *pent = NULL;
   edict_t *pEdict = pBot->pEdict;
   Vector vecPosition;

   if (BotHearsBomb (pEdict->v.origin))
      vecPosition = g_vecBomb;
   else
      vecPosition = pEdict->v.origin;

   // Find nearest Goal Waypoint either to Bomb (if "heard" or Player)
   for (i = 0; i < g_iNumGoalPoints; i++)
   {
      act_distance = (paths[g_rgiGoalWaypoints[i]]->origin - vecPosition).Length ();

      if (act_distance < min_distance)
      {
         min_distance = act_distance;
         iGoal = g_rgiGoalWaypoints[i];
      }
   }

   while (WasBombPointVisited (iGoal))
   {
      if (g_iNumGoalPoints == 1)
         iGoal = g_rgiGoalWaypoints[0];
      else
         iGoal = g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)];

      iCount++;

      if (iCount == g_iNumGoalPoints)
         break;
   }

   return (iGoal);
}


int BotFindDefendWaypoint (bot_t *pBot, Vector vecPosition)
{
   // Tries to find a good waypoint which
   // a) has a Line of Sight to vecPosition and
   // b) provides enough cover
   // c) is far away from the defending position

   int wpt_index[8];
   int min_distance[8];
   int iDistance, i;
   float fMin = 9999.0;
   float fPosMin = 9999.0;
   float fDistance;
   int iSourceIndex;
   int iPosIndex;
   edict_t *pEdict = pBot->pEdict;
   TraceResult tr;
   Vector vecSource;
   Vector vecDest;
   int iExp;
   int index1;
   int index2;
   int tempindex;
   bool bOrderchange;

   for (i = 0; i < 8; i++)
   {
      wpt_index[i] = -1;
      min_distance[i] = 128;
   }

   // Get nearest waypoint to Bot & Position
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      fDistance = (paths[i]->origin - pEdict->v.origin).Length ();

      if (fDistance < fMin)
      {
         iSourceIndex = i;
         fMin = fDistance;
      }

      fDistance = (paths[i]->origin - vecPosition).Length ();
      if (fDistance < fPosMin)
      {
         iPosIndex = i;
         fPosMin = fDistance;
      }
   }

   vecDest = paths[iPosIndex]->origin;

   // Find Best Waypoint now
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      // Exclude Ladder, Goal, Rescue & current Waypoints
      if ((paths[i]->flags & W_FL_LADDER) || (i == iSourceIndex) || !WaypointIsVisible (i, iPosIndex))
         continue;

      // Use the 'real' Pathfinding Distances
      iDistance = GetPathDistance (iSourceIndex, i);

      if (iDistance < 1024)
      {
         vecSource = paths[i]->origin;
         UTIL_TraceLine (vecSource, vecDest, ignore_monsters, ignore_glass, pEdict, &tr);
         if (tr.flFraction != 1.0)
            continue;

         if (iDistance > min_distance[0])
         {
            wpt_index[0] = i;
            min_distance[0] = iDistance;
         }
         else if (iDistance > min_distance[1])
         {
            wpt_index[1] = i;
            min_distance[1] = iDistance;
         }
         else if (iDistance > min_distance[2])
         {
            wpt_index[2] = i;
            min_distance[2] = iDistance;
         }
         else if (iDistance > min_distance[3])
         {
            wpt_index[3] = i;
            min_distance[3] = iDistance;
         }
         else if (iDistance > min_distance[4])
         {
            wpt_index[4] = i;
            min_distance[4] = iDistance;
         }
         else if (iDistance > min_distance[5])
         {
            wpt_index[5] = i;
            min_distance[5] = iDistance;
         }
         else if (iDistance > min_distance[6])
         {
            wpt_index[6] = i;
            min_distance[6] = iDistance;
         }
         else if (iDistance > min_distance[7])
         {
            wpt_index[7] = i;
            min_distance[7] = iDistance;
         }
      }
   }

   // Use statistics if we have them...
   if (g_bUseExperience)
   {
      for (i = 0; i < 8; i++)
      {
         if (wpt_index[i] != -1)
         {
            if (pBot->bot_team == TEAM_CS_TERRORIST)
            {
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam0Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
               iExp >>= 1;
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam1Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
            }
            else
            {
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam1Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
               iExp >>= 1;
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam0Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
            }
         }
      }
   }

   // If not use old method of relying on the wayzone radius
   else
   {
      for (i = 0; i < 8; i++)
         if (wpt_index[i] != -1)
            min_distance[i] -= paths[wpt_index[i]]->Radius * 3;
   }

   // Sort resulting Waypoints for farest distance
   do
   {
      bOrderchange = FALSE;

      for (i = 0; i < 3; i++)
      {
         index1 = wpt_index[i];
         index2 = wpt_index[i + 1];

         if ((index1 != -1) && (index2 != -1))
         {
            if (min_distance[i] > min_distance[i + 1])
            {
               tempindex = wpt_index[i];
               wpt_index[i] = wpt_index[i + 1];
               wpt_index[i + 1] = tempindex;
               tempindex = min_distance[i];
               min_distance[i] = min_distance[i + 1];
               min_distance[i + 1] = tempindex;
               bOrderchange = TRUE;
            }
         }
      }
   }
   while (bOrderchange);

   for (i = 0; i < 8; i++)
   {
      if (wpt_index[i] != -1)
         return (wpt_index[i]);
   }

   // Worst case: If no waypoint was found, just use a random one
   return (RANDOM_LONG (0, g_iNumWaypoints - 1));
}


int BotFindCoverWaypoint (bot_t *pBot, float maxdistance)
{
   // Tries to find a good Cover Waypoint if Bot wants to hide

   int i, j;
   int wpt_index[8];
   int distance,enemydistance, iEnemyWPT;
   int rgiEnemyIndices[MAX_PATH_INDEX];
   int iEnemyNeighbours = 0;
   int min_distance[8];
   float f_min = 9999.0;
   float f_enemymin = 9999.0;
   float f_distance;
   Vector vecEnemy = pBot->vecLastEnemyOrigin;
   edict_t *pEdict = pBot->pEdict;
   int iSourceIndex = pBot->curr_wpt_index;
   bool bNeighbourVisible;
   int iExp;
   int index1;
   int index2;
   int tempindex;
   bool bOrderchange;
   Vector v_source;
   Vector v_dest;
   TraceResult tr;

   // Get Enemies Distance
   // FIXME: Would be better to use the actual Distance returned
   // from Pathfinding because we might get wrong distances here
   f_distance = (vecEnemy- pEdict->v.origin).Length ();

   // Don't move to a position nearer the enemy
   if (maxdistance > f_distance)
      maxdistance = f_distance;
   if (maxdistance < 300)
      maxdistance = 300;

   for (i = 0; i < 8; i++)
   {
      wpt_index[i] = -1;
      min_distance[i] = maxdistance;
   }

   // Get nearest waypoint to enemy & Bot
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      f_distance = (paths[i]->origin - pEdict->v.origin).Length ();

      if (f_distance < f_min)
      {
         iSourceIndex = i;
         f_min = f_distance;
      }

      f_distance = (paths[i]->origin - vecEnemy).Length ();

      if (f_distance < f_enemymin)
      {
         iEnemyWPT = i;
         f_enemymin = f_distance;
      }
   }

   // Now Get Enemies Neigbouring Waypoints
   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      if (paths[iEnemyWPT]->index[i] != -1)
      {
         rgiEnemyIndices[iEnemyNeighbours] = paths[iEnemyWPT]->index[i];
         iEnemyNeighbours++;
      }
   }

   pBot->curr_wpt_index = iSourceIndex;

   // Find Best Waypoint now
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      // Exclude Ladder, current Waypoints
      if ((paths[i]->flags & W_FL_LADDER) || (i == iSourceIndex) || WaypointIsVisible (iEnemyWPT, i))
         continue;

      // Now check neighbour Waypoints for Visibility
      bNeighbourVisible = FALSE;
      for (j = 0; j < iEnemyNeighbours; j++)
      {
         if (WaypointIsVisible (rgiEnemyIndices[j], i))
         {
            bNeighbourVisible = TRUE;
            break;
         }
      }

      if (bNeighbourVisible)
         continue;

      // Use the 'real' Pathfinding Distances
      distance = GetPathDistance (iSourceIndex, i);
      enemydistance = GetPathDistance (iEnemyWPT, i);

      if (distance < enemydistance)
      {
         if (distance < min_distance[0])
         {
            wpt_index[0] = i;
            min_distance[0] = distance;
         }
         else if (distance < min_distance[1])
         {
            wpt_index[1] = i;
            min_distance[1] = distance;
         }
         else if (distance < min_distance[2])
         {
            wpt_index[2] = i;
            min_distance[2] = distance;
         }
         else if (distance < min_distance[3])
         {
            wpt_index[3] = i;
            min_distance[3] = distance;
         }
         else if (distance < min_distance[4])
         {
            wpt_index[4] = i;
            min_distance[4] = distance;
         }
         else if (distance < min_distance[5])
         {
            wpt_index[5] = i;
            min_distance[5] = distance;
         }
         else if (distance < min_distance[6])
         {
            wpt_index[6] = i;
            min_distance[6] = distance;
         }
         else if (distance < min_distance[7])
         {
            wpt_index[7] = i;
            min_distance[7] = distance;
         }
      }
   }

   // Use statistics if we have them...
   if (g_bUseExperience)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
      {
         for (i = 0; i < 8; i++)
         {
            if (wpt_index[i]!= -1)
            {
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam0Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
               iExp >>= 1;
            }
         }
      }
      else
      {
         for (i = 0; i < 8; i++)
         {
            if (wpt_index[i]!= -1)
            {
               iExp = (pBotExperienceData + (wpt_index[i] * g_iNumWaypoints) + wpt_index[i])->uTeam1Damage;
               iExp = (iExp * 100) / 240;
               min_distance[i] = (iExp * 100) / 8192;
               min_distance[i] += iExp;
               iExp >>= 1;
            }
         }
      }

   }

   // If not use old method of relying on the wayzone radius
   else
   {
      for (i = 0; i < 8; i++)
         if (wpt_index[i] != -1)
            min_distance[i] += paths[wpt_index[i]]->Radius * 3;
   }

   // Sort resulting Waypoints for nearest distance
   do
   {
      bOrderchange = FALSE;
      for (i = 0; i < 3; i++)
      {
         index1 = wpt_index[i];
         index2 = wpt_index[i + 1];

         if ((index1 != -1) && (index2 != -1))
         {
            if (min_distance[i] > min_distance[i + 1])
            {
               tempindex = wpt_index[i];
               wpt_index[i] = wpt_index[i + 1];
               wpt_index[i + 1] = tempindex;
               tempindex = min_distance[i];
               min_distance[i] = min_distance[i + 1];
               min_distance[i + 1] = tempindex;
               bOrderchange = TRUE;
            }
         }
      }
   }
   while (bOrderchange);

   // Take the first one which isn't spotted by the enemy
   for (i = 0; i < 8; i++)
   {
      if (wpt_index[i] != -1)
      {
         v_source = pBot->vecLastEnemyOrigin + Vector (0, 0, 36);
         v_dest = paths[wpt_index[i]]->origin;

         UTIL_TraceLine (v_source, v_dest, ignore_monsters, ignore_glass, pEdict, &tr);
         if (tr.flFraction < 1.0)
            return (wpt_index[i]);
      }
   }

   // If all are seen by the enemy, take the first one
   if (wpt_index[0] != -1)
      return (wpt_index[0]);

   // Worst case: if no waypoint was found, just use a random one
   return (RANDOM_LONG (0, g_iNumWaypoints - 1));
}


inline bool IsConnectedWithWaypoint (int a, int b)
{
   // Checks if Waypoint A has a Connection to Waypoint Nr. B

   int ix;

   for (ix = 0; ix < MAX_PATH_INDEX; ix++)
      if (paths[a]->index[ix] == b)
         return (TRUE);

   return (FALSE);
}


bool GetBestNextWaypoint (bot_t *pBot)
{
   // Does a realtime postprocessing of Waypoints returned from
   // Pathfinding, to vary Paths and find best Waypoints on the way

   int iNextWaypointIndex = pBot->pWaypointNodes->NextNode->iIndex;
   int iCurrentWaypointIndex = pBot->pWaypointNodes->iIndex;
   int iPrevWaypointIndex = pBot->curr_wpt_index;
   int ix = 0;
   int iUsedWaypoints[32];
   int num;
   int c;
   edict_t *pEdict = pBot->pEdict;
   bot_t *pOtherBot;
   bool bWaypointInUse = FALSE;

   // Get waypoints used by other Bots
   for (c = 0; c < gpGlobals->maxClients; c++)
   {
      pOtherBot = &bots[c];

      if (pOtherBot->is_used && !pOtherBot->bDead && (pOtherBot != pBot))
         iUsedWaypoints[c] = pOtherBot->curr_wpt_index;
   }

   for (c = 0; c < gpGlobals->maxClients; c++)
   {
      if (iUsedWaypoints[c] == iCurrentWaypointIndex)
      {
         bWaypointInUse = TRUE;
         break;
      }
   }

   if (bWaypointInUse)
   {
      while (ix < MAX_PATH_INDEX)
      {
         num = paths[iPrevWaypointIndex]->index[ix];
         if (num != -1)
         {
            if (IsConnectedWithWaypoint (num, iNextWaypointIndex)
                && IsConnectedWithWaypoint (num, iPrevWaypointIndex))
            {
               // Don't use ladder waypoints as alternative
               if (paths[num]->flags & W_FL_LADDER)
               {
                  ix++;
                  continue;
               }

               // check if this Waypoint is already in use by another bot
               bWaypointInUse = FALSE;

               for (c = 0; c < gpGlobals->maxClients; c++)
               {
                  if (iUsedWaypoints[c] == num)
                  {
                     bWaypointInUse = TRUE;
                     break;
                  }
               }

               // Waypoint not used by another Bot - feel free to use it
               if (!bWaypointInUse)
               {
                  pBot->pWaypointNodes->iIndex = num;
                  return (TRUE);
               }
            }
         }

         ix++;
      }
   }

   return (FALSE);
}


bool BotHeadTowardWaypoint (bot_t *pBot)
{
   // Advances in our Pathfinding list and sets the appropiate Destination Origins for this Bot

   int i, c;
   Vector v_src, v_dest;
   TraceResult tr;
   edict_t *pEdict = pBot->pEdict;
   int iWaypoint;
   float fKills;
   float fTime;
   PATH *p;
   bool will_jump;
   float jump_distance;

   // Check if old waypoints is still reliable
   GetValidWaypoint (pBot);

   // No Waypoints from pathfinding ?
   if (pBot->pWaypointNodes == NULL)
      return (FALSE);

   // Reset Travel Flags (jumping etc.)
   pBot->curr_travel_flags = 0;

   // Advance in List
   pBot->pWaypointNodes = pBot->pWaypointNodes->NextNode;

   // We're not at the end of the List ?
   if (pBot->pWaypointNodes != NULL)
   {
      // If in between a route, postprocess the waypoint (find better alternatives)
      if ((pBot->pWaypointNodes != pBot->pWayNodesStart)
          && (pBot->pWaypointNodes->NextNode != NULL))
      {
         GetBestNextWaypoint (pBot);

         pBot->fMinSpeed = pEdict->v.maxspeed;
         if ((BotGetSafeTask (pBot)->iTask == TASK_NORMAL) && !g_bBombPlanted)
         {
            pBot->iCampButtons = 0;
            iWaypoint = pBot->pWaypointNodes->NextNode->iIndex;

            if (pBot->bot_team == TEAM_CS_TERRORIST)
               fKills = (pBotExperienceData + (iWaypoint * g_iNumWaypoints) + iWaypoint)->uTeam0Damage;
            else
               fKills = (pBotExperienceData + (iWaypoint * g_iNumWaypoints) + iWaypoint)->uTeam1Damage;

            if ((fKills > 1) && (g_fTimeRoundMid > gpGlobals->time) && (g_cKillHistory > 0))
            {
               fKills = (fKills * 100) / g_cKillHistory;
               fKills /= 100;

               switch (pBot->bot_personality)
               {
               case 1: // Psycho
                  fKills /= 3;
                  break;
               default:
                  fKills /= 2;
               }

               if ((pBot->fBaseAgressionLevel < fKills)
                   && !((pBot->bot_team == TEAM_CS_COUNTER) && g_bBombPlanted))
               {
                  fTime = pBot->fFearLevel * (g_fTimeRoundMid - gpGlobals->time) * 0.5;

                  // Push camp task on to stack
                  bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, gpGlobals->time + fTime, TRUE};
                  BotPushTask (pBot, &TempTask);

                  // Push Move Command
                  TempTask.iTask = TASK_MOVETOPOSITION;
                  TempTask.fDesire = TASKPRI_MOVETOPOSITION;
                  TempTask.iData = BotFindDefendWaypoint (pBot, paths[iWaypoint]->origin);
                  BotPushTask (pBot, &TempTask);
                  pBot->iCampButtons |= IN_DUCK;
               }
            }
            else if (g_bBotsCanPause && !pBot->bOnLadder
                     && !pBot->bInWater && (pBot->curr_travel_flags == 0)
                     && (pEdict->v.flags & FL_ONGROUND))
            {
               if (fKills == pBot->fBaseAgressionLevel)
                  pBot->iCampButtons |= IN_DUCK;
               else if (RANDOM_LONG (1, 100) > pBot->bot_skill + RANDOM_LONG (1, 20))
                  pBot->fMinSpeed = 120.0;
            }
         }
      }

      if (pBot->pWaypointNodes != NULL)
      {
         // Find out about connection flags
         if (pBot->curr_wpt_index != -1)
         {
            p = paths[pBot->curr_wpt_index];

            for (i = 0; i < MAX_PATH_INDEX; i++)
            {
               if (p->index[i] == pBot->pWaypointNodes->iIndex)
               {
                  pBot->curr_travel_flags = p->connectflag[i];
                  pBot->vecDesiredVelocity = p->vecConnectVel[i];
                  pBot->bJumpDone = FALSE;
                  break;
               }
            }

            // Find out about FUTURE connection flags
            will_jump = FALSE;
            if (pBot->pWaypointNodes->NextNode != NULL)
            {
               for (i = 0; i < MAX_PATH_INDEX; i++)
               {
                  if ((paths[pBot->pWaypointNodes->iIndex]->index[i] == pBot->pWaypointNodes->NextNode->iIndex)
                      && (paths[pBot->pWaypointNodes->iIndex]->connectflag[i] & C_FL_JUMP))
                  {
                     will_jump = TRUE;
                     v_src = paths[pBot->pWaypointNodes->iIndex]->origin;
                     v_dest = paths[pBot->pWaypointNodes->NextNode->iIndex]->origin;
                     jump_distance = (paths[pBot->pWaypointNodes->iIndex]->origin - paths[pBot->pWaypointNodes->NextNode->iIndex]->origin).Length ();
                     break;
                  }
               }
            }

            // is there a jump waypoint right ahead and do we need to draw out the knife ?
            if (will_jump
                && ((jump_distance > 220)
                    || ((v_dest.z + 32 > v_src.z) && (jump_distance > 150))
                    || (((v_dest - v_src).Length2D () < 50) && (jump_distance > 60)))
                && FNullEnt (pBot->pBotEnemy))
               FakeClientCommand (pEdict, "weapon_knife\n"); // draw out the knife if needed

            // Bot not already on ladder ? but will be soon ?
            if (!pBot->bOnLadder && (paths[pBot->pWaypointNodes->iIndex]->flags & W_FL_LADDER))
            {
               // Get ladder waypoints used by other (first moving) Bots
               for (c = 0; c < gpGlobals->maxClients; c++)
               {
                  // If another Bot uses this ladder, wait 3 secs
                  if (bots[c].is_used && !bots[c].bDead && (&bots[c] != pBot)
                      && (bots[c].curr_wpt_index == pBot->pWaypointNodes->iIndex))
                  {
                     bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
                     BotPushTask (pBot, &TempTask);
                     return (TRUE);
                  }
               }
            }
         }

         pBot->curr_wpt_index = pBot->pWaypointNodes->iIndex;
      }
   }

   pBot->wpt_origin = paths[pBot->curr_wpt_index]->origin;

   // If wayzone radius != 0 vary origin a bit depending on body angles
   if (paths[pBot->curr_wpt_index]->Radius != 0)
   {
      MAKE_VECTORS (pEdict->v.angles);
      Vector v_x = pBot->wpt_origin + gpGlobals->v_right * RANDOM_FLOAT (-paths[pBot->curr_wpt_index]->Radius, paths[pBot->curr_wpt_index]->Radius);
      Vector v_y = pBot->wpt_origin + gpGlobals->v_forward * RANDOM_FLOAT (0, paths[pBot->curr_wpt_index]->Radius);
      pBot->wpt_origin = (v_x + v_y) / 2;
   }

   // Bot on Ladder ?
   if (pBot->bOnLadder)
   {
      v_src = pEdict->v.origin;
      v_src.z = pEdict->v.absmin.z;
      v_dest = pBot->wpt_origin;

      // Is the Bot inside a Ladder Cage ? Then we need to adjust
      // the Waypoint Origin to make sure Bot doesn't get stuck
      TRACE_LINE (v_src, v_dest, ignore_monsters, pEdict, &tr);
      if (tr.flFraction < 1.0)
         pBot->wpt_origin = pBot->wpt_origin + (pEdict->v.origin - pBot->wpt_origin) / 2 + Vector (0, 0, 32);

      // Uncomment this to have a temp line showing the direction to the destination waypoint
      //WaypointDrawBeam (pEdict->v.origin, pBot->wpt_origin, 10, 255, 255, 255);
      //WaypointDrawBeam (pBot->wpt_origin + Vector (0, 0, -20), pBot->wpt_origin + Vector (0, 0, 20), 10, 255, 255, 255);
   }

   pBot->f_wpt_timeset = gpGlobals->time;

   return (TRUE);
}


bool BotCantMoveForward (bot_t *pBot, Vector vNormal, TraceResult *tr)
{
   // Checks if Bot is blocked in his movement direction (excluding doors)
   // use some TraceLines to determine if anything is blocking the current path of the bot.

   edict_t *pEdict = pBot->pEdict;
   Vector v_src, v_forward, v_center;

   v_center = pEdict->v.angles;
   v_center.z = 0;
   v_center.x = 0;
   MAKE_VECTORS (v_center);

   // first do a trace from the bot's eyes forward...

   v_src = pEdict->v.origin + pEdict->v.view_ofs; // EyePosition ()
   v_forward = v_src + vNormal * 24;

   // trace from the bot's eyes straight forward...
   TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if (tr->flFraction < 1.0)
   {
      if (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) == 0)
         return (FALSE);

      return (TRUE); // bot's head will hit something
   }

   // bot's head is clear, check at shoulder level...
   // trace from the bot's shoulder left diagonal forward to the right shoulder...
   v_src = pEdict->v.origin + pEdict->v.view_ofs + Vector (0, 0, -16) + gpGlobals->v_right * -16;
   v_forward = pEdict->v.origin + pEdict->v.view_ofs + Vector (0, 0, -16) + gpGlobals->v_right * 16 + vNormal * 24;

   TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
      return (TRUE); // bot's body will hit something

   // bot's head is clear, check at shoulder level...
   // trace from the bot's shoulder right diagonal forward to the left shoulder...
   v_src = pEdict->v.origin + pEdict->v.view_ofs + Vector (0, 0, -16) + gpGlobals->v_right * 16;
   v_forward = pEdict->v.origin + pEdict->v.view_ofs + Vector (0, 0, -16) + gpGlobals->v_right * -16 + vNormal * 24;

   TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
      return (TRUE); // bot's body will hit something

   // Now check below Waist

   if (pEdict->v.flags & FL_DUCKING)
   {
      v_src = pEdict->v.origin + Vector (0, 0, -19 + 19);
      v_forward = v_src + Vector (0, 0, 10) + vNormal * 24;

      TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

      // check if the trace hit something...
      if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
         return (TRUE); // bot's body will hit something

      v_src = pEdict->v.origin + Vector (0, 0, -19 + 19);
      v_forward = v_src + vNormal * 24;

      TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

      // check if the trace hit something...
      if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
         return (TRUE); // bot's body will hit something
   }
   else
   {
      // Trace from the left Waist to the right forward Waist Pos
      v_src = pEdict->v.origin + Vector (0, 0, -17) + gpGlobals->v_right * -16;
      v_forward = pEdict->v.origin + Vector (0, 0, -17) + gpGlobals->v_right * 16 + vNormal * 24;

      // trace from the bot's waist straight forward...
      TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

      // check if the trace hit something...
      if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
         return (TRUE); // bot's body will hit something

      // Trace from the left Waist to the right forward Waist Pos
      v_src = pEdict->v.origin + Vector (0, 0, -17) + gpGlobals->v_right * 16;
      v_forward = pEdict->v.origin + Vector (0, 0, -17) + gpGlobals->v_right * -16 + vNormal * 24;

      TRACE_LINE (v_src, v_forward, ignore_monsters, pEdict, tr);

      // check if the trace hit something...
      if ((tr->flFraction < 1.0) && (strncmp ("func_door", STRING (tr->pHit->v.classname), 9) != 0))
         return (TRUE); // bot's body will hit something
   }

   return (FALSE); // bot can move forward, return (FALSE)
}


bool BotCanStrafeLeft (bot_t *pBot, TraceResult *tr)
{
   // Check if Bot can move sideways

   edict_t *pEdict = pBot->pEdict;
   Vector v_src;
   Vector v_left;

   MAKE_VECTORS (pEdict->v.v_angle);
   v_src = pEdict->v.origin;
   v_left = v_src + gpGlobals->v_right * -40;

   // trace from the bot's waist straight left...
   TRACE_LINE (v_src, v_left, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if (tr->flFraction < 1.0)
      return (FALSE); // bot's body will hit something

   v_left = v_left + gpGlobals->v_forward * 40;

   // trace from the strafe pos straight forward...
   TRACE_LINE (v_src, v_left, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if (tr->flFraction < 1.0)
      return (FALSE); // bot's body will hit something

   return (TRUE);
}


bool BotCanStrafeRight (bot_t *pBot, TraceResult *tr)
{
   // Check if Bot can move sideways

   edict_t *pEdict = pBot->pEdict;
   Vector v_src;
   Vector v_right;

   MAKE_VECTORS (pEdict->v.v_angle);
   v_src = pEdict->v.origin;
   v_right = v_src + gpGlobals->v_right * 40;

   // trace from the bot's waist straight right...
   TRACE_LINE (v_src, v_right, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if (tr->flFraction < 1.0)
      return (FALSE); // bot's body will hit something

   v_right = v_right + gpGlobals->v_forward * 40;

   // trace from the strafe pos straight forward...
   TRACE_LINE (v_src, v_right, ignore_monsters, pEdict, tr);

   // check if the trace hit something...
   if (tr->flFraction < 1.0)
      return (FALSE); // bot's body will hit something

   return (TRUE);
}


bool BotCanJumpUp (bot_t *pBot, Vector vNormal)
{
   // Check if Bot can jump over some obstacle

   TraceResult tr;
   Vector v_jump;
   Vector v_source;
   Vector v_dest;
   edict_t *pEdict = pBot->pEdict;

   // Can't jump if not on ground and not on ladder/swimming
   if (!(pEdict->v.flags & (FL_ONGROUND | FL_PARTIALGROUND)) && (pBot->bOnLadder || !pBot->bInWater))
      return (FALSE);

   // convert current view angle to vectors for TraceLine math...

   v_jump = pEdict->v.angles;
   v_jump.x = 0; // reset pitch to 0 (level horizontally)
   v_jump.z = 0; // reset roll to 0 (straight up and down)

   MAKE_VECTORS (v_jump);

   // Check for normal jump height first...

   v_source = pEdict->v.origin + Vector (0, 0, -36 + 45);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   if (tr.flFraction < 1.0)
      goto CheckDuckJump;
   else
   {
      // now trace from jump height upward to check for obstructions...
      v_source = v_dest;
      v_dest.z = v_dest.z + 37;

      TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

      if (tr.flFraction < 1.0)
         return (FALSE);
   }

   // now check same height to one side of the bot...
   v_source = pEdict->v.origin + gpGlobals->v_right * 16 + Vector (0, 0, -36 + 45);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      goto CheckDuckJump;

   // now trace from jump height upward to check for obstructions...
   v_source = v_dest;
   v_dest.z = v_dest.z + 37;

   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now check same height on the other side of the bot...
   v_source = pEdict->v.origin + (-gpGlobals->v_right * 16) + Vector (0, 0, -36 + 45);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      goto CheckDuckJump;

   // now trace from jump height upward to check for obstructions...
   v_source = v_dest;
   v_dest.z = v_dest.z + 37;

   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   return (TRUE);

   // Here we check if a Duck Jump would work...
CheckDuckJump:
   // use center of the body first...

   // maximum duck jump height is 62, so check one unit above that (63)
   v_source = pEdict->v.origin + Vector (0, 0, -36 + 63);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   if (tr.flFraction < 1.0)
      return (FALSE);
   else
   {
      // now trace from jump height upward to check for obstructions...
      v_source = v_dest;
      v_dest.z = v_dest.z + 37;

      TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

      // if trace hit something, check duckjump
      if (tr.flFraction < 1.0)
         return (FALSE);
   }

   // now check same height to one side of the bot...
   v_source = pEdict->v.origin + gpGlobals->v_right * 16 + Vector (0, 0, -36 + 63);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now trace from jump height upward to check for obstructions...
   v_source = v_dest;
   v_dest.z = v_dest.z + 37;

   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now check same height on the other side of the bot...
   v_source = pEdict->v.origin + (-gpGlobals->v_right * 16) + Vector (0, 0, -36 + 63);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at maximum jump height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now trace from jump height upward to check for obstructions...
   v_source = v_dest;
   v_dest.z = v_dest.z + 37;

   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   return (TRUE);
}


bool BotCanDuckUnder (bot_t *pBot, Vector vNormal)
{
   // Check if Bot can duck under Obstacle

   TraceResult tr;
   Vector v_duck, v_baseheight,v_source, v_dest;
   edict_t *pEdict = pBot->pEdict;

   // convert current view angle to vectors for TraceLine math...

   v_duck = pEdict->v.angles;
   v_duck.x = 0; // reset pitch to 0 (level horizontally)
   v_duck.z = 0; // reset roll to 0 (straight up and down)

   MAKE_VECTORS (v_duck);

   // use center of the body first...

   if (pEdict->v.flags & FL_DUCKING)
      v_baseheight = pEdict->v.origin + Vector (0, 0, -17);
   else
      v_baseheight = pEdict->v.origin;

   v_source = v_baseheight;
   v_dest = v_source + vNormal * 32;

   // trace a line forward at duck height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now check same height to one side of the bot...
   v_source = v_baseheight + gpGlobals->v_right * 16;
   v_dest = v_source + vNormal * 32;

   // trace a line forward at duck height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   // now check same height on the other side of the bot...
   v_source = v_baseheight + (-gpGlobals->v_right * 16);
   v_dest = v_source + vNormal * 32;

   // trace a line forward at duck height...
   TRACE_LINE (v_source, v_dest, ignore_monsters, pEdict, &tr);

   // if trace hit something, return (FALSE)
   if (tr.flFraction < 1.0)
      return (FALSE);

   return (TRUE);
}


bool BotFollowUser (bot_t *pBot)
{
   // Check if Bot can still follow a User

   bool user_visible;
   float f_distance;

   if (FNullEnt (pBot->pBotUser))
      return (FALSE);

   if (!IsAlive (pBot->pBotUser))
   {
      // the bot's user is dead!
      pBot->pBotUser = NULL;
      return (FALSE);
   }

   edict_t *pEdict = pBot->pEdict;
   Vector vecUser;

   user_visible = FVisible (pBot->pBotUser->v.origin, pEdict);

   // check if the "user" is still visible or if the user has been visible
   // in the last 5 seconds (or the player just starting "using" the bot)

   if (user_visible || (pBot->f_bot_use_time + 5 > gpGlobals->time))
   {
      if (user_visible)
         pBot->f_bot_use_time = gpGlobals->time; // reset "last visible time"

      Vector v_user = pBot->pBotUser->v.origin - pEdict->v.origin;
      f_distance = v_user.Length (); // how far away is the "user"?

      if (f_distance > 150)      // run if distance to enemy is far
         pBot->f_move_speed = pEdict->v.maxspeed;

      else if (f_distance > 80)  // don't move
         pBot->f_move_speed = 0.0;
      else
         pBot->f_move_speed = -pEdict->v.maxspeed;

      return (TRUE);
   }
   else
   {
      // person to follow has gone out of sight...
      pBot->pBotUser = NULL;

      return (FALSE);
   }
}


bool BotIsBlockedLeft (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   Vector v_src, v_left;
   TraceResult tr;

   int iDirection = 48;

   if (pBot->f_move_speed < 0)
      iDirection = -48;

   MAKE_VECTORS (pEdict->v.angles);

   // do a trace to the left...

   v_src = pEdict->v.origin;
   v_left = v_src + (gpGlobals->v_forward * iDirection) + (gpGlobals->v_right * -48); // 48 units to the left

   TRACE_LINE (v_src, v_left, ignore_monsters, pEdict, &tr);

   // check if the trace hit something...
   if ((tr.flFraction < 1.0) && (strncmp ("func_door", STRING (tr.pHit->v.classname), 9) != 0))
      return (TRUE);

   return (FALSE);
}


bool BotIsBlockedRight (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   Vector v_src, v_left;
   TraceResult tr;

   int iDirection = 48;

   if (pBot->f_move_speed < 0)
      iDirection = -48;
   MAKE_VECTORS (pEdict->v.angles);

   // do a trace to the left...

   v_src = pEdict->v.origin;
   v_left = v_src + (gpGlobals->v_forward * iDirection) + (gpGlobals->v_right * 48); // 48 units to the right

   TRACE_LINE (v_src, v_left, ignore_monsters, pEdict, &tr);

   // check if the trace hit something...
   if ((tr.flFraction < 1.0) && (strncmp ("func_door", STRING (tr.pHit->v.classname), 9) != 0))
      return (TRUE);

   return (FALSE);
}


bool BotCheckWallOnLeft (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   Vector v_src, v_left;
   TraceResult tr;

   MAKE_VECTORS (pEdict->v.angles);

   // do a trace to the left...

   v_src = pEdict->v.origin;
   v_left = v_src + (-gpGlobals->v_right * 40); // 40 units to the left

   TRACE_LINE (v_src, v_left, ignore_monsters, pEdict, &tr);

   // check if the trace hit something...
   if (tr.flFraction < 1.0)
      return (TRUE);

   return (FALSE);
}


bool BotCheckWallOnRight (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   Vector v_src, v_right;
   TraceResult tr;

   MAKE_VECTORS (pEdict->v.angles);

   // do a trace to the right...

   v_src = pEdict->v.origin;
   v_right = v_src + gpGlobals->v_right * 40; // 40 units to the right

   TRACE_LINE (v_src, v_right, ignore_monsters, pEdict, &tr);

   // check if the trace hit something...
   if (tr.flFraction < 1.0)
      return (TRUE);

   return (FALSE);
}


void BotGetCampDirection (bot_t *pBot, Vector *vecDest)
{
   // Check if View on last Enemy Position is blocked - replace with better Vector then
   // Mostly used for getting a good Camping Direction Vector if not camping on a camp waypoint

   TraceResult tr;
   edict_t *pEdict;
   Vector vecSource;
   float distance1;
   float min_distance1;
   float distance2;
   float min_distance2;
   float f_length;
   int iLookAtWaypoint;
   int indexbot;
   int indexenemy;
   int i;

   pEdict = pBot->pEdict;
   vecSource = pEdict->v.origin + pEdict->v.view_ofs; // EyePosition ()

   TRACE_LINE (vecSource, *vecDest, ignore_monsters, pEdict, &tr);

   // check if the trace hit something...
   if (tr.flFraction < 1.0)
   {
      min_distance1 = 9999.0;
      min_distance2 = 9999.0;
      f_length = (tr.vecEndPos - vecSource).Length ();

      if (f_length > 100)
         return;

      // Find Nearest Waypoint to Bot and Position
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         distance1 = (paths[i]->origin - pEdict->v.origin).Length ();

         if (distance1 < min_distance1)
         {
            min_distance1 = distance1;
            indexbot = i;
         }

         distance2 = (paths[i]->origin - *vecDest).Length ();

         if (distance2 < min_distance2)
         {
            min_distance2 = distance2;
            indexenemy = i;
         }
      }

      min_distance1 = 9999.0;
      iLookAtWaypoint = -1;

      for (i = 0; i < MAX_PATH_INDEX; i++)
      {
         if (paths[indexbot]->index[i] == -1)
            continue;

         distance1 = GetPathDistance (paths[indexbot]->index[i], indexenemy);

         if (distance1 < min_distance1)
         {
            min_distance1 = distance1;
            iLookAtWaypoint = i;
         }
      }

      if ((iLookAtWaypoint != -1) && (iLookAtWaypoint < g_iNumWaypoints))
         *vecDest = paths[iLookAtWaypoint]->origin;
   }
}


void BotPlayRadioMessage (bot_t *pBot, int iMessage)
{
   // Inserts the Radio Message into the Message Queue

   pBot->iRadioSelect = iMessage;
   BotPushMessageQueue (pBot, MSG_CS_RADIO);
}


void BotCheckMessageQueue (bot_t *pBot)
{
   // Checks and executes pending Messages

   int iCurrentMSG;

   // No new message ?
   if (pBot->iActMessageIndex == pBot->iPushMessageIndex)
      return;

   // Get Message from Stack
   iCurrentMSG = BotGetMessageQueue (pBot);

   switch (iCurrentMSG)
   {
      // General Radio Message issued
      case MSG_CS_RADIO:

         // If last Bot Radio Command (global) happened just a second ago, delay response
         if (g_rgfLastRadioTime[pBot->bot_team - 1] + 1 < gpGlobals->time)
         {
            // If same message like previous just do a yes/no
            if ((pBot->iRadioSelect != RADIO_AFFIRMATIVE)
                && (pBot->iRadioSelect != RADIO_NEGATIVE)
                && (pBot->iRadioSelect != RADIO_REPORTINGIN))
            {
               if ((pBot->iRadioSelect == g_rgfLastRadio[pBot->bot_team - 1])
                   && (g_rgfLastRadioTime[pBot->bot_team - 1] + 1.5 > gpGlobals->time))
                  pBot->iRadioSelect = RADIO_AFFIRMATIVE;
               else
                  g_rgfLastRadio[pBot->bot_team - 1] = pBot->iRadioSelect;
            }

            if (pBot->iRadioSelect == RADIO_REPORTINGIN)
            {
               char szReport[80];
               int iTask = BotGetSafeTask (pBot)->iTask;
               int iWPT = pBot->pTasks->iData;

               switch (iTask)
               {
               case TASK_NORMAL:
                  if (iWPT != -1)
                  {
                     if (paths[iWPT]->flags & W_FL_GOAL)
                        sprintf (szReport, "Heading for a Map Goal!");
                     else if (paths[iWPT]->flags & W_FL_RESCUE)
                        sprintf (szReport, "Heading to Rescue Point");
                     else if (paths[iWPT]->flags & W_FL_CAMP)
                        sprintf (szReport, "Moving to Camp Spot");
                     else
                        sprintf (szReport, "Roaming around");
                  }
                  else
                     sprintf (szReport, "Roaming around");
                  break;
               case TASK_MOVETOPOSITION:
                  sprintf (szReport, "Moving to position");
                  break;
               case TASK_FOLLOWUSER:
                  if (!FNullEnt (pBot->pBotUser))
                     sprintf (szReport, "Following %s", STRING (pBot->pBotUser->v.netname));
                  break;
               case TASK_WAITFORGO:
                  sprintf (szReport, "Waiting for GO!");
                  break;
               case TASK_CAMP:
                  sprintf (szReport, "Camping...");
                  break;
               case TASK_PLANTBOMB:
                  sprintf (szReport, "Planting the Bomb!");
                  break;
               case TASK_DEFUSEBOMB:
                  sprintf (szReport, "Defusing the Bomb!");
                  break;
               case TASK_ATTACK:
                  if (!FNullEnt (pBot->pBotEnemy))
                     sprintf (szReport, "Attacking %s", STRING (pBot->pBotEnemy->v.netname));
                  break;
               case TASK_ENEMYHUNT:
                  if (!FNullEnt (pBot->pLastEnemy))
                     sprintf (szReport, "Hunting %s", STRING (pBot->pLastEnemy->v.netname));
                  break;
               case TASK_SEEKCOVER:
                  sprintf (szReport, "Fleeing from Battle");
                  break;
               case TASK_HIDE:
                  sprintf (szReport, "Hiding from Enemy");
                  break;
               default:
                  sprintf (szReport, "Nothing special here...");
                  break;
               }

               FakeClientCommand (pBot->pEdict, "say_team %s\n", szReport);
            }

            if (pBot->iRadioSelect < 10)
               FakeClientCommand (pBot->pEdict, "radio1;menuselect %d\n", pBot->iRadioSelect);
            else if (pBot->iRadioSelect < 20)
               FakeClientCommand (pBot->pEdict, "radio2;menuselect %d\n", pBot->iRadioSelect - 10);
            else
               FakeClientCommand (pBot->pEdict, "radio3;menuselect %d\n", pBot->iRadioSelect - 20);

            pBot->iRadioSelect = 0;

            // Store last radio usage
            g_rgfLastRadioTime[pBot->bot_team - 1] = gpGlobals->time;
         }
         else
            BotPushMessageQueue (pBot, MSG_CS_RADIO);
         break;

      // Team independant Saytext
      case MSG_CS_SAY:

         char szMessage[256];
         int iEntIndex;
         int bot_index;

         FakeClientCommand (pBot->pEdict, "say %s\n", pBot->szMiscStrings);

         // Notify other Bots of the spoken Text otherwise Bots won't respond to other Bots
         // (Network Messages aren't sent to Bots)
         iEntIndex = ENTINDEX (pBot->pEdict);

         // Add this so the Chat Parser doesn't get confused
         sprintf (szMessage, "%s:%s", STRING (pBot->pEdict->v.netname), pBot->szMiscStrings);

         for (bot_index = 0; bot_index < gpGlobals->maxClients; bot_index++)
         {
            bot_t *pOtherBot = &bots[bot_index];

            if (pOtherBot->is_used && !FNullEnt (pOtherBot->pEdict) && (pOtherBot != pBot))
            {
               if (!pOtherBot->bDead)
               {
                  pOtherBot->SaytextBuffer.iEntityIndex = iEntIndex;
                  strcpy (pOtherBot->SaytextBuffer.szSayText, szMessage);
               }

               pOtherBot->SaytextBuffer.fTimeNextChat = gpGlobals->time + pOtherBot->SaytextBuffer.fChatDelay;
            }
         }

         break;

      default:
         break;
   }

   return;
}


void BotBuyStuff (bot_t *pBot)
{
   // Does all the work in selecting correct Buy Menus for most Weapons/Items

   int iCount = 0;
   int iFoundWeapons = 0;
   int iBuyChoices[NUM_WEAPONS];
   int iChosenWeapon;
   edict_t *pEdict = pBot->pEdict;

   // If Bot has finished buying
   if (pBot->iBuyCount == 0)
      return;

   // If Fun-Mode no need to buy
   if (g_bJasonMode)
   {
      pBot->iBuyCount = 0;
      SelectWeaponByName (pBot, "weapon_knife");
      return;
   }

   // Prevent VIP from buying
   if ((g_iMapType & MAP_AS)
       && (strcmp ("vip", INFOKEY_VALUE (GET_INFOKEYBUFFER (pEdict), "model")) == 0))
   {
      pBot->iBuyCount = 0;
      pBot->bIsVIP = TRUE;
      pBot->byPathType = 2;
      return;
   }

   // Needs a Weapon ?
   if (pBot->iBuyCount == 1)
   {
      if (BotHasPrimaryWeapon (pBot) || BotHasShield (pBot))
      {
         pBot->iBuyCount = 5; // only buy ammo & items
         pBot->pEdict->v.button |= IN_RELOAD;
         return;
      }

      if (pBot->bot_money > 650)
      {
         // Select the Priority Tab for this Personality
         int *ptrWeaponTab = ptrWeaponPrefs[pBot->bot_personality];

         // Start from most desired Weapon
         ptrWeaponTab += NUM_WEAPONS;

         do
         {
            ptrWeaponTab--;
            assert ((*ptrWeaponTab > -1) && (*ptrWeaponTab < NUM_WEAPONS));
            pBot->pSelected_weapon = &cs_weapon_select[*ptrWeaponTab];
            iCount++;

            // Weapon available for every Team ?
            if (g_iMapType & MAP_AS)
            {
               if ((pBot->pSelected_weapon->iTeamAS != 2)
                   && (pBot->pSelected_weapon->iTeamAS != pBot->bot_team - 1))
                  continue;
            }
            else
            {
               if ((pBot->pSelected_weapon->iTeamStandard != 2)
                   && (pBot->pSelected_weapon->iTeamStandard != pBot->bot_team - 1))
                  continue;
            }

            if (pBot->pSelected_weapon->iPrice <= pBot->bot_money)
               iBuyChoices[iFoundWeapons++] = *ptrWeaponTab;
         }
         while ((iCount < NUM_WEAPONS) && (iFoundWeapons < 4));

         // Found a desired weapon ?
         if (iFoundWeapons > 0)
         {
            // Choose randomly from the best ones...
            if (iFoundWeapons > 1)
               iChosenWeapon = iBuyChoices[RANDOM_LONG (0, iFoundWeapons - 1)];
            else
               iChosenWeapon = iBuyChoices[iFoundWeapons - 1];

            pBot->pSelected_weapon = &cs_weapon_select[iChosenWeapon];

            if (g_bIsOldCS15)
               FakeClientCommand (pEdict, "%s\n", pBot->pSelected_weapon->buy_command);
            else
               FakeClientCommand (pEdict, "%s\n", pBot->pSelected_weapon->buy_shortcut);
         }
      }

      pBot->iBuyCount++;
      pBot->f_buy_time = gpGlobals->time + RANDOM_FLOAT (0.3, 0.8);
      return;
   }

   // Needs Ammo ?
   else if (pBot->iBuyCount < 4)
   {
      if (!BotHasPrimaryWeapon (pBot)) // Pistol ?
      {
         if (g_bIsOldCS15)
            FakeClientCommand (pEdict, "buyammo2\n");
         else
            FakeClientCommand (pEdict, "secammo\n");
      }
      else
      {
         if (g_bIsOldCS15)
            FakeClientCommand (pEdict, "buyammo1\n");
         else
            FakeClientCommand (pEdict, "primammo\n");
      }

      pBot->iBuyCount++;
      pBot->f_buy_time = gpGlobals->time + RANDOM_FLOAT (0.2, 0.5);
      return;
   }

   // Needs an Item ?
   else if (pBot->iBuyCount < 7)
   {
      // Care first about buying Armor
      if (pBot->iBuyCount == 4)
      {
         if ((pBot->pEdict->v.armorvalue == 0) && (pBot->bot_money > 650))
         {
            if (pBot->bot_money > 1000)
            {
               if (g_bIsOldCS15)
                  FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 2\n");
               else
                  FakeClientCommand (pEdict, "vesthelm\n");
            }
            else
            {
               if (g_bIsOldCS15)
                  FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 1\n");
               else
                  FakeClientCommand (pEdict, "vest\n");
            }
         }
      }

      // Buy Grenade or Defuse Kit
      else
      {
         if (pBot->bot_money > 300)
         {
            // If Defusion Map & Counter buy Defusion Kit
            if ((g_iMapType & MAP_DE) && (pBot->bot_team == TEAM_CS_COUNTER) && !pBot->b_has_defuse_kit)
            {
               if (g_bIsOldCS15)
                  FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 6\n");
               else
                  FakeClientCommand (pEdict, "defuser\n");
            }

            // Else buy Grenade
            else
            {
               int iGrenadeType = RANDOM_LONG (1, 100);

               // Focus on HE Grenades
               if (iGrenadeType < 70)
               {
                  if (g_bIsOldCS15)
                     FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 4\n");
                  else
                     FakeClientCommand (pEdict, "hegren\n");
               }
               else if (iGrenadeType < 90)
               {
                  if (g_bIsOldCS15)
                     FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 5\n");
                  else
                     FakeClientCommand (pEdict, "sgren\n");
               }
               else if (iGrenadeType < 100)
               {
                  if (g_bIsOldCS15)
                     FakeClientCommand (pEdict, "buy;menuselect 8;menuselect 3\n");
                  else
                     FakeClientCommand (pEdict, "flash\n");
               }
            }
         }
      }

      pBot->iBuyCount = 0; // Finished Buying
      return;
   }

   else
      pBot->iBuyCount = 0; // Finished Buying

   return;
}


void UpdateGlobalExperienceData (void)
{
   // Called after each End of the Round to update knowledge about
   // the most dangerous waypoints for each Team.

   unsigned short min_damage;
   unsigned short act_damage;
   int iBestIndex, i, j;
   bool bRecalcKills = FALSE;
   int iClip;

   // No waypoints, no experience used or waypoints edited OR being edited ?
   if ((g_iNumWaypoints < 1) || !g_bUseExperience || g_bWaypointsChanged || g_bWaypointOn)
      return;

   // Get the most dangerous Waypoint for this Position for Team 0
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      min_damage = 0;
      iBestIndex = -1;

      for (j = 0; j < g_iNumWaypoints; j++)
      {
         if (i == j)
            continue;

         act_damage = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage;

         if (act_damage > min_damage)
         {
            min_damage = act_damage;
            iBestIndex = j;
         }
      }

      if (min_damage > MAX_DAMAGE_VAL)
         bRecalcKills = TRUE;

      (pBotExperienceData + (i * g_iNumWaypoints) + i)->iTeam0_danger_index = (short) iBestIndex;
   }

   // Get the most dangerous Waypoint for this Position for Team 1
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      min_damage = 0;
      iBestIndex = -1;

      for (j = 0; j < g_iNumWaypoints; j++)
      {
         if (i == j)
            continue;

         act_damage = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage;

         if (act_damage > min_damage)
         {
            min_damage = act_damage;
            iBestIndex = j;
         }
      }

      if (min_damage >= MAX_DAMAGE_VAL)
         bRecalcKills = TRUE;

      (pBotExperienceData + (i * g_iNumWaypoints) + i)->iTeam1_danger_index = (short) iBestIndex;
   }

   // Adjust Values if overflow is about to happen
   if (bRecalcKills)
   {
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         for (j = 0; j < g_iNumWaypoints; j++)
         {
            if (i == j)
               continue;

            iClip = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage;
            iClip -= MAX_DAMAGE_VAL / 2;

            if (iClip < 0)
               iClip = 0;

            (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage = (unsigned short) iClip;

            iClip = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage;
            iClip -= MAX_DAMAGE_VAL / 2;

            if (iClip < 0)
               iClip = 0;

            (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage = (unsigned short) iClip;
         }
      }
   }

   g_cKillHistory++;

   if (g_cKillHistory == MAX_KILL_HIST)
   {
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         (pBotExperienceData + (i * g_iNumWaypoints) + i)->uTeam0Damage /= gpGlobals->maxClients / 2;
         (pBotExperienceData + (i * g_iNumWaypoints) + i)->uTeam1Damage /= gpGlobals->maxClients / 2;
      }

      g_cKillHistory = 1;
   }

   return;
}


void BotCollectGoalExperience (bot_t *pBot, int iDamage)
{
   // Gets called each time a Bot gets damaged by some enemy.
   // Tries to achieve a statistic about most/less dangerous waypoints
   // for a destination goal used for pathfinding

   int iWPTValue;

   if ((g_iNumWaypoints < 1) || !g_bUseExperience || g_bWaypointsChanged
       || (pBot->chosengoal_index < 0) || (pBot->prev_goal_index < 0))
      return;

   // Only rate Goal Waypoint if Bot died because of the damage
   // FIXME: Could be done a lot better, however this cares most
   // about damage done by sniping or really deadly weapons
   if (pBot->pEdict->v.health - iDamage <= 0)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
      {
         iWPTValue = (pBotExperienceData + (pBot->chosengoal_index * g_iNumWaypoints) + pBot->prev_goal_index)->wTeam0Value - (pBot->pEdict->v.health / 20);
         if (iWPTValue < -MAX_GOAL_VAL)
            iWPTValue = -MAX_GOAL_VAL;
         else if (iWPTValue > MAX_GOAL_VAL)
            iWPTValue = MAX_GOAL_VAL;
         (pBotExperienceData + (pBot->chosengoal_index * g_iNumWaypoints) + pBot->prev_goal_index)->wTeam0Value = (signed short) iWPTValue;
      }
      else
      {
         iWPTValue = (pBotExperienceData + (pBot->chosengoal_index * g_iNumWaypoints) + pBot->prev_goal_index)->wTeam1Value - (pBot->pEdict->v.health / 20);
         if (iWPTValue<-MAX_GOAL_VAL)
            iWPTValue = -MAX_GOAL_VAL;
         else if (iWPTValue>MAX_GOAL_VAL)
            iWPTValue = MAX_GOAL_VAL;
         (pBotExperienceData + (pBot->chosengoal_index * g_iNumWaypoints) + pBot->prev_goal_index)->wTeam1Value = (signed short) iWPTValue;
      }
   }
}


void BotCollectExperienceData (edict_t *pVictimEdict, edict_t *pAttackerEdict, int iDamage)
{
   // Gets called each time a Bot gets damaged by some enemy.
   // Stores the damage (teamspecific) done to the Victim
   // FIXME: Should probably rate damage done by humans higher...

   if (!g_bUseExperience || FNullEnt (pVictimEdict) || FNullEnt (pAttackerEdict))
      return;

   int iVictimTeam = UTIL_GetTeam (pVictimEdict);
   int iAttackerTeam = UTIL_GetTeam (pAttackerEdict);

   if (iVictimTeam == iAttackerTeam)
      return;

   bot_t *pBot = UTIL_GetBotPointer (pVictimEdict);

   // If these are Bots also remember damage to rank the destination of the Bot
   if (pBot != NULL)
      pBot->f_goal_value -= iDamage;

   pBot = UTIL_GetBotPointer (pAttackerEdict);
   if (pBot != NULL)
      pBot->f_goal_value += iDamage;

   float distance;
   float min_distance_victim = 9999.0;
   float min_distance_attacker = 9999.0;

   int VictimIndex;
   int AttackerIndex;
   int i;

   // Find Nearest Waypoint to Attacker/Victim
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      distance = (paths[i]->origin - pVictimEdict->v.origin).Length ();
      if (distance < min_distance_victim)
      {
         min_distance_victim = distance;
         VictimIndex = i;
      }

      distance = (paths[i]->origin - pAttackerEdict->v.origin).Length ();
      if (distance < min_distance_attacker)
      {
         min_distance_attacker = distance;
         AttackerIndex = i;
      }
   }

   if (pVictimEdict->v.health - iDamage < 0)
   {
      if (iVictimTeam == TEAM_CS_TERRORIST)
         (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam0Damage++;
      else
         (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam1Damage++;

      if ((pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam0Damage > 240)
         (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam0Damage = 240;

      if ((pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam1Damage > 240)
         (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + VictimIndex)->uTeam1Damage = 240;
   }

   if (VictimIndex == AttackerIndex)
      return;

   int iValue;

   // Store away the damage done
   if (iVictimTeam == TEAM_CS_TERRORIST)
   {
      iValue = (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + AttackerIndex)->uTeam0Damage;
      iValue += ((float) iDamage / 10.0);
      if (iValue > MAX_DAMAGE_VAL)
         iValue = MAX_DAMAGE_VAL;

      (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + AttackerIndex)->uTeam0Damage = (unsigned short)iValue;
   }
   else
   {
      iValue = (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + AttackerIndex)->uTeam1Damage;
      iValue += ((float) iDamage / 10.0);
      if (iValue > MAX_DAMAGE_VAL)
         iValue = MAX_DAMAGE_VAL;

      (pBotExperienceData + (VictimIndex * g_iNumWaypoints) + AttackerIndex)->uTeam1Damage = (unsigned short)iValue;
   }
}


void BotSetConditions (bot_t *pBot)
{
   // Carried out each Frame.
   // Does all of the sensing, calculates Emotions and finally
   // sets the desired Action after applying all of the Filters

   edict_t *pEdict = pBot->pEdict;
   float f_distance;
   float min_distance;
   bool bUsingGrenade = pBot->bUsingGrenade;
   bool bCheckNoiseOrigin;
   unsigned char *pas;
   int ind;
   edict_t *pPlayer;
   Vector v_distance;
   unsigned char cHit;
   Vector vecVisPos;

   pBot->iAimFlags = 0;

   // Slowly increase/decrease dynamic Emotions back to their Base Level
   if (pBot->fNextEmotionUpdate < gpGlobals->time)
   {
      if (pBot->fAgressionLevel > pBot->fBaseAgressionLevel)
         pBot->fAgressionLevel -= 0.05;
      else
         pBot->fAgressionLevel += 0.05;

      if (pBot->fFearLevel > pBot->fBaseFearLevel)
         pBot->fFearLevel -= 0.05;
      else
         pBot->fFearLevel += 0.05;

      if (pBot->fAgressionLevel < 0.0)
         pBot->fAgressionLevel = 0.0;
      if (pBot->fFearLevel < 0.0)
         pBot->fFearLevel = 0.0;

      pBot->fNextEmotionUpdate = gpGlobals->time + 0.5;
   }

   // Does Bot see an Enemy ?
   if (!g_bIgnoreEnemies && BotFindEnemy (pBot))
      pBot->iStates |= STATE_SEEINGENEMY;
   else
   {
      pBot->iStates &= ~STATE_SEEINGENEMY;
      pBot->pBotEnemy = NULL;
   }

   // Did Bot just kill an Enemy ?
   if (!FNullEnt (pBot->pLastVictim))
   {
      if (UTIL_GetTeam (pBot->pLastVictim) != pBot->bot_team)
      {
         // Add some agression because we just killed somebody MUWHAHA !!
         pBot->fAgressionLevel += 0.1;
         if (pBot->fAgressionLevel > 1.0)
            pBot->fAgressionLevel = 1.0;

         // Taunt Enemy if we feel like it
         int iRandomMessage = RANDOM_LONG (0, 100);
         if (g_bBotChat)
         {
            if (iRandomMessage < 20)
            {
               BotPrepareChatMessage (pBot, szKillChat[RANDOM_LONG (0, iNumKillChats - 1)]);
               BotPushMessageQueue (pBot, MSG_CS_SAY);
            }
         }

         // Sometimes give some radio message
         if (iRandomMessage<50)
            BotPlayRadioMessage (pBot, RADIO_ENEMYDOWN);
      }

      pBot->pLastVictim = NULL;
   }

   // Check if our current enemy is still valid
   if (!FNullEnt (pBot->pLastEnemy))
   {
      if (!IsAlive (pBot->pLastEnemy) && (pBot->f_shootatdead_time < gpGlobals->time))
      {
         pBot->vecLastEnemyOrigin = g_vecZero;
         pBot->pLastEnemy = NULL;
      }
   }
   else
   {
      pBot->pLastEnemy = NULL;
      pBot->vecLastEnemyOrigin = g_vecZero;
   }

   bCheckNoiseOrigin = FALSE;

   // Check sounds of other players
   // FIXME: Hearing is done by simulating and aproximation
   // Need to check if hooking the Server Playsound Routines
   // wouldn't give better results because the current method
   // is far too sensitive and unreliable

   // Don't listen if seeing enemy, just checked for sounds or being blinded ('cause its inhuman)
   if (!g_bIgnoreEnemies && (pBot->f_sound_update_time < gpGlobals->time)
       && FNullEnt (pBot->pBotEnemy) && (pBot->f_blind_time < gpGlobals->time))
   {
      pBot->f_sound_update_time = gpGlobals->time + g_fTimeSoundUpdate;

      // Let Hearing be affected by Movement Speed
      float fSensitivity = pEdict->v.velocity.Length2D ();
      if (fSensitivity != 0.0)
      {
         fSensitivity /= 240.0;
         fSensitivity = -fSensitivity;
      }
      fSensitivity += 1.5;

      // If Bot just shot, half hearing Sensibility
      if (pEdict->v.oldbuttons & IN_ATTACK)
         fSensitivity *= 0.5;

      // Setup Engines Potentially Audible Set for this Bot
      Vector vecOrg = pEdict->v.origin + pEdict->v.view_ofs;
      if (pEdict->v.flags & FL_DUCKING)
         vecOrg = vecOrg + (VEC_HULL_MIN - VEC_DUCK_HULL_MIN);

      pas = ENGINE_SET_PAS ((float *) &vecOrg);

      pPlayer = NULL;
      min_distance = 9999;

      // Loop through all enemy clients to check for hearable stuff
      for (ind = 0; ind < gpGlobals->maxClients; ind++)
      {
         if (!clients[ind].IsUsed
             || !clients[ind].IsAlive
             || (clients[ind].iTeam == pBot->bot_team)
             || (clients[ind].pEdict == pEdict)
             || (clients[ind].fTimeSoundLasting < gpGlobals->time))
            continue;

         // Despite its name it also checks for sounds...
         // NOTE: This only checks if sounds could be heard from
         // this position in theory but doesn't care for Volume or
         // real Sound Events. Even if there's no noise it returns true,
         // so we still have the work of simulating sound levels
         if (!ENGINE_CHECK_VISIBILITY (clients[ind].pEdict, pas))
            continue;

         f_distance = (clients[ind].vecSoundPosition - pEdict->v.origin).Length ();
         if (f_distance > clients[ind].fHearingDistance)
            continue;

         if (f_distance > min_distance)
            continue;

         min_distance = f_distance;
         pPlayer = clients[ind].pEdict;
      }

      // Did the Bot hear someone ?
      if (!FNullEnt (pPlayer))
      {
         // Change to best weapon if heard something
         if ((pBot->current_weapon.iId == CS_WEAPON_KNIFE) && !g_bJasonMode)
            BotSelectBestWeapon (pBot);

         pBot->f_heard_sound_time = gpGlobals->time;
         pBot->iStates |= STATE_HEARINGENEMY;

         // Didn't Bot already have an enemy ? Take this one...
         if (pBot->vecLastEnemyOrigin == g_vecZero)
         {
            pBot->pLastEnemy = pPlayer;
            pBot->vecLastEnemyOrigin = pPlayer->v.origin;
         }

         // Bot had an enemy, check if it's the heard one
         else
         {
            if (pPlayer == pBot->pLastEnemy)
            {
               // Bot sees enemy ? then bail out !
               if (pBot->iStates & STATE_SEEINGENEMY)
                  goto endhearing;
               pBot->vecLastEnemyOrigin = pPlayer->v.origin;
            }
            else
            {
               // If Bot had an enemy but the heard one is nearer, take it instead
               f_distance = (pBot->vecLastEnemyOrigin - pEdict->v.origin).Length ();

               if ((f_distance > (pPlayer->v.origin - pEdict->v.origin).Length ())
                   && (pBot->f_bot_see_enemy_time + 2.0 < gpGlobals->time))
               {
                  pBot->pLastEnemy = pPlayer;
                  pBot->vecLastEnemyOrigin = pPlayer->v.origin;
               }
               else
                  goto endhearing;
            }
         }

         // Check if heard enemy can be seen
         if (FBoxVisible (pEdict, pPlayer, &vecVisPos, &cHit))
         {
            pBot->pBotEnemy = pPlayer;
            pBot->pLastEnemy = pPlayer;
            pBot->vecLastEnemyOrigin = vecVisPos;
            pBot->ucVisibility = cHit;
            pBot->iStates |= STATE_SEEINGENEMY;
            pBot->f_bot_see_enemy_time = gpGlobals->time;
         }

         // Check if heard enemy can be shoot through some obstacle
         else if ((pBot->pLastEnemy == pPlayer)
                  && (pBot->f_bot_see_enemy_time + 3.0 > gpGlobals->time))
         {
            int iShootThruFreq = BotAimTab[pBot->bot_skill / 20].iHeardShootThruProb;

            if (g_bShootThruWalls && WeaponShootsThru (pBot->current_weapon.iId)
                && (RANDOM_LONG (1, 100) < iShootThruFreq))
            {
               if (IsShootableThruObstacle (pEdict, pPlayer->v.origin))
               {
                  pBot->pBotEnemy = pPlayer;
                  pBot->pLastEnemy = pPlayer;
                  pBot->vecLastEnemyOrigin = pPlayer->v.origin;
                  pBot->iStates |= STATE_SEEINGENEMY;
                  pBot->iStates |= STATE_SUSPECTENEMY;
                  pBot->f_bot_see_enemy_time = gpGlobals->time;
               }
            }
         }
      }
   }
   else
      pBot->iStates &= ~STATE_HEARINGENEMY;

endhearing:

   if (FNullEnt (pBot->pBotEnemy) && !FNullEnt (pBot->pLastEnemy))
   {
      pBot->iAimFlags |= AIM_PREDICTPATH;
      if (BotEntityIsVisible (pBot, pBot->vecLastEnemyOrigin))
         pBot->iAimFlags |= AIM_LASTENEMY;
   }

   // Check if throwing a Grenade is a good thing to do...
   if ((pBot->f_grenade_check_time < gpGlobals->time) && !bUsingGrenade
       && !pBot->bIsReloading && (pBot->current_weapon.iId != CS_WEAPON_INSWITCH))
   {
      // Check again in some seconds
      pBot->f_grenade_check_time = gpGlobals->time + g_fTimeGrenadeUpdate;

      if (!FNullEnt (pBot->pLastEnemy) && IsAlive (pBot->pLastEnemy)
          && !(pBot->iStates & STATE_SEEINGENEMY))
      {
         // Check if we have Grenades to throw
         int iGrenadeType = BotCheckGrenades (pBot);

         // If we don't have grenades no need to check
         // it this round again
         if (iGrenadeType == -1)
            pBot->f_grenade_check_time = gpGlobals->time + 9999.0;

         if (iGrenadeType != -1)
         {
            edict_t *pEnemy = pBot->pLastEnemy;
            Vector v_distance = pBot->vecLastEnemyOrigin - pEdict->v.origin;
            f_distance = v_distance.Length ();

            // Too high to throw ?
            if (pEnemy->v.origin.z > pEdict->v.origin.z + 500.0)
               f_distance = 9999;

            // Enemy within a good Throw distance ?
            if ((f_distance > 400) && (f_distance < 1600))
            {
               Vector v_enemypos;
               Vector vecSource;
               Vector v_dest;
               TraceResult tr;
               bool bThrowGrenade = TRUE;
               int iThrowIndex;
               Vector vecPredict;
               int rgi_WaypointTab[4];
               int iIndexCount;
               float fRadius;

               // Care about different Grenades
               switch (iGrenadeType)
               {
               case CS_WEAPON_HEGRENADE:
                  if (NumTeammatesNearPos (pBot, pBot->pLastEnemy->v.origin, 256) > 0)
                     bThrowGrenade = FALSE;
                  else
                  {
                     vecPredict = pBot->pLastEnemy->v.velocity * 0.5;
                     vecPredict.z = 0.0;
                     vecPredict = vecPredict + pBot->pLastEnemy->v.origin;
                     fRadius = pBot->pLastEnemy->v.velocity.Length2D ();

                     if (fRadius < 128)
                        fRadius = 128;
                     iIndexCount = 4;

                     WaypointFindInRadius (vecPredict, fRadius, &rgi_WaypointTab[0], &iIndexCount);

                     while (iIndexCount > 0)
                     {
                        bThrowGrenade = TRUE;

                        pBot->vecThrow = paths[rgi_WaypointTab[iIndexCount--]]->origin;
                        vecSource = VecCheckThrow (pEdict, GetGunPosition (pEdict), pBot->vecThrow, 1.0);

                        if (vecSource == g_vecZero)
                           vecSource = VecCheckToss (pEdict, GetGunPosition (pEdict), pBot->vecThrow);

                        if (vecSource == g_vecZero)
                           bThrowGrenade = FALSE;
                        else
                           break;
                     }
                  }

                  // Start throwing ?
                  if (bThrowGrenade)
                     pBot->iStates |= STATE_THROWHEGREN;
                  else
                     pBot->iStates &= ~STATE_THROWHEGREN;

                  break;

               case CS_WEAPON_FLASHBANG:
                  vecPredict = pBot->pLastEnemy->v.velocity * 0.5;
                  vecPredict.z = 0.0;
                  vecPredict = vecPredict + pBot->pLastEnemy->v.origin;
                  iThrowIndex = WaypointFindNearestToMove (vecPredict);
                  pBot->vecThrow = paths[iThrowIndex]->origin;

                  if (NumTeammatesNearPos (pBot, pBot->vecThrow, 256) > 0)
                     bThrowGrenade = FALSE;

                  if (bThrowGrenade)
                  {
                     vecSource = VecCheckThrow (pEdict, GetGunPosition (pEdict), pBot->vecThrow, 1.0);
                     if (vecSource == g_vecZero)
                        vecSource = VecCheckToss (pEdict, GetGunPosition (pEdict), pBot->vecThrow);
                     if (vecSource == g_vecZero)
                        bThrowGrenade = FALSE;
                  }

                  if (bThrowGrenade)
                     pBot->iStates |= STATE_THROWFLASHBANG;
                  else
                     pBot->iStates &= ~STATE_THROWFLASHBANG;

                  break;

               case CS_WEAPON_SMOKEGRENADE:
                  // Check if Enemy is directly facing us
                  // Don't throw if that's the case !!
                  if (bThrowGrenade && !FNullEnt (pBot->pBotEnemy))
                  {
                     if (GetShootingConeDeviation (pBot->pBotEnemy, &pEdict->v.origin) >= 0.9)
                        bThrowGrenade = FALSE;
                  }

                  if (bThrowGrenade)
                     pBot->iStates |= STATE_THROWSMOKEGREN;
                  else
                     pBot->iStates &= ~STATE_THROWSMOKEGREN;

                  break;
               }
               bottask_t TempTask = {NULL, NULL, TASK_THROWHEGRENADE, TASKPRI_THROWGRENADE, -1, gpGlobals->time + TIME_GRENPRIME, FALSE};

               if (pBot->iStates & STATE_THROWHEGREN)
                  BotPushTask (pBot, &TempTask);
               else if (pBot->iStates & STATE_THROWFLASHBANG)
               {
                  TempTask.iTask = TASK_THROWFLASHBANG;
                  BotPushTask (pBot, &TempTask);
               }
               else if (pBot->iStates & STATE_THROWSMOKEGREN)
               {
                  TempTask.iTask = TASK_THROWSMOKEGRENADE;
                  BotPushTask (pBot, &TempTask);
               }
            }
            else
            {
               pBot->iStates &= ~STATE_THROWHEGREN;
               pBot->iStates &= ~STATE_THROWFLASHBANG;
               pBot->iStates &= ~STATE_THROWSMOKEGREN;
            }
         }
         else
         {
            pBot->iStates &= ~STATE_THROWHEGREN;
            pBot->iStates &= ~STATE_THROWFLASHBANG;
            pBot->iStates &= ~STATE_THROWSMOKEGREN;
         }
      }
   }
   else
   {
      pBot->iStates &= ~STATE_THROWHEGREN;
      pBot->iStates &= ~STATE_THROWFLASHBANG;
      pBot->iStates &= ~STATE_THROWSMOKEGREN;
   }

   // Check if there are Items needing to be used/collected
   if ((pBot->f_itemcheck_time < gpGlobals->time) || !FNullEnt (pBot->pBotPickupItem))
   {
      pBot->f_itemcheck_time = gpGlobals->time + g_fTimePickupUpdate;
      BotFindItem (pBot);
   }

   float fTempFear = pBot->fFearLevel;
   float fTempAgression = pBot->fAgressionLevel;

   // Decrease Fear if Teammates near
   int iFriendlyNum = 0;
   if (pBot->vecLastEnemyOrigin != g_vecZero)
      iFriendlyNum = NumTeammatesNearPos (pBot, pEdict->v.origin, 300) - NumEnemiesNearPos (pBot, pBot->vecLastEnemyOrigin, 500);
   if (iFriendlyNum > 0)
      fTempFear = fTempFear * 0.5;

   // Increase/Decrease Fear/Agression if Bot uses a sniping weapon
   // to be more careful
   if (BotUsesSniper (pBot))
   {
      fTempFear = fTempFear * 1.5;
      fTempFear = fTempAgression * 0.5;
   }

   // Initialize & Calculate the Desire for all Actions based on
   // distances, Emotions and other Stuff

   BotGetSafeTask (pBot);

   // Bot found some Item to use ?
   if (pBot->pBotPickupItem)
   {
      pBot->iStates |= STATE_PICKUPITEM;
      edict_t *pItem = pBot->pBotPickupItem;
      Vector vecPickme;

      if (strncmp ("func_", STRING (pItem->v.classname), 5) == 0)
         vecPickme = VecBModelOrigin (pItem);
      else
         vecPickme = pItem->v.origin;

      f_distance = (vecPickme - pEdict->v.origin).Length ();
      f_distance = 500 - f_distance;
      f_distance = (100 * f_distance) / 500;

      if (f_distance > 50)
         f_distance = 50;

      taskFilters[TASK_PICKUPITEM].fDesire = f_distance;
   }
   else
   {
      pBot->iStates &= ~STATE_PICKUPITEM;
      taskFilters[TASK_PICKUPITEM].fDesire = 0.0;
   }

   float fLevel;
   float fMaxView = pBot->f_maxview_distance;

   // Calculate Desire to Attack
   if (pBot->iStates & STATE_SEEINGENEMY)
   {
      if (BotReactOnEnemy(pBot))
         taskFilters[TASK_ATTACK].fDesire = TASKPRI_ATTACK;
      else
         taskFilters[TASK_ATTACK].fDesire = 0;
   }
   else
      taskFilters[TASK_ATTACK].fDesire = 0;

   // Calculate Desires to seek Cover or Hunt
   if (!FNullEnt (pBot->pLastEnemy))
   {
      f_distance = (pBot->vecLastEnemyOrigin - pEdict->v.origin).Length ();
      float fRetreatLevel = (100 - pBot->pEdict->v.health) * fTempFear;
      float fTimeSeen = pBot->f_bot_see_enemy_time - gpGlobals->time;
      float fTimeHeard = pBot->f_heard_sound_time - gpGlobals->time;
      float fRatio;

      if (fTimeSeen > fTimeHeard)
      {
         fTimeSeen += 10.0;
         fRatio = fTimeSeen / 10;
      }
      else
      {
         fTimeHeard += 10.0;
         fRatio = fTimeHeard / 10;
      }

      taskFilters[TASK_SEEKCOVER].fDesire = fRetreatLevel * fRatio;

      // If half of the Round is over, allow hunting
      // FIXME: It probably should be also team/map dependant
      if (FNullEnt (pBot->pBotEnemy) && (g_fTimeRoundMid < gpGlobals->time) && !pBot->bUsingGrenade)
      {
         fLevel = 4096.0 - ((1.0 - fTempAgression) * f_distance);
         fLevel = (100 * fLevel) / 4096.0;
         fLevel = fLevel-fRetreatLevel;
         if (fLevel > 89)
            fLevel = 89;
         taskFilters[TASK_ENEMYHUNT].fDesire = fLevel;
      }
      else
         taskFilters[TASK_ENEMYHUNT].fDesire = 0;
   }
   else
   {
      taskFilters[TASK_SEEKCOVER].fDesire = 0;
      taskFilters[TASK_ENEMYHUNT].fDesire = 0;
   }

   // Blinded Behaviour
   if (pBot->f_blind_time > gpGlobals->time)
      taskFilters[TASK_BLINDED].fDesire = TASKPRI_BLINDED;
   else
      taskFilters[TASK_BLINDED].fDesire = 0.0;


   // Now we've initialised all the desires go through the hard work
   // of filtering all Actions against each other to pick the most
   // rewarding one to the Bot
   // Credits for the basic Idea of filtering comes out of the paper
   // "Game Agent Control Using Parallel Behaviors"
   // by Robert Zubek
   //
   // FIXME: Instead of going through all of the Actions it might be
   // better to use some kind of decision tree to sort out impossible
   // actions
   //
   // Most of the values were found out by Trial-and-Error and a Helper
   // Utility I wrote so there could still be some weird behaviours, it's
   // hard to check them all out 


   pBot->oldcombatdesire = hysteresisdesire (taskFilters[TASK_ATTACK].fDesire, 40.0, 90.0, pBot->oldcombatdesire);
   taskFilters[TASK_ATTACK].fDesire = pBot->oldcombatdesire;
   bottask_t *ptaskOffensive = &taskFilters[TASK_ATTACK];

   bottask_t * ptaskPickup = &taskFilters[TASK_PICKUPITEM];

   // Calc Survive (Cover/Hide)
   bottask_t *ptaskSurvive = thresholddesire (&taskFilters[TASK_SEEKCOVER], 40.0, 0.0);
   ptaskSurvive = subsumedesire (&taskFilters[TASK_HIDE], ptaskSurvive);

   // Don't allow hunting if Desire's 60<
   bottask_t *pDefault = thresholddesire (&taskFilters[TASK_ENEMYHUNT], 60.0, 0.0);

   // If offensive Task, don't allow picking up stuff
   ptaskOffensive = subsumedesire (ptaskOffensive, ptaskPickup);

   // Default normal & defensive Tasks against Offensive Actions
   bottask_t *pSub1 = maxdesire (ptaskOffensive, pDefault);

   // Reason about fleeing instead
   bottask_t *pFinal = maxdesire (ptaskSurvive, pSub1);

   pFinal = subsumedesire (&taskFilters[TASK_BLINDED], pFinal);

   if (pBot->pTasks != NULL)
      pFinal = maxdesire (pFinal, pBot->pTasks);

   // Push the final Behaviour in our Tasklist to carry out
   BotPushTask (pBot, pFinal);
}


void BotResetTasks (bot_t *pBot)
{
   bottask_t *pPrevTask;
   bottask_t *pNextTask;

   if (pBot->pTasks == NULL)
      return;

   pNextTask = BotGetSafeTask (pBot)->pNextTask;
   pPrevTask = BotGetSafeTask (pBot);

   while (pBot->pTasks != NULL)
   {
      pPrevTask = pBot->pTasks->pPreviousTask;
      delete (pBot->pTasks);
      pBot->pTasks = pPrevTask;
   }
   pBot->pTasks = pNextTask;

   while (pBot->pTasks != NULL)
   {
      pNextTask = pBot->pTasks->pNextTask;
      delete (pBot->pTasks);
      pBot->pTasks = pNextTask;
   }
   pBot->pTasks = NULL;
}


void BotPushTask (bot_t *pBot, bottask_t *pTask)
{
   if (pBot->pTasks != NULL)
   {
      if (BotGetSafeTask (pBot)->iTask == pTask->iTask)
      {
         if (BotGetSafeTask (pBot)->fDesire != pTask->fDesire)
            BotGetSafeTask (pBot)->fDesire = pTask->fDesire;
         return;
      }
      else
         DeleteSearchNodes (pBot);
   }

   pBot->fNoCollTime = gpGlobals->time + 0.5;

   bottask_t *pNewTask = new bottask_t;
   pNewTask->iTask = pTask->iTask;
   pNewTask->fDesire = pTask->fDesire;
   pNewTask->iData = pTask->iData;
   pNewTask->fTime = pTask->fTime;
   pNewTask->bCanContinue = pTask->bCanContinue;

   pNewTask->pPreviousTask = NULL;
   pNewTask->pNextTask = NULL;

   if (pBot->pTasks != NULL)
   {
      while (BotGetSafeTask (pBot)->pNextTask)
         pBot->pTasks = BotGetSafeTask (pBot)->pNextTask;

      BotGetSafeTask (pBot)->pNextTask = pNewTask;
      pNewTask->pPreviousTask = pBot->pTasks;
   }

   pBot->pTasks = pNewTask;

   // Leader Bot ?
   if (pBot->bIsLeader)
   {
      // Reorganize Team if fleeing
      if (pNewTask->iTask == TASK_SEEKCOVER)
         BotCommandTeam(pBot);
   }

   return;
}


bottask_t *BotGetSafeTask (bot_t *pBot)
{
   if (pBot->pTasks == NULL)
   {
      bottask_t TempTask = {NULL, NULL, TASK_NORMAL, TASKPRI_NORMAL, -1, 0.0, TRUE};
      BotPushTask (pBot, &TempTask);
   }

   return (pBot->pTasks);
}


void BotRemoveCertainTask (bot_t *pBot, int iTaskNum)
{
   bottask_t *pTask = pBot->pTasks;
   bottask_t *pNextTask;
   bottask_t *pPrevTask;

   if (pTask == NULL)
      return;

   while (pTask->pPreviousTask != NULL)
      pTask = pTask->pPreviousTask;

   while (pTask != NULL)
   {
      pNextTask = pTask->pNextTask;
      pPrevTask = pTask->pPreviousTask;

      if (pTask->iTask == iTaskNum)
      {
         if (pPrevTask != NULL)
            pPrevTask->pNextTask = pNextTask;
         if (pNextTask != NULL)
            pNextTask->pPreviousTask = pPrevTask;

         delete (pTask);
      }

      pTask = pNextTask;
   }

   pBot->pTasks = pPrevTask;
   DeleteSearchNodes (pBot);
}


void BotTaskComplete (bot_t *pBot)
{
   // Called whenever a Task is completed

   bottask_t *pPrevTask;

   if (pBot->pTasks == NULL)
   {
      DeleteSearchNodes (pBot); // Delete all Pathfinding Nodes
      return;
   }

   do
   {
      pPrevTask = BotGetSafeTask (pBot)->pPreviousTask;
      delete (pBot->pTasks);
      pBot->pTasks = NULL;

      if (pPrevTask != NULL)
      {
         pPrevTask->pNextTask = NULL;
         pBot->pTasks = pPrevTask;
      }

      if (pBot->pTasks == NULL)
         break;

   } while (!BotGetSafeTask (pBot)->bCanContinue);

   // Delete all Pathfinding Nodes
   DeleteSearchNodes(pBot);
}


inline void BotFacePosition (bot_t *pBot, Vector vecPos)
{
   // Adjust all Bot Body and View Angles to face an absolute Vector

   edict_t *pEdict = pBot->pEdict;
   Vector vecDirection;

   vecDirection = UTIL_VecToAngles (vecPos - GetGunPosition (pEdict));
   vecDirection = vecDirection - pEdict->v.punchangle;

   vecDirection.x = -vecDirection.x;
   pEdict->v.ideal_yaw = vecDirection.y;
   pEdict->v.idealpitch = vecDirection.x;

   UTIL_ClampAngle (&pEdict->v.ideal_yaw);
   UTIL_ClampAngle (&pEdict->v.idealpitch);

   if (pEdict->v.idealpitch > 89)
      pEdict->v.idealpitch = 89;
   else if (pEdict->v.idealpitch < -89)
      pEdict->v.idealpitch = -89;

   return;
}


bool BotEnemyIsThreat (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   float f_distance;

   if (FNullEnt (pBot->pBotEnemy) || (pBot->iStates & STATE_SUSPECTENEMY)
       || (BotGetSafeTask (pBot)->iTask == TASK_SEEKCOVER))
      return (FALSE);

   if (!FNullEnt (pBot->pBotEnemy))
   {
      Vector vDest = pBot->pBotEnemy->v.origin - pBot->pEdict->v.origin;
      f_distance = vDest.Length ();
   }
   else
      return (FALSE);

   // If Bot is camping, he should be firing anyway and NOT leaving his position
   if (BotGetSafeTask (pBot)->iTask == TASK_CAMP)
      return (FALSE);

   // If Enemy is near or facing us directly
   if ((f_distance < 256) || (GetShootingConeDeviation (pBot->pBotEnemy, &pEdict->v.origin) >= 0.9))
      return (TRUE);

   return (FALSE);
}


bool BotReactOnEnemy (bot_t *pBot)
{
   // Check if Task has to be interrupted because an Enemy is near (run Attack Actions then)

   if (BotEnemyIsThreat (pBot))
   {
      if (pBot->fEnemyReachableTimer < gpGlobals->time)
      {
         int iBotIndex = WaypointFindNearestToMove (pBot->pEdict->v.origin);
         int iEnemyIndex = WaypointFindNearestToMove (pBot->pBotEnemy->v.origin);
         int fLinDist = (pBot->pBotEnemy->v.origin - pBot->pEdict->v.origin).Length ();
         int fPathDist = GetPathDistance (iBotIndex, iEnemyIndex);

         if (fPathDist - fLinDist > 112)
            pBot->bEnemyReachable = FALSE;
         else
            pBot->bEnemyReachable = TRUE;

         pBot->fEnemyReachableTimer = gpGlobals->time + 1.0;
      }

      if (pBot->bEnemyReachable)
      {
         // Override existing movement by attack movement
         pBot->f_wpt_timeset = gpGlobals->time;
//         BotDoAttackMovement (pBot);

         return (TRUE);
      }
   }

   return (FALSE);
}


bool BotLastEnemyVisible (bot_t *pBot)
{
   // Checks if Line of Sight established to last Enemy

   edict_t *pEdict = pBot->pEdict;
   TraceResult tr;

   // trace a line from bot's eyes to destination...
   TRACE_LINE (pEdict->v.origin + pEdict->v.view_ofs,
               pBot->vecLastEnemyOrigin, ignore_monsters,
               pEdict, &tr);

   // check if line of sight to object is not blocked (i.e. visible)
   if (tr.flFraction >= 1.0)
      return (TRUE);

   return (FALSE);
}


bool BotLastEnemyShootable (bot_t *pBot)
{
   edict_t *pEdict = pBot->pEdict;
   float flDot;

   if (!(pBot->iAimFlags & AIM_LASTENEMY))
      return (FALSE);

   flDot = GetShootingConeDeviation (pEdict, &pBot->vecLastEnemyOrigin);
   if (flDot >= 0.90)
      return (TRUE);

   return (FALSE);
}


bool BotDoWaypointNav (bot_t *pBot)
{
   // Does the main Path Navigation...

   static char target_name[64];
   edict_t *pEdict = pBot->pEdict;
   edict_t *pButton;
   edict_t *pNearestButton;
   Vector v_trace_start;
   Vector v_button_origin;
   float f_button_distance;
   float f_button_min_distance;
   TraceResult tr;
   TraceResult tr2;
   float wpt_distance;
   float fDesiredDistance;
   int iWPTValue;
   int iStartIndex;
   int iGoalIndex;
   int iWPTIndex;
   int i;

   if (pBot->curr_wpt_index == -1)
      GetValidWaypoint (pBot); // check if we need to find a waypoint...

   pBot->dest_origin = pBot->wpt_origin;
   wpt_distance = (pEdict->v.origin - pBot->wpt_origin).Length ();

   // Initialize the radius for a special waypoint type, where the wpt
   // is considered to be reached
   if ((pEdict->v.flags & FL_DUCKING) || (paths[pBot->curr_wpt_index]->flags & W_FL_GOAL))
      fDesiredDistance = 25;

   else if (pBot->bOnLadder)
      fDesiredDistance = 15;

   else
      fDesiredDistance = 50;

   // This waypoint has additional Travel Flags - care about them
   if (pBot->curr_travel_flags & C_FL_JUMP)
   {
      // Not jumped yet ?
      if (!pBot->bJumpDone)
      {
         fDesiredDistance = 0;

         // If Bot's on ground or on ladder we're free to jump.
         // Yes, I'm cheating here by setting the correct velocity for the jump. Pressing
         // the jump button gives the illusion of the Bot actual jumping
         if ((pEdict->v.flags & (FL_ONGROUND | FL_PARTIALGROUND)) || pBot->bOnLadder)
         {
            pEdict->v.velocity = pBot->vecDesiredVelocity;
            pEdict->v.button |= IN_JUMP;
            pBot->bJumpDone = TRUE;
            pBot->vecDesiredVelocity = g_vecZero;
            pBot->bCheckTerrain = FALSE;
         }
      }

      // Jump made
      else
      {
         // if bot was doing a knife-jump, switch back to normal weapon
         if (!g_bJasonMode && (pBot->current_weapon.iId == CS_WEAPON_KNIFE)
             && (pEdict->v.flags & (FL_ONGROUND | FL_PARTIALGROUND)))
            BotSelectBestWeapon (pBot);
      }
   }

   // Special Ladder Handling
   if (paths[pBot->curr_wpt_index]->flags & W_FL_LADDER)
   {
      fDesiredDistance = 15;

      if (pBot->wpt_origin.z < pEdict->v.origin.z)
      {
         if (!pBot->bOnLadder
             && (pEdict->v.flags & FL_ONGROUND)
             && !(pEdict->v.flags & FL_DUCKING))
         {
            // Slowly approach ladder if going down
            pBot->f_move_speed = wpt_distance;

            if (pBot->f_move_speed < 150.0)
               pBot->f_move_speed = 150.0;
            else if (pBot->f_move_speed > pEdict->v.maxspeed)
               pBot->f_move_speed = pEdict->v.maxspeed;
         }
      }
   }

   // Special Lift Handling
   if (paths[pBot->curr_wpt_index]->flags & W_FL_LIFT)
   {
      fDesiredDistance = 50;

      TRACE_LINE (paths[pBot->curr_wpt_index]->origin, paths[pBot->curr_wpt_index]->origin + Vector (0, 0, -50), ignore_monsters, pEdict, &tr);

      // lift found at waypoint ?
      if (tr.flFraction < 1.0)
      {
         // is lift activated AND bot is standing on it AND lift is moving ?
         if ((tr.pHit->v.nextthink > 0) && (pEdict->v.groundentity == tr.pHit)
             && (pEdict->v.velocity.z != 0) && (pEdict->v.flags & (FL_ONGROUND | FL_PARTIALGROUND)))
         {
            // When lift is moving, pause the bot
            pBot->f_wpt_timeset = gpGlobals->time;
            pBot->f_move_speed = 0.0;
            pBot->f_sidemove_speed = 0.0;
            pBot->iAimFlags |= AIM_DEST;
         }

         // lift found but won't move ?
         else if ((tr.pHit->v.nextthink <= 0) && (pBot->f_itemcheck_time < gpGlobals->time))
         {
            DeleteSearchNodes (pBot);
            BotFindWaypoint (pBot);

            return (FALSE);
         }
      }

      // lift not found at waypoint ?
      else
      {
         // button has been pressed, lift should come
         pBot->f_wpt_timeset = gpGlobals->time;
         pBot->f_move_speed = 0.0;
         pBot->f_sidemove_speed = 0.0;
         pBot->iAimFlags |= AIM_DEST;

         if (pBot->f_itemcheck_time + 4.0 < gpGlobals->time)
         {
            DeleteSearchNodes (pBot);
            BotFindWaypoint (pBot);

            return (FALSE);
         }
      }
   }

   // Special Button Handling
   if (paths[pBot->curr_wpt_index]->flags & W_FL_USE_BUTTON)
   {
      fDesiredDistance = 0;

      pBot->iAimFlags = AIM_DEST; // look at button and only at it (so bot can trigger it)

      pButton = NULL;
      pNearestButton = NULL;
      f_button_min_distance = 100;

      // find the closest reachable button
      while (!FNullEnt (pButton = FIND_ENTITY_IN_SPHERE (pButton, pBot->wpt_origin, 100)))
      {
         if ((strcmp ("func_button", STRING (pButton->v.classname)) != 0)
             && (strcmp ("func_pushable", STRING (pButton->v.classname)) != 0)
             && (strcmp ("trigger_once", STRING (pButton->v.classname)) != 0)
             && (strcmp ("trigger_multiple", STRING (pButton->v.classname)) != 0))
            continue;

         v_button_origin = VecBModelOrigin (pButton);
         f_button_distance = (v_button_origin - pBot->wpt_origin).Length ();

         TRACE_LINE (pBot->wpt_origin, v_button_origin, ignore_monsters, pEdict, &tr);
         if (((tr.pHit == pButton) || (tr.flFraction > 0.95))
             && (f_button_distance < f_button_min_distance))
         {
            f_button_min_distance = f_button_distance;
            pNearestButton = pButton;
         }
      }

      // found one ?
      if (!FNullEnt (pNearestButton))
      {
         pBot->dest_origin = VecBModelOrigin (pNearestButton);
         pBot->f_wpt_timeset = gpGlobals->time;
         pBot->bCheckTerrain = FALSE;

         // reached it?
         if ((pBot->dest_origin - pEdict->v.origin).Length () < 50)
         {
            if (!(pEdict->v.button & IN_USE))
               pEdict->v.button |= IN_USE;

            pBot->f_itemcheck_time = gpGlobals->time + 4.0;
         }
      }
   }

   if ((pBot->prev_wpt_index[0] >= 0) && (pBot->prev_wpt_index[0] < g_iNumWaypoints))
      v_trace_start = paths[pBot->prev_wpt_index[0]]->origin;
   else
      v_trace_start = pEdict->v.origin;

   TRACE_LINE (v_trace_start, pBot->wpt_origin, ignore_monsters, pEdict, &tr);

   // special door handling
   if (strncmp (STRING (tr.pHit->v.classname), "func_door", 9) == 0)
   {
      fDesiredDistance = 0;
      pBot->iAimFlags = AIM_DEST; // look at door and only at it (so it opens in the right direction)

      // does this door has a target button ?
      if (STRING (tr.pHit->v.targetname)[0] != 0)
      {
         // find a reachable target button
         while (!FNullEnt (pButton = FIND_ENTITY_BY_STRING (pButton, "target", STRING (tr.pHit->v.targetname))))
         {
            v_button_origin = VecBModelOrigin (pButton);

            TRACE_LINE (v_trace_start, v_button_origin, ignore_monsters, pEdict, &tr2);
            if ((tr2.pHit == pButton) || (tr2.flFraction > 0.95))
            {
               pBot->dest_origin = v_button_origin;
               pBot->f_wpt_timeset = gpGlobals->time;
               pBot->bCheckTerrain = FALSE;

               if (((v_button_origin - pEdict->v.origin).Length () < 40)
                   && (RANDOM_LONG (1, 100) < 10))
                  pEdict->v.button |= IN_USE;

               break;
            }
         }
      }

      // if bot hits the door, then it opens, so wait a bit to let it open safely
      if ((pEdict->v.velocity.Length2D () < 2) && (pBot->f_timeDoorOpen < gpGlobals->time))
      {
         bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 0.5, FALSE};
         BotPushTask (pBot, &TempTask);
         pBot->f_timeDoorOpen = gpGlobals->time + 1.0; // retry in 1 sec until door is open
      }
   }

   // special breakable handling
   else if ((strcmp (STRING (tr.pHit->v.classname), "func_breakable") == 0)
            && IsShootableBreakable (tr.pHit))
   {
      pBot->iAimFlags = AIM_DEST; // look at breakable and only at it (so we can shoot it)
      pBot->pShootBreakable = tr.pHit;
      pBot->iCampButtons = pEdict->v.button & IN_DUCK;
      bottask_t TempTask = {NULL, NULL, TASK_SHOOTBREAKABLE, TASKPRI_SHOOTBREAKABLE, -1, 0.0, FALSE};
      BotPushTask (pBot, &TempTask);
   }

   // Check if Waypoint has a special Travelflag, so they need to be reached more precisely
   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      if (paths[pBot->curr_wpt_index]->connectflag[i] != 0)
      {
         fDesiredDistance = 0;
         break;
      }
   }

   // Needs precise placement - check if we get past the point
   if ((fDesiredDistance < 16) && (wpt_distance < 30))
   {
      Vector v_OriginNextFrame = pEdict->v.origin + (pEdict->v.velocity * pBot->fTimeFrameInterval);

      if ((v_OriginNextFrame - pBot->wpt_origin).Length () > wpt_distance)
         fDesiredDistance = wpt_distance + 1;
   }

   if (wpt_distance < fDesiredDistance)
   {
      // Did we reach a destination Waypoint ?
      if (BotGetSafeTask (pBot)->iData == pBot->curr_wpt_index)
      {
         // Add Goal Values
         if (g_bUseExperience && (pBot->chosengoal_index != -1))
         {
            iStartIndex = pBot->chosengoal_index;
            iGoalIndex = pBot->curr_wpt_index;

            if (pBot->bot_team == TEAM_CS_TERRORIST)
            {
               iWPTValue = (pBotExperienceData + (iStartIndex * g_iNumWaypoints) + iGoalIndex)->wTeam0Value;
               iWPTValue += pBot->pEdict->v.health / 20;
               iWPTValue += pBot->f_goal_value / 20;

               if (iWPTValue < -MAX_GOAL_VAL)
                  iWPTValue = -MAX_GOAL_VAL;
               else if (iWPTValue > MAX_GOAL_VAL)
                  iWPTValue = MAX_GOAL_VAL;

               (pBotExperienceData + (iStartIndex * g_iNumWaypoints) + iGoalIndex)->wTeam0Value = iWPTValue;
            }
            else
            {
               iWPTValue = (pBotExperienceData + (iStartIndex * g_iNumWaypoints) + iGoalIndex)->wTeam1Value;
               iWPTValue += pBot->pEdict->v.health / 20;
               iWPTValue += pBot->f_goal_value / 20;

               if (iWPTValue < -MAX_GOAL_VAL)
                  iWPTValue = -MAX_GOAL_VAL;
               else if (iWPTValue > MAX_GOAL_VAL)
                  iWPTValue = MAX_GOAL_VAL;

               (pBotExperienceData + (iStartIndex * g_iNumWaypoints) + iGoalIndex)->wTeam1Value = iWPTValue;
            }
         }

         return (TRUE);
      }

      else if (pBot->pWaypointNodes == NULL)
         return (FALSE);

      // Defusion Map ?
      if (g_iMapType & MAP_DE)
      {
         // Bomb planted and CT ?
         if (g_bBombPlanted && (pBot->bot_team == TEAM_CS_COUNTER))
         {
            iWPTIndex = BotGetSafeTask (pBot)->iData;

            if (iWPTIndex != -1)
            {
               float fDistance = (pEdict->v.origin - paths[iWPTIndex]->origin).Length ();

               // Bot within 'hearable' Bomb Tick Noises ?
               if (fDistance < BOMBMAXHEARDISTANCE)
               {
                  // Does hear Bomb ?
                  if (BotHearsBomb (pEdict->v.origin))
                  {
                     fDistance = (g_vecBomb - paths[iWPTIndex]->origin).Length ();

                     if (fDistance > 512.0)
                     {
                        // Doesn't hear so not a good goal
                        CTBombPointClear (iWPTIndex);
                        BotTaskComplete (pBot);
                     }
                  }
                  else
                  {
                     // Doesn't hear so not a good goal
                     CTBombPointClear (iWPTIndex);
                     BotTaskComplete (pBot);
                  }
               }
            }
         }
      }

      // Do the actual movement checking
      BotHeadTowardWaypoint (pBot);
   }

   return (FALSE);
}


inline bool BotGoalIsValid (bot_t* pBot)
{
   int iGoal = BotGetSafeTask (pBot)->iData;

   if (iGoal == -1)
      return (FALSE); // Not decided about a goal

   else if (iGoal == pBot->curr_wpt_index)
      return (TRUE); // No Nodes needed

   else if (pBot->pWaypointNodes == NULL)
      return (FALSE); // No Path calculated

   // Got Path - check if still valid
   PATHNODE *Node = pBot->pWaypointNodes;

   while (Node->NextNode != NULL)
      Node = Node->NextNode;

   if (Node->iIndex == iGoal)
      return (TRUE);

   return (FALSE);
}


void BotCheckRadioCommands (bot_t *pBot)
{
   // Radio Handling and Reactings to them

   edict_t *pPlayer = pBot->pRadioEntity; // Entity who used this Radio Command
   edict_t *pEdict = pBot->pEdict; // Bots Entity
   float f_distance = (pPlayer->v.origin - pEdict->v.origin).Length ();

   switch (pBot->iRadioOrder)
   {
      case RADIO_FOLLOWME:
         // check if line of sight to object is not blocked (i.e. visible)
         if (BotEntityIsVisible (pBot, pPlayer->v.origin))
         {
            // If Bot isn't already 'used' then follow him about half of the time
            if (FNullEnt (pBot->pBotUser) && (RANDOM_LONG (0, 100) < 50))
            {
               int iNumFollowers = 0;
               int i;

               // Check if no more followers are allowed
               for (i = 0; i < gpGlobals->maxClients; i++)
               {
                  if (bots[i].is_used && !bots[i].bDead)
                  {
                     if (bots[i].pBotUser == pPlayer)
                        iNumFollowers++;
                  }
               }

               if (iNumFollowers < g_iMaxNumFollow)
               {
                  BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
                  pBot->pBotUser = pPlayer;

                  // don't pause/camp/follow anymore
                  int iTask = BotGetSafeTask (pBot)->iTask;

                  if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
                     BotGetSafeTask (pBot)->fTime = gpGlobals->time;

                  pBot->f_bot_use_time = gpGlobals->time;
                  bottask_t TempTask = {NULL, NULL, TASK_FOLLOWUSER, TASKPRI_FOLLOWUSER, -1, 0.0, TRUE};
                  BotPushTask (pBot, &TempTask);
               }
               else
                  BotPlayRadioMessage (pBot, RADIO_NEGATIVE);
            }
            else if (pBot->pBotUser == pPlayer)
               BotPlayRadioMessage (pBot, RADIO_IMINPOSITION);
            else if (RANDOM_LONG (0, 100) < 50)
               BotPlayRadioMessage (pBot, RADIO_NEGATIVE);
         }
         break;

      case RADIO_HOLDPOSITION:
         if (!FNullEnt (pBot->pBotUser) && (pBot->pBotUser == pPlayer))
         {
            pBot->pBotUser = NULL;
            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
            pBot->iCampButtons = 0;
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + RANDOM_FLOAT (30.0, 60.0), FALSE};
            BotPushTask (pBot, &TempTask);
         }
         break;

      // Someone called for Assistance
      case RADIO_TAKINGFIRE:
         if (FNullEnt (pBot->pBotUser))
         {
            if (FNullEnt (pBot->pBotEnemy))
            {
               // Decrease Fear Levels to lower probability of Bot seeking Cover again
               pBot->fFearLevel -= 0.2;

               if (pBot->fFearLevel < 0.0)
                  pBot->fFearLevel = 0.0;

               BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);

               // don't pause/camp anymore
               int iTask = BotGetSafeTask (pBot)->iTask;

               if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
                  BotGetSafeTask (pBot)->fTime = gpGlobals->time;

               pBot->f_bot_use_time = gpGlobals->time;
               pBot->vecPosition = pPlayer->v.origin;
               DeleteSearchNodes (pBot);

               bottask_t TempTask = {NULL, NULL, TASK_MOVETOPOSITION, TASKPRI_MOVETOPOSITION, -1, 0.0, TRUE};
               BotPushTask (pBot, &TempTask);
            }
            else
               BotPlayRadioMessage (pBot, RADIO_NEGATIVE);
         }
         break;

      case RADIO_NEEDBACKUP:
         if ((FNullEnt (pBot->pBotEnemy) && (BotEntityIsVisible (pBot, pPlayer->v.origin)))
             || (f_distance < 2048))
         {
            pBot->fFearLevel -= 0.1;
            if (pBot->fFearLevel < 0.0)
               pBot->fFearLevel = 0.0;

            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);

            // don't pause/camp anymore
            int iTask = BotGetSafeTask (pBot)->iTask;
            if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
               BotGetSafeTask (pBot)->fTime = gpGlobals->time;

            pBot->f_bot_use_time = gpGlobals->time;
            pBot->vecPosition = pPlayer->v.origin;
            DeleteSearchNodes (pBot);

            bottask_t TempTask = {NULL, NULL, TASK_MOVETOPOSITION, TASKPRI_MOVETOPOSITION, -1, 0.0, TRUE};
            BotPushTask (pBot, &TempTask);
         }
         else
            BotPlayRadioMessage (pBot, RADIO_NEGATIVE);

      case RADIO_GOGOGO:
         if (pPlayer == pBot->pBotUser)
         {
            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
            pBot->pBotUser = NULL;
            pBot->fFearLevel -= 0.3;

            if (pBot->fFearLevel < 0.0)
               pBot->fFearLevel = 0.0;
         }
         else if ((FNullEnt (pBot->pBotEnemy) && (BotEntityIsVisible (pBot, pPlayer->v.origin)))
                  || (f_distance < 2048))
         {
            int iTask = BotGetSafeTask (pBot)->iTask;

            if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
            {
               pBot->fFearLevel -= 0.3;

               if (pBot->fFearLevel < 0.0)
                  pBot->fFearLevel = 0.0;

               BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);

               // don't pause/camp anymore
               BotGetSafeTask (pBot)->fTime = gpGlobals->time;
               pBot->f_bot_use_time = gpGlobals->time;
               pBot->pBotUser = NULL;
               MAKE_VECTORS (pPlayer->v.v_angle);
               pBot->vecPosition = pPlayer->v.origin + gpGlobals->v_forward * RANDOM_LONG (1024, 2048);
               DeleteSearchNodes (pBot);
               bottask_t TempTask = {NULL, NULL, TASK_MOVETOPOSITION, TASKPRI_MOVETOPOSITION, -1, 0.0, TRUE};
               BotPushTask (pBot, &TempTask);
            }
         }
         else
            BotPlayRadioMessage (pBot, RADIO_NEGATIVE);
         break;

      case RADIO_STORMTHEFRONT:
         if ((FNullEnt (pBot->pBotEnemy) && BotEntityIsVisible (pBot, pPlayer->v.origin))
             || (f_distance < 1024))
         {
            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);

            // don't pause/camp anymore
            int iTask = BotGetSafeTask (pBot)->iTask;

            if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
               BotGetSafeTask (pBot)->fTime = gpGlobals->time;

            pBot->f_bot_use_time = gpGlobals->time;
            pBot->pBotUser = NULL;
            MAKE_VECTORS (pPlayer->v.v_angle);
            pBot->vecPosition = pPlayer->v.origin + gpGlobals->v_forward * RANDOM_LONG (1024, 2048);
            DeleteSearchNodes (pBot);
            bottask_t TempTask = {NULL, NULL, TASK_MOVETOPOSITION, TASKPRI_MOVETOPOSITION, -1, 0.0, TRUE};
            BotPushTask (pBot, &TempTask);

            pBot->fFearLevel -= 0.3;
            if (pBot->fFearLevel < 0.0)
               pBot->fFearLevel = 0.0;

            pBot->fAgressionLevel += 0.3;
            if (pBot->fAgressionLevel > 1.0)
               pBot->fAgressionLevel = 1.0;
         }
         break;

      case RADIO_FALLBACK:
         if ((FNullEnt (pBot->pBotEnemy) && (BotEntityIsVisible (pBot, pPlayer->v.origin)))
             || (f_distance < 1024))
         {
            pBot->fFearLevel += 0.5;
            if (pBot->fFearLevel > 1.0)
               pBot->fFearLevel = 1.0;

            pBot->fAgressionLevel -= 0.5;
            if (pBot->fAgressionLevel < 0.0)
               pBot->fAgressionLevel = 0.0;

            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
            if (BotGetSafeTask (pBot)->iTask == TASK_CAMP)
               BotGetSafeTask (pBot)->fTime += RANDOM_FLOAT (10.0, 15.0);
            else
            {
               // don't pause/camp anymore
               int iTask = BotGetSafeTask (pBot)->iTask;
               if (iTask == TASK_PAUSE)
                  BotGetSafeTask (pBot)->fTime = gpGlobals->time;

               pBot->f_bot_use_time = gpGlobals->time;
               pBot->pBotUser = NULL;

               // FIXME : Bot doesn't see enemy yet!
               pBot->f_bot_see_enemy_time = gpGlobals->time;

               // If Bot has no enemy
               if (pBot->vecLastEnemyOrigin == g_vecZero)
               {
                  float distance;
                  float nearestdistance = 9999.0;
                  int ind;

                  // Take nearest enemy to ordering Player
                  for (ind = 0; ind < gpGlobals->maxClients; ind++)
                  {
                     if (!clients[ind].IsUsed
                         || !clients[ind].IsAlive
                         || (clients[ind].iTeam == pBot->bot_team))
                        continue;

                     edict_t *pEnemy = clients[ind].pEdict;
                     distance = (pPlayer->v.origin - pEnemy->v.origin).Length ();

                     if (distance < nearestdistance)
                     {
                        nearestdistance = distance;
                        pBot->pLastEnemy = pEnemy;
                        pBot->vecLastEnemyOrigin = pEnemy->v.origin;
                     }
                  }
               }

               DeleteSearchNodes(pBot);
            }
         }
         break;

      case RADIO_REPORTTEAM:
         BotPlayRadioMessage (pBot, RADIO_REPORTINGIN);
         break;

      case RADIO_SECTORCLEAR:
         // Is Bomb planted and it's a Counter
         if (g_bBombPlanted)
         {
            // Check if it's a Counter Command
            if ((UTIL_GetTeam (pPlayer) == TEAM_CS_COUNTER) && (pBot->bot_team == TEAM_CS_COUNTER))
            {
               if (g_fTimeNextBombUpdate < gpGlobals->time)
               {
                  float min_distance = 9999.0;
                  int i;

                  // Find Nearest Bomb Waypoint to Player
                  for (i = 0; i < g_iNumGoalPoints; i++)
                  {
                     f_distance = (paths[g_rgiGoalWaypoints[i]]->origin - pPlayer->v.origin).Length ();

                     if (f_distance < min_distance)
                     {
                        min_distance = f_distance;
                        g_iLastBombPoint = g_rgiGoalWaypoints[i];
                     }
                  }

                  // Enter this WPT Index as taboo wpt
                  CTBombPointClear (g_iLastBombPoint);
                  g_fTimeNextBombUpdate = gpGlobals->time + 0.5;
               }

               // Does this Bot want to defuse ?
               if (BotGetSafeTask (pBot)->iTask == TASK_NORMAL)
               {
                  // Is he approaching this goal ?
                  if (BotGetSafeTask (pBot)->iData == g_iLastBombPoint)
                  {
                     BotGetSafeTask (pBot)->iData = -1;
                     BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
                  }
               }
            }
         }
         break;

      case RADIO_GETINPOSITION:
         if ((FNullEnt (pBot->pBotEnemy) && (BotEntityIsVisible (pBot, pPlayer->v.origin)))
             || (f_distance < 1024))
         {
            BotPlayRadioMessage (pBot, RADIO_AFFIRMATIVE);
            if (BotGetSafeTask (pBot)->iTask == TASK_CAMP)
               BotGetSafeTask (pBot)->fTime = gpGlobals->time + RANDOM_FLOAT (30.0, 60.0);
            else
            {
               // don't pause anymore
               int iTask = BotGetSafeTask (pBot)->iTask;
               if (iTask == TASK_PAUSE)
                  BotGetSafeTask (pBot)->fTime = gpGlobals->time;

               pBot->f_bot_use_time = gpGlobals->time;
               pBot->pBotUser = NULL;

               // FIXME : Bot doesn't see enemy yet!
               pBot->f_bot_see_enemy_time = gpGlobals->time;

               // If Bot has no enemy
               if (pBot->vecLastEnemyOrigin == g_vecZero)
               {
                  float distance;
                  float nearestdistance = 9999.0;
                  int ind;

                  // Take nearest enemy to ordering Player
                  for (ind = 0; ind < gpGlobals->maxClients; ind++)
                  {
                     if (!clients[ind].IsUsed
                         || !clients[ind].IsAlive
                         || (clients[ind].iTeam == pBot->bot_team))
                        continue;

                     edict_t *pEnemy = clients[ind].pEdict;
                     distance = (pPlayer->v.origin - pEnemy->v.origin).Length ();

                     if (distance < nearestdistance)
                     {
                        nearestdistance = distance;
                        pBot->pLastEnemy = pEnemy;
                        pBot->vecLastEnemyOrigin = pEnemy->v.origin;
                     }
                  }
               }

               DeleteSearchNodes(pBot);

               // Push camp task on to stack
               bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, gpGlobals->time + RANDOM_FLOAT (30.0, 60.0), TRUE};
               BotPushTask (pBot, &TempTask);

               // Push Move Command
               TempTask.iTask = TASK_MOVETOPOSITION;
               TempTask.fDesire = TASKPRI_MOVETOPOSITION;
               TempTask.iData = BotFindDefendWaypoint (pBot, pPlayer->v.origin);
               BotPushTask (pBot, &TempTask);
               pBot->iCampButtons |= IN_DUCK;
            }
         }

         break;
   }

   // Radio Command has been handled, reset
   pBot->iRadioOrder = 0;

   return;
}


int BotFindGoal (bot_t *pBot)
{
   // Chooses a Destination (Goal) Waypoint for a Bot

   int iTactic;
   int iOffensive;
   int iDefensive;
   int iGoalDesire;
   int iForwardDesire;
   int iCampDesire;
   int iBackoffDesire;
   int iTacticChoice;
   int *pOffensiveWPTS = NULL;
   int iNumOffensives;
   int *pDefensiveWPTS = NULL;
   int iNumDefensives;
   bool bHasHostage = BotHasHostage (pBot);
   int index;
   int min_index;
   float distance;
   float min_distance;
   int iGoalChoices[4];
   float iGoalDistances[4];
   edict_t *pEdict;

   pEdict = pBot->pEdict;

   // Pathfinding Behaviour depending on Maptype
   if (g_bUseExperience)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
      {
         pOffensiveWPTS = &g_rgiCTWaypoints[0];
         iNumOffensives = g_iNumCTPoints;
         pDefensiveWPTS = &g_rgiTerrorWaypoints[0];
         iNumDefensives = g_iNumTerrorPoints;
      }
      else
      {
         pOffensiveWPTS = &g_rgiTerrorWaypoints[0];
         iNumOffensives = g_iNumTerrorPoints;
         pDefensiveWPTS = &g_rgiCTWaypoints[0];
         iNumDefensives = g_iNumCTPoints;
      }

      // Terrorist carrying the C4 ?
      if ((pBot->pEdict->v.weapons & (1 << CS_WEAPON_C4))
          || pBot->bIsVIP)
      {
         iTactic = 3;
         goto tacticchosen;
      }
      else if (bHasHostage && (pBot->bot_team == TEAM_CS_COUNTER))
      {
         min_distance = 9999;
         min_index = -1;

         for (index = 0; index < g_iNumWaypoints; index++)
         {
            distance = (paths[index]->origin - pEdict->v.origin).Length();

            if ((paths[index]->flags & W_FL_RESCUE) && (distance < min_distance))
            {
               min_distance = distance;
               min_index = index;
            }
         }

         if (min_index != -1)
            return (min_index);
      }

      iOffensive = pBot->fAgressionLevel * 100;
      iDefensive = pBot->fFearLevel * 100;

      if ((g_iMapType & MAP_AS) || (g_iMapType & MAP_CS))
      {
         if (pBot->bot_team == TEAM_CS_TERRORIST)
         {
            iDefensive += 25;
            iOffensive -= 25;
         }
      }

      if (g_iMapType & MAP_DE)
      {
         if (pBot->bot_team == TEAM_CS_COUNTER)
         {
            if (g_bBombPlanted)
            {
               if (g_bBotChat && g_bBombSayString)
               {
                  BotPrepareChatMessage (pBot, szBombChat[RANDOM_LONG (0, iNumBombChats - 1)]);
                  BotPushMessageQueue (pBot, MSG_CS_SAY);
                  g_bBombSayString = FALSE;
               }

               return (BotChooseBombWaypoint (pBot));
            }

            iDefensive += 25;
            iOffensive -= 25;
         }
      }

      iGoalDesire = RANDOM_LONG (0, 100) + iOffensive;
      iForwardDesire = RANDOM_LONG (0, 100) + iOffensive;
      iCampDesire = RANDOM_LONG (0, 100) + iDefensive;
      iBackoffDesire = RANDOM_LONG (0, 100) + iDefensive;

      iTacticChoice = iBackoffDesire;
      iTactic = 0;

      if (iCampDesire > iTacticChoice)
      {
         iTacticChoice = iCampDesire;
         iTactic = 1;
      }
      if (iForwardDesire > iTacticChoice)
      {
         iTacticChoice = iForwardDesire;
         iTactic = 2;
      }
      if (iGoalDesire > iTacticChoice)
      {
         iTacticChoice = iGoalDesire;
         iTactic = 3;
      }

tacticchosen:
      for (index = 0; index < 4; index++)
      {
         iGoalChoices[index] = -1;
         iGoalDistances[index] = 9999.0;
      }

      // Defensive Goal
      if (iTactic == 0)
      {
         for (index = 0; index < 4; index++)
         {
            iGoalChoices[index] = pDefensiveWPTS[RANDOM_LONG (0, iNumDefensives - 1)];
            assert (iGoalChoices[index] >= 0 && iGoalChoices[index] < g_iNumWaypoints);
         }
      }

      // Camp Waypoint Goal
      else if (iTactic == 1)
      {
         for (index = 0; index < 4; index++)
         {
            iGoalChoices[index] = g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)];
            assert (iGoalChoices[index] >= 0 && iGoalChoices[index] < g_iNumWaypoints);
         }
      }

      // Offensive Goal
      else if (iTactic == 2)
      {
         for (index = 0; index < 4; index++)
         {
            iGoalChoices[index] = pOffensiveWPTS[RANDOM_LONG (0, iNumOffensives - 1)];
            assert (iGoalChoices[index] >= 0 && iGoalChoices[index] < g_iNumWaypoints);
         }
      }

      // Map Goal Waypoint
      else if (iTactic == 3)
      {
         for (index = 0; index < 4; index++)
         {
            iGoalChoices[index] = g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)];
            assert (iGoalChoices[index] >= 0 && iGoalChoices[index] < g_iNumWaypoints);
         }
      }

      if ((pBot->curr_wpt_index < 0) || (pBot->curr_wpt_index >= g_iNumWaypoints))
         pBot->curr_wpt_index = WaypointFindNearestToMove (pBot->pEdict->v.origin);

      int iBotIndex = pBot->curr_wpt_index;
      int iTestIndex;
      bool bSorting;

      do
      {
         bSorting = FALSE;
         for (index = 0; index < 3; index++)
         {
            iTestIndex = iGoalChoices[index + 1];
            if (iTestIndex < 0)
               break;

            if (pBot->bot_team == TEAM_CS_TERRORIST)
            {
               if ((pBotExperienceData + (iBotIndex * g_iNumWaypoints) + iGoalChoices[index])->wTeam0Value
                   < (pBotExperienceData + (iBotIndex * g_iNumWaypoints) + iTestIndex)->wTeam0Value)
               {
                  iGoalChoices[index + 1] = iGoalChoices[index];
                  iGoalChoices[index] = iTestIndex;
                  bSorting = TRUE;
               }
            }
            else
            {
               if ((pBotExperienceData + (iBotIndex * g_iNumWaypoints) + iGoalChoices[index])->wTeam1Value
                   < (pBotExperienceData + (iBotIndex * g_iNumWaypoints) + iTestIndex)->wTeam1Value)
               {
                  iGoalChoices[index + 1] = iGoalChoices[index];
                  iGoalChoices[index] = iTestIndex;
                  bSorting = TRUE;
               }
            }

         }
      } while (bSorting);

      return (iGoalChoices[0]);
   }
   else
   {
      int iRandomPick = RANDOM_LONG (1, 100);

      if (g_iMapType & MAP_AS)
      {
         if (pBot->bIsVIP)
         {
            // 90% choose a Goal Waypoint
            if (iRandomPick < 70)
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 90)
               return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
            else
               return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
         }
         else
         {
            if (pBot->bot_team == TEAM_CS_TERRORIST)
            {
               if (iRandomPick < 30)
                  return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
               else if (iRandomPick < 60)
                  return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
               else if (iRandomPick < 90)
                  return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
               else
                  return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
            }
            else
            {
               if (iRandomPick < 50)
                  return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
               else if (iRandomPick < 70)
                  return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
               else if (iRandomPick < 90)
                  return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
               else
                  return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
            }
         }
      }

      if (g_iMapType & MAP_CS)
      {
         bHasHostage = BotHasHostage (pBot);

         if (pBot->bot_team == TEAM_CS_TERRORIST)
         {
            if (iRandomPick < 30)
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 60)
               return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
            else if (iRandomPick < 90)
               return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
            else
               return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
         }
         else
         {
            if (bHasHostage)
            {
               min_distance = 9999;
               min_index = -1;

               for (index = 0; index < g_iNumWaypoints; index++)
               {
                  distance = (paths[index]->origin - pEdict->v.origin).Length();

                  if ((paths[index]->flags & W_FL_RESCUE) && (distance < min_distance))
                  {
                     min_distance = distance;
                     min_index = index;
                  }
               }

               if (min_index != -1)
                  return (min_index);
            }
            else if (iRandomPick < 50)
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 70)
               return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
            else if (iRandomPick < 90)
               return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
            else
               return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
         }
      }

      if (g_iMapType & MAP_DE)
      {
         if (pBot->bot_team == TEAM_CS_TERRORIST)
         {
            // Terrorist carrying the C4 ?
            if (pBot->pEdict->v.weapons & (1 << CS_WEAPON_C4))
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 30)
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 60)
               return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
            else if (iRandomPick < 90)
               return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
            else
               return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
         }
         else
         {
            if (g_bBombPlanted)
            {
               if (g_bBotChat && g_bBombSayString)
               {
                  BotPrepareChatMessage (pBot, szBombChat[RANDOM_LONG (0, iNumBombChats - 1)]);
                  BotPushMessageQueue (pBot, MSG_CS_SAY);
                  g_bBombSayString = FALSE;
               }

               return (BotChooseBombWaypoint (pBot));
            }
            else if (iRandomPick < 50)
               return (g_rgiGoalWaypoints[RANDOM_LONG (0, g_iNumGoalPoints - 1)]);
            else if (iRandomPick < 70)
               return (g_rgiCTWaypoints[RANDOM_LONG (0, g_iNumCTPoints - 1)]);
            else if (iRandomPick < 90)
               return (g_rgiCampWaypoints[RANDOM_LONG (0, g_iNumCampPoints - 1)]);
            else
               return (g_rgiTerrorWaypoints[RANDOM_LONG (0, g_iNumTerrorPoints - 1)]);
         }
      }
   }

   return (0);
}


int GetHighestFragsBot (int iTeam)
{
   bot_t *pFragBot;
   int iBestIndex = 0;
   float fBestFrags = -1;
   int bot_index;

   // Search Bots in this team
   for (bot_index = 0; bot_index < gpGlobals->maxClients; bot_index++)
   {
      pFragBot = &bots[bot_index];

      if (pFragBot->is_used && !FNullEnt (pFragBot->pEdict) && !pFragBot->bDead
          && (pFragBot->bot_team == iTeam) && (pFragBot->pEdict->v.frags > fBestFrags))
      {
         iBestIndex = bot_index;
         fBestFrags = pFragBot->pEdict->v.frags;
      }
   }

   return (iBestIndex);
}


void SelectLeaderEachTeam (bot_t *pBot)
{
   bot_t *pBotLeader;
   edict_t *pEdict = pBot->pEdict;

   if (g_iMapType & MAP_AS)
   {
      if (pBot->bIsVIP && !g_bLeaderChosenCT)
      {
         // VIP Bot is the leader
         pBot->bIsLeader = TRUE;

         if (RANDOM_LONG (1, 100) < 50)
         {
            BotPlayRadioMessage (pBot, RADIO_FOLLOWME);
            pBot->iCampButtons = 0;
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
            BotPushTask (pBot, &TempTask);
         }

         g_bLeaderChosenCT = TRUE;
      }
      else if ((pBot->bot_team == TEAM_CS_TERRORIST) && !g_bLeaderChosenT)
      {
         pBotLeader = &bots[GetHighestFragsBot (pBot->bot_team)];
         pBotLeader->bIsLeader = TRUE;

         if (RANDOM_LONG (1, 100) < 50)
         {
            BotPlayRadioMessage (pBotLeader, RADIO_FOLLOWME);
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
            BotPushTask (pBotLeader, &TempTask);
         }

         g_bLeaderChosenT = TRUE;
      }
   }

   if (g_iMapType & MAP_CS)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
      {
         pBotLeader = &bots[GetHighestFragsBot (pBot->bot_team)];
         pBotLeader->bIsLeader = TRUE;

         if (RANDOM_LONG (1, 100) < 50)
         {
            BotPlayRadioMessage (pBotLeader, RADIO_FOLLOWME);
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
            BotPushTask (pBotLeader, &TempTask);
         }
      }
      else
      {
         pBotLeader = &bots[GetHighestFragsBot (pBot->bot_team)];
         pBotLeader->bIsLeader = TRUE;

         if (RANDOM_LONG (1, 100) < 50)
         {
            BotPlayRadioMessage (pBotLeader, RADIO_FOLLOWME);
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
            BotPushTask (pBotLeader, &TempTask);
         }
      }
   }

   if (g_iMapType & MAP_DE)
   {
      if ((pBot->bot_team == TEAM_CS_TERRORIST) && !g_bLeaderChosenT)
      {
         if (pEdict->v.weapons & (1 << CS_WEAPON_C4))
         {
            // Bot carrying the Bomb is the leader
            pBot->bIsLeader = TRUE;

            // Terrorist carrying a Bomb needs to have some company so order some Bots sometimes
            if (RANDOM_LONG (1, 100) < 50)
            {
               BotPlayRadioMessage (pBot, RADIO_FOLLOWME);
               pBot->iCampButtons = 0;
               bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
               BotPushTask (pBot, &TempTask);
            }

            g_bLeaderChosenT = TRUE;
         }
      }
      else if (!g_bLeaderChosenCT)
      {
         pBotLeader = &bots[GetHighestFragsBot (pBot->bot_team)];
         pBotLeader->bIsLeader = TRUE;

         if (RANDOM_LONG (1, 100) < 50)
         {
            BotPlayRadioMessage (pBotLeader, RADIO_FOLLOWME);
            bottask_t TempTask = {NULL, NULL, TASK_PAUSE, TASKPRI_PAUSE, -1, gpGlobals->time + 3.0, FALSE};
            BotPushTask (pBotLeader, &TempTask);
         }

         g_bLeaderChosenCT = TRUE;
      }
   }

   return;
}


void BotChooseAimDirection (bot_t *pBot)
{
   bool bCanChoose = TRUE;
   unsigned int iFlags = pBot->iAimFlags;

   // Don't allow Bot to look at danger positions under certain circumstances
   if (!(iFlags & (AIM_GRENADE | AIM_ENEMY | AIM_ENTITY)))
   {
      if (pBot->bOnLadder || pBot->bInWater
         || (pBot->curr_travel_flags & C_FL_JUMP) || (pBot->iWPTFlags & W_FL_LADDER))
      {
         iFlags &= ~(AIM_LASTENEMY | AIM_PREDICTPATH);
         bCanChoose = FALSE;
      }
   }

   if (iFlags & AIM_OVERRIDE)
      pBot->vecLookAt = pBot->vecCamp;
   else if (iFlags & AIM_GRENADE)
      pBot->vecLookAt = GetGunPosition (pBot->pEdict) + (pBot->vecGrenade.Normalize () * 1);
   else if (iFlags & AIM_ENEMY)
   {
      pBot->vecLookAt = pBot->vecEnemy;
      BotFocusEnemy (pBot);
   }
   else if (iFlags & AIM_ENTITY)
      pBot->vecLookAt = pBot->vecEntity;
   else if (iFlags & AIM_LASTENEMY)
   {
      pBot->vecLookAt = pBot->vecLastEnemyOrigin;

      // Did Bot just see Enemy and is quite agressive ?
      if (pBot->f_bot_see_enemy_time - pBot->f_actual_reaction_time + pBot->fBaseAgressionLevel > gpGlobals->time)
      {
         // Not using a Sniper Weapon ?
         if (!BotUsesSniper (pBot))
         {
            // Feel free to fire if shootable
            if (BotLastEnemyShootable (pBot))
               pBot->bWantsToFire = TRUE;
         }
      }
   }
   else if (iFlags & AIM_PREDICTPATH)
   {
      bool bRecalcPath = TRUE;

      if ((pBot->pTrackingEdict == pBot->pLastEnemy)
          && (pBot->fTimeNextTracking < gpGlobals->time))
         bRecalcPath = FALSE;

      if (bRecalcPath)
      {
         pBot->vecLookAt = paths[GetAimingWaypoint (pBot, pBot->vecLastEnemyOrigin, 8)]->origin;
         pBot->vecCamp = pBot->vecLookAt;
         pBot->fTimeNextTracking = gpGlobals->time + 0.5;
         pBot->pTrackingEdict = pBot->pLastEnemy;
      }
      else
         pBot->vecLookAt = pBot->vecCamp;
   }
   else if (iFlags & AIM_CAMP)
      pBot->vecLookAt = pBot->vecCamp;
   else if (iFlags & AIM_DEST)
   {
      pBot->vecLookAt = pBot->dest_origin;

      if (bCanChoose && g_bUseExperience && (pBot->curr_wpt_index != -1)
          && !(paths[pBot->curr_wpt_index]->flags & W_FL_LADDER))
      {
         int iIndex = pBot->curr_wpt_index;

         if (pBot->bot_team == TEAM_CS_TERRORIST)
         {
            if ((pBotExperienceData + (iIndex * g_iNumWaypoints) + iIndex)->iTeam0_danger_index != -1)
               pBot->vecLookAt = paths[(pBotExperienceData + (iIndex * g_iNumWaypoints) + iIndex)->iTeam0_danger_index]->origin;
         }
         else
         {
            if ((pBotExperienceData + (iIndex * g_iNumWaypoints) + iIndex)->iTeam1_danger_index != -1)
               pBot->vecLookAt = paths[(pBotExperienceData + (iIndex * g_iNumWaypoints) + iIndex)->iTeam1_danger_index]->origin;
         }
      }

      pBot->vecLookAt = pBot->vecLookAt + Vector (0, 0, 16);
   }

   if (pBot->vecLookAt == g_vecZero)
      pBot->vecLookAt = pBot->dest_origin;
}


void BotSetStrafeSpeed (bot_t *pBot, Vector vecMoveDir, float fStrafeSpeed)
{
   edict_t *pEdict = pBot->pEdict;
   Vector2D vec2LOS;
   Vector vecDestination = pEdict->v.origin + vecMoveDir * 2;
   float flDot;

   MAKE_VECTORS (pEdict->v.angles);

   vec2LOS = (vecMoveDir - pEdict->v.origin).Make2D ();
   vec2LOS = vec2LOS.Normalize ();

   flDot = DotProduct (vec2LOS, gpGlobals->v_forward.Make2D ());

   if (flDot > 0)
      pBot->f_sidemove_speed = fStrafeSpeed;
   else
      pBot->f_sidemove_speed = -fStrafeSpeed;
}


void BotThink (bot_t *pBot)
{
   // This function gets called each Frame and is the core of
   // all Bot AI. From here all other Subroutines are called

   int index = 0;
   Vector v_diff; // vector from previous to current location
   float moved_distance; // length of v_diff vector (distance bot moved)
   TraceResult tr;
   bool bBotMovement = FALSE;
   float flDot;
   bot_t *pOtherBot;
   int i, c;
   Vector v_direction;
   Vector v_angles;
   Vector v_dest;
   Vector v_src;
   bool bMoveToGoal = TRUE;

   edict_t *pEdict = pBot->pEdict;
   pEdict->v.flags |= FL_FAKECLIENT;

   pBot->fTimeFrameInterval = gpGlobals->time - pBot->fTimePrevThink;
   pBot->fTimePrevThink = gpGlobals->time;

   pEdict->v.button = 0;
   pBot->f_move_speed = 0.0;
   pBot->f_sidemove_speed = 0.0;
   pBot->bDead = (IsAlive (pEdict) ? FALSE : TRUE);

   // if the bot hasn't selected stuff to start the game yet, go do that...
   if (pBot->not_started)
      BotStartGame (pBot); // Select Team & Class

   // In Cs Health seems to be refilled in Spectator Mode that's why I'm doing this extra
   else if (pBot->bDead)
   {
      // Bot chatting turned on ?
      if (g_bBotChat)
      {
         if (!BotRepliesToPlayer (pBot) && (pBot->f_lastchattime + 10 < gpGlobals->time)
             && (g_fLastChatTime + 5.0 < gpGlobals->time))
         {
            // Say a Text every now and then
            if (RANDOM_LONG (1, 1500) < 2)
            {
               pBot->f_lastchattime = gpGlobals->time;
               g_fLastChatTime = gpGlobals->time;

               // Rotate used Strings Array up
               szUsedDeadChat[7] = szUsedDeadChat[6];
               szUsedDeadChat[6] = szUsedDeadChat[5];
               szUsedDeadChat[5] = szUsedDeadChat[4];
               szUsedDeadChat[4] = szUsedDeadChat[3];
               szUsedDeadChat[3] = szUsedDeadChat[2];
               szUsedDeadChat[2] = szUsedDeadChat[1];
               szUsedDeadChat[1] = szUsedDeadChat[0];

               bool bStringUsed = TRUE;
               int iStringIndex;
               int iCount = 0;

               while (bStringUsed)
               {
                  iStringIndex = RANDOM_LONG (0, iNumDeadChats - 1);
                  bStringUsed = FALSE;

                  for (i = 0; i < 8; i++)
                  {
                     if (szUsedDeadChat[i] == szDeadChat[iStringIndex])
                     {
                        iCount++;
                        if (iCount < 9)
                           bStringUsed = TRUE;
                     }
                  }
               }

               // Save new String
               szUsedDeadChat[0] = szDeadChat[iStringIndex];
               BotPrepareChatMessage (pBot, szDeadChat[iStringIndex]);
               BotPushMessageQueue (pBot, MSG_CS_SAY);
            }
         }
      }
   }

   // Bot is still buying - don't move
   else if ((pBot->iBuyCount > 0) && (pBot->iBuyCount < 8) && pBot->b_can_buy)
   {
      if (pBot->f_buy_time < gpGlobals->time)
         BotBuyStuff (pBot);

      // Bot has spawned 10 secs ago ? Something went wrong in buying so cancel it
      if (pBot->f_spawn_time + 10.0 < gpGlobals->time)
         pBot->iBuyCount = 0;
   }
   else
      bBotMovement = TRUE;

   // Check for pending Messages
   BotCheckMessageQueue (pBot);

   if (!bBotMovement || (gpGlobals->time <= g_fTimeRoundStart) || g_bWaypointsChanged)
   {
      g_engfuncs.pfnRunPlayerMove (pEdict, pEdict->v.v_angle, 0.0, 0, 0, 0, 0, msecval);
      return;
   }

   if (pBot->bCheckMyTeam)
   {
      pBot->bot_team = UTIL_GetTeam (pEdict);
      pBot->bCheckMyTeam = FALSE;
   }

   pBot->bOnLadder = (pEdict->v.movetype == MOVETYPE_FLY);
   pBot->bInWater = ((pEdict->v.waterlevel == 2) || (pEdict->v.waterlevel == 3));

   // Check if we already switched weapon mode
   if (pBot->bCheckWeaponSwitch && (pBot->f_spawn_time + 4.0 < gpGlobals->time))
   {
      if (BotHasShield (pBot))
      {
         if (BotHasShieldDrawn (pBot))
            pEdict->v.button |= IN_ATTACK2;
      }
      else
      {
         // Bot owns a Sniper Weapon ? Try to switch back to no zoom so Bot isn't moving slow
         if (BotUsesSniper (pBot))
         {
            if (pEdict->v.fov < 90)
               pEdict->v.button |= IN_ATTACK2;
         }

         // If no sniper weapon use a secondary mode at random times
         else
         {
            if ((pBot->current_weapon.iId == CS_WEAPON_M4A1) || (pBot->current_weapon.iId == CS_WEAPON_USP))
            {
               // Aggressive bots don't like the silencer (courtesy of Wei Mingzhi - good idea)
               if (RANDOM_LONG (1, 100) <= (pBot->bot_personality == 1 ? 25 : 75))
               {
                  if (pEdict->v.weaponanim > 6) // is the silencer not attached...
                     pEdict->v.button |= IN_ATTACK2; // attach the silencer
               }
               else
               {
                  if (pEdict->v.weaponanim <= 6) // is the silencer attached...
                     pEdict->v.button |= IN_ATTACK2; // detach the silencer
               }
            }
         }

         // If Psycho Bot switch to Knife
         if (pBot->bot_personality == 1)
            SelectWeaponByName (pBot, "weapon_knife");
      }

      if (RANDOM_LONG (1, 100) < 20)
      {
         bottask_t TempTask = {NULL, NULL, TASK_SPRAYLOGO, TASKPRI_SPRAYLOGO, -1, gpGlobals->time + 1.0, FALSE};
         BotPushTask (pBot, &TempTask);
      }

      // Select a Leader Bot for this team
      SelectLeaderEachTeam (pBot);

      pBot->bCheckWeaponSwitch = FALSE;
   }

   // FIXME: The following Timers aren't frame independant so it varies on slower/faster computers
   // Increase Reaction Time
   pBot->f_actual_reaction_time += 0.2;
   if (pBot->f_actual_reaction_time > pBot->f_ideal_reaction_time)
      pBot->f_actual_reaction_time = pBot->f_ideal_reaction_time;

   // Bot could be blinded by FlashBang or Smoke, recover from it
   pBot->f_view_distance += 3.0;
   if (pBot->f_view_distance > pBot->f_maxview_distance)
      pBot->f_view_distance = pBot->f_maxview_distance;

   // Maxspeed is set in ClientSetMaxspeed
   pBot->f_move_speed = pEdict->v.maxspeed;

   if (pBot->prev_time <= gpGlobals->time)
   {
      // see how far bot has moved since the previous position...
      v_diff = pBot->v_prev_origin - pEdict->v.origin;
      moved_distance = v_diff.Length ();

      // save current position as previous
      pBot->v_prev_origin = pEdict->v.origin;
      pBot->prev_time = gpGlobals->time + 0.2;
   }
   else
      moved_distance = 2.0;

   // If there's some Radio Message to respond, check it
   if (pBot->iRadioOrder != 0)
      BotCheckRadioCommands (pBot);

   // Do all Sensing, calculate/filter all Actions here
   BotSetConditions (pBot);

   int iDestIndex = pBot->curr_wpt_index;
   pBot->bCheckTerrain = TRUE;
   bool bShootLastPosition = FALSE;
   bool bMadShoot = FALSE;
   pBot->bWantsToFire = FALSE;

   // Get affected by SmokeGrenades (very basic!) and sense Grenades flying towards us
   BotCheckSmokeGrenades (pBot);
   pBot->bUsingGrenade = FALSE;

   if (BotUsesSniper (pBot) && FNullEnt (pBot->pBotEnemy)
       && (pBot->f_bot_see_enemy_time + 4.0 < gpGlobals->time))
   {
      // Try zooming out to move fast again
      if (pEdict->v.fov < 90)
         pEdict->v.button |= IN_ATTACK2;
   }

   switch (BotGetSafeTask (pBot)->iTask)
   {
   // Normal (roaming) Task
   case TASK_NORMAL:
      pBot->iAimFlags |= AIM_DEST;

      if (BotHasShieldDrawn (pBot))
         pEdict->v.button |= IN_ATTACK2;

      if ((g_fTimeRoundEnd < gpGlobals->time) && FNullEnt (pBot->pBotEnemy))
         pEdict->v.button |= IN_RELOAD; // Reload at the end of the round

      // User forced a Waypoint as a Goal ?
      if (g_iDebugGoalIndex != -1)
      {
         if (BotGetSafeTask (pBot)->iData != g_iDebugGoalIndex)
         {
            DeleteSearchNodes (pBot);
            BotGetSafeTask (pBot)->iData = g_iDebugGoalIndex;
         }
      }

      // If Bomb planted and it's a Counter
      // calculate new path to Bomb Point if he's not already heading for
      if (g_bBombPlanted && (pBot->bot_team == TEAM_CS_COUNTER))
      {
         if (BotGetSafeTask (pBot)->iData != -1)
         {
            if (!(paths[BotGetSafeTask (pBot)->iData]->flags & W_FL_GOAL))
            {
               DeleteSearchNodes (pBot);
               BotGetSafeTask (pBot)->iData = -1;
            }
         }
      }

      // Reached the destination (goal) waypoint ?
      if (BotDoWaypointNav (pBot))
      {
         // Spray Logo sometimes if allowed to do so
         if (!pBot->bLogoSprayed && g_bBotSpray)
         {
            if (RANDOM_LONG (1, 100) < 50)
            {
               bottask_t TempTask = {NULL, NULL, TASK_SPRAYLOGO, TASKPRI_SPRAYLOGO, -1, gpGlobals->time + 1.0, FALSE};
               BotPushTask (pBot, &TempTask);
            }
         }

         BotTaskComplete (pBot);
         pBot->prev_goal_index = -1;

         // Reached Waypoint is a Camp Waypoint
         if (paths[pBot->curr_wpt_index]->flags & W_FL_CAMP)
         {
            // Check if Bot has got a primary weapon and hasn't camped before
            if (BotHasPrimaryWeapon (pBot) && (pBot->fTimeCamping + 10.0 < gpGlobals->time)
                && !((pBot->bot_team == TEAM_CS_COUNTER) && g_bBombPlanted))
            {
               bool bCampingAllowed = TRUE;

               // Check if it's not allowed for this team to camp here
               if (pBot->bot_team == TEAM_CS_TERRORIST)
               {
                  if (paths[pBot->curr_wpt_index]->flags & W_FL_COUNTER)
                     bCampingAllowed = FALSE;
               }
               else
               {
                  if (paths[pBot->curr_wpt_index]->flags & W_FL_TERRORIST)
                     bCampingAllowed = FALSE;
               }

               // Check if another Bot is already camping here
               for (c = 0; c < gpGlobals->maxClients; c++)
               {
                  pOtherBot = &bots[c];

                  if (pOtherBot->is_used)
                  {
                     if (pOtherBot == pBot)
                        continue;

                     if (!pOtherBot->bDead && (pOtherBot->bot_team == pBot->bot_team)
                         && (pOtherBot->curr_wpt_index == pBot->curr_wpt_index))
                        bCampingAllowed = FALSE;
                  }
               }

               if (bCampingAllowed)
               {
                  // Crouched camping here ?
                  if (paths[pBot->curr_wpt_index]->flags & W_FL_CROUCH)
                     pBot->iCampButtons = IN_DUCK;
                  else
                     pBot->iCampButtons = 0;

                  if (!(pBot->iStates & STATE_SEEINGENEMY))
                  {
                     pEdict->v.button |= IN_RELOAD;   // reload - just to be sure
                     pBot->bIsReloading = TRUE;
                  }

                  pBot->fTimeCamping = gpGlobals->time + RANDOM_FLOAT (BotSkillDelays[pBot->bot_skill / 20].fBotCampStartDelay, BotSkillDelays[pBot->bot_skill / 20].fBotCampEndDelay);
                  bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, pBot->fTimeCamping, TRUE};
                  BotPushTask (pBot, &TempTask);

                  MAKE_VECTORS (Vector (paths[pBot->curr_wpt_index]->fcampstartx, paths[pBot->curr_wpt_index]->fcampstarty, 0));
                  pBot->vecCamp = paths[pBot->curr_wpt_index]->origin + gpGlobals->v_forward * 500;
                  pBot->iAimFlags |= AIM_CAMP;
                  pBot->iCampDirection = 0;

                  // Tell the world we're camping
                  BotPlayRadioMessage (pBot, RADIO_IMINPOSITION);
                  bMoveToGoal = FALSE;
                  pBot->bCheckTerrain = FALSE;
                  pBot->f_move_speed = 0;
                  pBot->f_sidemove_speed = 0;
               }
            }
         }
         else
         {
            // Some Goal Waypoints are map dependant so check it out...
            if (g_iMapType & MAP_CS)
            {
               // CT Bot has some stupid hossies following ?
               if (BotHasHostage (pBot) && (pBot->bot_team == TEAM_CS_COUNTER))
               {
                  // and reached a Rescue Point ?
                  if ((paths[pBot->curr_wpt_index]->flags & W_FL_RESCUE))
                  {
                     // Clear Array of Hostage ptrs
                     for (i = 0; i < MAX_HOSTAGES; i++)
                        pBot->pHostages[i] = NULL;

                     g_bHostageRescued = TRUE; // Notify T Bots that there's a rescue going on
                  }
               }
            }

            if (g_iMapType & MAP_DE)
            {
               // Reached Goal Waypoint
               if (paths[pBot->curr_wpt_index]->flags & W_FL_GOAL)
               {
                  // Is it a Terrorist carrying the bomb ?
                  if ((pBot->bot_team == TEAM_CS_TERRORIST) && (pEdict->v.weapons & (1 << CS_WEAPON_C4)))
                  {
                     FakeClientCommand (pEdict, "weapon_c4");
                     bottask_t TempTask = {NULL, NULL, TASK_PLANTBOMB, TASKPRI_PLANTBOMB, -1, 0.0, FALSE};
                     BotPushTask (pBot, &TempTask);

                     // Tell Teammates to move over here...
                     BotPlayRadioMessage (pBot, RADIO_NEEDBACKUP);
                  }

                  // Counter searching the Bomb ?
                  else if ((pBot->bot_team == TEAM_CS_COUNTER) && g_bBombPlanted)
                  {
                     CTBombPointClear (pBot->curr_wpt_index);
                     BotPlayRadioMessage (pBot, RADIO_SECTORCLEAR);
                  }
               }
            }
         }
      }

      // No more Nodes to follow - search new ones
      else if (!BotGoalIsValid (pBot))
      {
         pBot->f_move_speed = pEdict->v.maxspeed;
         DeleteSearchNodes (pBot);

         // Did we already decide about a goal before ?
         if (BotGetSafeTask (pBot)->iData != -1)
            iDestIndex = BotGetSafeTask (pBot)->iData;
         else
            iDestIndex = BotFindGoal (pBot);

         pBot->prev_goal_index = iDestIndex;

         // Remember Index
         BotGetSafeTask (pBot)->iData = iDestIndex;

         if (iDestIndex!= pBot->curr_wpt_index)
         {
            // Do Pathfinding if it's not the current waypoint
            pBot->pWayNodesStart = FindLeastCostPath (pBot, pBot->curr_wpt_index, iDestIndex);
            pBot->pWaypointNodes = pBot->pWayNodesStart;
         }
      }
      else
      {
         if (!(pEdict->v.flags & FL_DUCKING)
             && (pBot->fMinSpeed != pEdict->v.maxspeed))
            pBot->f_move_speed = pBot->fMinSpeed;
      }
      break;

   // Bot sprays messy Logos all over the place...
   case TASK_SPRAYLOGO:
      pBot->iAimFlags |= AIM_ENTITY;

      // Bot didn't spray this round ?
      if (!pBot->bLogoSprayed && (BotGetSafeTask (pBot)->fTime > gpGlobals->time))
      {
         MAKE_VECTORS (pEdict->v.v_angle);
         Vector vecSprayPos = pEdict->v.origin + pEdict->v.view_ofs + gpGlobals->v_forward * 128;
         TRACE_LINE (pEdict->v.origin + pEdict->v.view_ofs, vecSprayPos, ignore_monsters, pEdict, &tr);

         // No Wall in Front ?
         if (tr.flFraction >= 1.0)
            vecSprayPos.z -= 128.0;
         pBot->vecEntity = vecSprayPos;

         if (BotGetSafeTask (pBot)->fTime - 0.5 < gpGlobals->time)
         {
            // Emit Spraycan sound
            EMIT_SOUND_DYN2 (pEdict, CHAN_VOICE, "player/sprayer.wav", 1.0, ATTN_NORM, 0, 100);
            TRACE_LINE (pEdict->v.origin + pEdict->v.view_ofs, pEdict->v.origin + pEdict->v.view_ofs + gpGlobals->v_forward * 128, ignore_monsters, pEdict, &tr);

            // Paint the actual Logo Decal
            UTIL_DecalTrace (&tr, &szSprayNames[pBot->iSprayLogo][0]);
            pBot->bLogoSprayed = TRUE;
         }
      }
      else
         BotTaskComplete (pBot);

      bMoveToGoal = FALSE;
      pBot->bCheckTerrain = FALSE;
      pBot->f_wpt_timeset = gpGlobals->time;
      pBot->f_move_speed = 0;
      pBot->f_sidemove_speed = 0.0;
      break;

   // Hunt down Enemy
   case TASK_ENEMYHUNT:
      pBot->iAimFlags |= AIM_DEST;

      // Reached last Enemy Pos ?
      if (!FNullEnt (pBot->pBotEnemy) || FNullEnt (pBot->pLastEnemy))
      {
         // Forget about it...
         BotRemoveCertainTask (pBot, TASK_ENEMYHUNT);
         pBot->prev_goal_index = -1;
      }
      else if (BotDoWaypointNav (pBot))
      {
         // Forget about it...
         BotTaskComplete (pBot);
         pBot->prev_goal_index = -1;
         pBot->vecLastEnemyOrigin = g_vecZero;
      }

      // Do we need to calculate a new Path ?
      else if (pBot->pWaypointNodes == NULL)
      {
         DeleteSearchNodes (pBot);

         // Is there a remembered Index ?
         if ((BotGetSafeTask (pBot)->iData != -1)
             && (BotGetSafeTask (pBot)->iData < g_iNumWaypoints))
            iDestIndex = BotGetSafeTask (pBot)->iData;

         // No. We need to find a new one
         else
         {
            float min_distance;
            float distance;
            min_distance = 9999.0;

            // Search nearest waypoint to enemy
            for (i = 0; i < g_iNumWaypoints; i++)
            {
               distance = (paths[i]->origin - pBot->vecLastEnemyOrigin).Length ();

               if (distance < min_distance)
               {
                  iDestIndex = i;
                  min_distance = distance;
               }
            }
         }

         // Remember Index
         pBot->prev_goal_index = iDestIndex;
         BotGetSafeTask (pBot)->iData = iDestIndex;
         pBot->pWayNodesStart = FindLeastCostPath (pBot, pBot->curr_wpt_index, iDestIndex);
         pBot->pWaypointNodes = pBot->pWayNodesStart;
      }

      // Bots skill higher than 70 ?
      if (pBot->bot_skill > 70)
      {
         // Then make him move slow if near Enemy
         if (!(pBot->curr_travel_flags & C_FL_JUMP))
         {
            if (pBot->curr_wpt_index != -1)
            {
               if ((paths[pBot->curr_wpt_index]->Radius < 32) && !pBot->bOnLadder
                   && !pBot->bInWater && (pBot->f_bot_see_enemy_time + 1.0 < gpGlobals->time))
                  pEdict->v.button |= IN_DUCK;
            }

            Vector v_diff = pBot->vecLastEnemyOrigin - pEdict->v.origin;
            float fDistance = v_diff.Length ();

            if ((fDistance < 700.0) && !(pEdict->v.flags & FL_DUCKING))
               pBot->f_move_speed = pEdict->v.maxspeed / 2;
         }
      }
      break;

   // Bot seeks Cover from Enemy
   case TASK_SEEKCOVER:
      pBot->iAimFlags |= AIM_DEST;
      if (FNullEnt (pBot->pLastEnemy) || !IsAlive (pBot->pLastEnemy))
      {
         BotTaskComplete (pBot);
         pBot->prev_goal_index = -1;
      }

      // Reached final Cover waypoint ?
      else if (BotDoWaypointNav (pBot))
      {
         pBot->byPathType = 2;

         // Yep. Activate Hide Behaviour
         BotTaskComplete (pBot);
         pBot->prev_goal_index = -1;
         bottask_t TempTask = {NULL, NULL, TASK_HIDE, TASKPRI_HIDE, -1, gpGlobals->time + RANDOM_FLOAT (2.0, 10.0), FALSE};
         BotPushTask (pBot, &TempTask);
         v_dest = pBot->vecLastEnemyOrigin;

         // Get a valid look direction
         BotGetCampDirection (pBot, &v_dest);
         pBot->iAimFlags |= AIM_CAMP;
         pBot->vecCamp = v_dest;
         pBot->iCampDirection = 0;

         // Chosen Waypoint is a Camp Waypoint ?
         if (paths[pBot->curr_wpt_index]->flags & W_FL_CAMP)
         {
            // Use the existing camp wpt prefs
            if (paths[pBot->curr_wpt_index]->flags & W_FL_CROUCH)
               pBot->iCampButtons = IN_DUCK;
            else
               pBot->iCampButtons = 0;
         }
         else
         {
            // Choose a crouch or stand pos
            if ((RANDOM_LONG (1, 100) < 30) && (paths[pBot->curr_wpt_index]->Radius < 32))
               pBot->iCampButtons = IN_DUCK;
            else
               pBot->iCampButtons = 0;

            // Enter look direction from previously calculated positions
            Vector vecAnglesToEnemy = UTIL_VecToAngles (pBot->vecCamp - pEdict->v.origin);

            paths[pBot->curr_wpt_index]->fcampstartx = vecAnglesToEnemy.x;
            paths[pBot->curr_wpt_index]->fcampstarty = vecAnglesToEnemy.y;
            paths[pBot->curr_wpt_index]->fcampendx = vecAnglesToEnemy.x;
            paths[pBot->curr_wpt_index]->fcampendy = vecAnglesToEnemy.y;
         }

         int iId = pBot->current_weapon.iId;

         if ((pBot->bIsReloading == FALSE) && (pBot->current_weapon.iClip < 5)
             && (pBot->current_weapon.iAmmo1 > 0))
         {
            pEdict->v.button |= IN_RELOAD;   // reload - just to be sure
            pBot->bIsReloading = TRUE;
         }

         pBot->f_move_speed = 0;
         pBot->f_sidemove_speed = 0;
         bMoveToGoal = FALSE;
         pBot->bCheckTerrain = FALSE;
      }

      // We didn't choose a Cover Waypoint yet or lost it due to an attack ?
      else if (!BotGoalIsValid (pBot))
      {
         DeleteSearchNodes (pBot);

         if (BotGetSafeTask (pBot)->iData != -1)
            iDestIndex = BotGetSafeTask (pBot)->iData;
         else
         {
            iDestIndex = BotFindCoverWaypoint(pBot, 1024);
            if (iDestIndex == -1)
               iDestIndex = RANDOM_LONG (0, g_iNumWaypoints - 1);
         }

         pBot->iCampDirection = 0;
         pBot->prev_goal_index = iDestIndex;
         BotGetSafeTask (pBot)->iData = iDestIndex;

         if (iDestIndex != pBot->curr_wpt_index)
         {
            pBot->pWayNodesStart = FindLeastCostPath (pBot, pBot->curr_wpt_index, iDestIndex);
            pBot->pWaypointNodes = pBot->pWayNodesStart;
         }
      }
      break;

   // Plain Attacking
   case TASK_ATTACK:
      bMoveToGoal = FALSE;
      pBot->bCheckTerrain = FALSE;

      if (!FNullEnt (pBot->pBotEnemy))
         BotDoAttackMovement (pBot);
      else
      {
         BotTaskComplete (pBot);
         pBot->dest_origin = pBot->vecLastEnemyOrigin;
      }

      pBot->f_wpt_timeset = gpGlobals->time;
      break;

   // Bot is pausing
   case TASK_PAUSE:
      bMoveToGoal = FALSE;
      pBot->bCheckTerrain = FALSE;
      pBot->f_wpt_timeset = gpGlobals->time;
      pBot->f_move_speed = 0.0;
      pBot->f_sidemove_speed = 0.0;
      pBot->iAimFlags |= AIM_DEST;

      // Is Bot blinded and above average skill ?
      if ((pBot->f_view_distance < 500.0) && (pBot->bot_skill > 60))
      {
         // Go mad !
         pBot->f_move_speed = -fabs ((pBot->f_view_distance - 500.0) / 2);
         if (pBot->f_move_speed < -pEdict->v.maxspeed)
            pBot->f_move_speed = -pEdict->v.maxspeed;

         MAKE_VECTORS (pEdict->v.v_angle);
         pBot->vecCamp = GetGunPosition (pEdict) + gpGlobals->v_forward * 500;
         pBot->iAimFlags |= AIM_OVERRIDE;
         pBot->bWantsToFire = TRUE;
      }
      else
         pEdict->v.button |= pBot->iCampButtons;

      // body angles = view angles
      pEdict->v.angles.y = pEdict->v.v_angle.y;

      // Stop camping if Time over or gets Hurt by something else than bullets
      if ((BotGetSafeTask (pBot)->fTime < gpGlobals->time) || (pBot->iLastDamageType > 0))
         BotTaskComplete (pBot);
      break;

   // Blinded (flashbanged) Behaviour
   case TASK_BLINDED:

      bMoveToGoal = FALSE;
      pBot->bCheckTerrain = FALSE;
      pBot->f_wpt_timeset = gpGlobals->time;

      switch (pBot->bot_personality)
      {
         // Normal
         case 0:
            if ((pBot->bot_skill > 60) && (pBot->vecLastEnemyOrigin != g_vecZero))
               bShootLastPosition = TRUE;
            break;
         // Psycho
         case 1:
            if (pBot->vecLastEnemyOrigin != g_vecZero)
               bShootLastPosition = TRUE;
            else
               bMadShoot = TRUE;
      }

      // If Bot remembers last Enemy Position
      if (bShootLastPosition)
      {
         // Face it and shoot
         pBot->vecLookAt = pBot->vecLastEnemyOrigin;
         pBot->bWantsToFire = TRUE;
      }

      // If Bot is mad
      else if (bMadShoot)
      {
         // Just shoot in forward direction
         MAKE_VECTORS (pEdict->v.v_angle);
         pBot->vecLookAt = GetGunPosition (pEdict) + gpGlobals->v_forward * 500;
         pBot->bWantsToFire = TRUE;
      }

      pBot->f_move_speed = pBot->f_blindmovespeed_forward;
      pBot->f_sidemove_speed = pBot->f_blindmovespeed_side;

      if (pBot->f_blind_time < gpGlobals->time)
         BotTaskComplete (pBot);
      break;

   // Camping Behaviour
   case TASK_CAMP:
      {
      pBot->iAimFlags |= AIM_CAMP;
      pBot->bCheckTerrain = FALSE;
      bMoveToGoal = FALSE;

      // half the reaction time if camping because you're more aware of enemies if camping
      pBot->f_ideal_reaction_time = RANDOM_FLOAT (BotSkillDelays[pBot->bot_skill / 20].fMinSurpriseDelay,
                                                  BotSkillDelays[pBot->bot_skill / 20].fMaxSurpriseDelay) / 2;
      pBot->f_wpt_timeset = gpGlobals->time;
      pBot->f_move_speed = 0;
      pBot->f_sidemove_speed = 0.0;
      GetValidWaypoint (pBot);

      if (pBot->fNextCampDirectionTime < gpGlobals->time)
      {
         int i;
         float distance;

         if (pBot->iCampDirection < 1)
         {
            v_dest.x = paths[pBot->curr_wpt_index]->fcampstartx;
            v_dest.y = paths[pBot->curr_wpt_index]->fcampstarty;
            v_dest.z = 0;
         }
         else
         {
            v_dest.x = paths[pBot->curr_wpt_index]->fcampendx;
            v_dest.y = paths[pBot->curr_wpt_index]->fcampendy;
            v_dest.z = 0;
         }

         if (v_dest == g_vecZero)
         {
            for (i = 0; i < g_iNumWaypoints; i++)
            {
               distance = (paths[i]->origin - pEdict->v.origin).Length ();

               if ((distance > 200) && (distance < 500) && FVisible (paths[i]->origin, pEdict))
                  break;
            }

            if (i < g_iNumWaypoints)
               v_dest = UTIL_VecToAngles (paths[i]->origin - pEdict->v.origin);
            else
               v_dest = Vector (0, RANDOM_FLOAT (-180, 180), 0); // last chance
         }

         MAKE_VECTORS (v_dest);
         pBot->vecCamp = paths[pBot->curr_wpt_index]->origin + gpGlobals->v_forward * 500;

         // Switch from 1 direction to the other
         pBot->fNextCampDirectionTime = gpGlobals->time + RANDOM_FLOAT (1, 4);
      }

      // Press remembered crouch Button
      pEdict->v.button |= pBot->iCampButtons;

      // body angles = view angles
      pEdict->v.angles.y = pEdict->v.v_angle.y;

      // Stop camping if Time over or gets Hurt by something else than bullets
      if ((BotGetSafeTask (pBot)->fTime < gpGlobals->time) || (pBot->iLastDamageType > 0))
         BotTaskComplete (pBot);
      break;
      }

   // Hiding Behaviour
   case TASK_HIDE:
      pBot->iAimFlags |= AIM_CAMP;
      pBot->bCheckTerrain = FALSE;
      bMoveToGoal = FALSE;

      // half the reaction time if camping
      pBot->f_ideal_reaction_time = RANDOM_FLOAT (BotSkillDelays[pBot->bot_skill / 20].fMinSurpriseDelay,
                                                  BotSkillDelays[pBot->bot_skill / 20].fMaxSurpriseDelay) / 2;
      pBot->f_wpt_timeset = gpGlobals->time;
      pBot->f_move_speed = 0;
      pBot->f_sidemove_speed = 0.0;
      GetValidWaypoint (pBot);

      if (BotHasShield (pBot))
      {
         if (!pBot->bIsReloading)
         {
            if (!BotHasShieldDrawn (pBot))
               pEdict->v.button |= IN_ATTACK2; // draw the shield!
            else
               pEdict->v.button |= IN_DUCK; // duck under if the shield is already drawn
         }
      }

      // If we see an enemy and aren't at a good camping point leave the spot
      if (pBot->iStates & STATE_SEEINGENEMY)
      {
         if (!(paths[pBot->curr_wpt_index]->flags & W_FL_CAMP))
         {
            BotTaskComplete (pBot);
            pBot->iCampButtons = 0;
            pBot->prev_goal_index = -1;
            if (!FNullEnt (pBot->pBotEnemy))
               BotDoAttackMovement(pBot);
            break;
         }
      }

      // If we don't have an enemy we're also free to leave
      else if (pBot->vecLastEnemyOrigin == g_vecZero)
      {
         BotTaskComplete (pBot);
         pBot->iCampButtons = 0;
         pBot->prev_goal_index = -1;
         if (BotGetSafeTask (pBot)->iTask == TASK_HIDE)
            BotTaskComplete (pBot);
         break;
      }

      pEdict->v.button |= pBot->iCampButtons;
      pBot->f_wpt_timeset = gpGlobals->time;

      // body angles = view angles
      pEdict->v.angles.y = pEdict->v.v_angle.y;

      // Stop camping if Time over or gets Hurt by something else than bullets
      if ((BotGetSafeTask (pBot)->fTime < gpGlobals->time) || (pBot->iLastDamageType > 0))
         BotTaskComplete (pBot);
      break;

   // Moves to a Position specified in pBot->vecPosition
   // Has a higher Priority than TASK_NORMAL
   case TASK_MOVETOPOSITION:
      pBot->iAimFlags |= AIM_DEST;

      if (BotHasShieldDrawn (pBot))
         pEdict->v.button |= IN_ATTACK2;

      // Reached destination ?
      if (BotDoWaypointNav (pBot))
      {
         // We're done
         BotTaskComplete (pBot);
         pBot->prev_goal_index = -1;
         pBot->vecPosition = g_vecZero;
      }

      // Didn't choose Goal Waypoint yet ?
      else if (!BotGoalIsValid (pBot))
      {
         DeleteSearchNodes (pBot);
         if ((BotGetSafeTask (pBot)->iData != -1)
             && (BotGetSafeTask (pBot)->iData < g_iNumWaypoints))
            iDestIndex = BotGetSafeTask (pBot)->iData;
         else
         {
            float min_distance = 9999.0;
            float distance;

            // Search nearest waypoint to Position
            for (i = 0; i < g_iNumWaypoints; i++)
            {
               distance = (paths[i]->origin - pBot->vecPosition).Length ();

               if (distance < min_distance)
               {
                  iDestIndex = i;
                  min_distance = distance;
               }
            }
         }

         pBot->prev_goal_index = iDestIndex;
         BotGetSafeTask (pBot)->iData = iDestIndex;
         pBot->pWayNodesStart = FindLeastCostPath (pBot, pBot->curr_wpt_index, iDestIndex);
         pBot->pWaypointNodes = pBot->pWayNodesStart;
      }
      break;

   // Planting the Bomb right now
   case TASK_PLANTBOMB:
      pBot->iAimFlags |= AIM_DEST;

      // We're still in the planting time and got the c4 ?
      if (pBot->b_bomb_blinking && (pEdict->v.weapons & (1 << CS_WEAPON_C4)))
      {
         bMoveToGoal = FALSE;
         pBot->bCheckTerrain = FALSE;
         pBot->f_wpt_timeset = gpGlobals->time;
         pEdict->v.button |= IN_ATTACK;
         pEdict->v.button |= IN_DUCK;
         pBot->f_move_speed = 0;
         pBot->f_sidemove_speed = 0;
      }

      // Done with planting
      else
      {
         BotTaskComplete (pBot);

         if (!(pEdict->v.weapons & (1 << CS_WEAPON_C4)))
         {
            // Notify the Team of this heroic action
            FakeClientCommand (pBot->pEdict, "say_team Planted the Bomb!\n");

            DeleteSearchNodes (pBot);

            // Push camp task on to stack
            float f_c4timer = CVAR_GET_FLOAT ("mp_c4timer");
            bottask_t TempTask = {NULL, NULL, TASK_CAMP, TASKPRI_CAMP, -1, gpGlobals->time + (f_c4timer / 2), TRUE};
            BotPushTask (pBot, &TempTask);

            // Push Move Command
            TempTask.iTask = TASK_MOVETOPOSITION;
            TempTask.fDesire = TASKPRI_MOVETOPOSITION;
            TempTask.iData = BotFindDefendWaypoint (pBot, pEdict->v.origin);
            BotPushTask (pBot, &TempTask);
            pBot->iCampButtons |= IN_DUCK;
         }
      }
      break;

   // Bomb defusing Behaviour
   case TASK_DEFUSEBOMB:
      pBot->iAimFlags |= AIM_ENTITY;
      bMoveToGoal = FALSE;
      pBot->bCheckTerrain = FALSE;

      pBot->f_wpt_timeset = gpGlobals->time;

      // Bomb still there ?
      if (!FNullEnt (pBot->pBotPickupItem))
      {
         // Get Face Position
         pBot->vecEntity = pBot->pBotPickupItem->v.origin;
         pEdict->v.button |= IN_USE;
         pEdict->v.button |= IN_DUCK;
      }
      else
         BotTaskComplete (pBot);

      pBot->f_move_speed = 0;
      pBot->f_sidemove_speed = 0;
      break;

   // Follow User Behaviour
   case TASK_FOLLOWUSER:
      pBot->iAimFlags |= AIM_DEST;

      // Follow User ?
      if (BotFollowUser (pBot))
      {
         // Imitate Users crouching
         pEdict->v.button |= (pBot->pBotUser->v.button & IN_DUCK);
         pBot->dest_origin = pBot->pBotUser->v.origin;
         pBot->vecLookAt = pBot->dest_origin;
      }
      else
         BotTaskComplete (pBot);

      break;

   // HE Grenade Throw Behaviour
   case TASK_THROWHEGRENADE:
      pBot->iAimFlags |= AIM_GRENADE;

      v_dest = pBot->vecThrow;

      if (!(pBot->iStates & STATE_SEEINGENEMY))
      {
         pBot->f_move_speed = 0.0;
         pBot->f_sidemove_speed = 0.0;
         bMoveToGoal = FALSE;
      }
      else if (!(pBot->iStates & STATE_SUSPECTENEMY) && !FNullEnt (pBot->pBotEnemy))
      {
         v_dest = pBot->pBotEnemy->v.origin;
         v_src = pBot->pBotEnemy->v.velocity;
         v_src.z = 0.0;
         v_dest = v_dest + (v_src * 0.3);
      }

      pBot->bUsingGrenade = TRUE;
      pBot->bCheckTerrain = FALSE;

      pBot->vecGrenade = VecCheckThrow  (pEdict, GetGunPosition (pEdict), v_dest, 1.0);
      if (pBot->vecGrenade == g_vecZero && !bMoveToGoal)
         pBot->vecGrenade = VecCheckToss  (pEdict, GetGunPosition (pEdict), v_dest);

      // We're done holding the Button (about to throw) ?
      if ((pBot->vecGrenade == g_vecZero) || (BotGetSafeTask (pBot)->fTime < gpGlobals->time)
          || (pEdict->v.weapons & (1 << CS_WEAPON_HEGRENADE) == 0))
      {
         if (pBot->vecGrenade == g_vecZero)
         {
            pBot->f_grenade_check_time = gpGlobals->time + RANDOM_FLOAT (2, 5);
            BotSelectBestWeapon (pBot);
         }

         BotTaskComplete (pBot);
      }
      else
      {
         pEdict->v.button |= IN_ATTACK;

         // Select Grenade if we're not already using it
         if (pBot->current_weapon.iId != CS_WEAPON_HEGRENADE)
         {
            if (pBot->current_weapon.iId != CS_WEAPON_INSWITCH)
            {
               SelectWeaponByName(pBot, "weapon_hegrenade");
               BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
            }
            else
               BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
         }
      }

      pEdict->v.button |= pBot->iCampButtons;
      break;

   // Flashbang Throw Behaviour
   // Basically the same code like for HE's
   case TASK_THROWFLASHBANG:
      pBot->iAimFlags |= AIM_GRENADE;
      v_dest = pBot->vecThrow;

      if (!(pBot->iStates & STATE_SEEINGENEMY))
      {
         pBot->f_move_speed = 0.0;
         pBot->f_sidemove_speed = 0.0;
         bMoveToGoal = FALSE;
      }
      else
      {
         if (!(pBot->iStates & STATE_SUSPECTENEMY) && !FNullEnt (pBot->pBotEnemy))
         {
            v_dest = pBot->pBotEnemy->v.origin;
            v_src = pBot->pBotEnemy->v.velocity;
            v_src.z = 0.0;
            v_dest = v_dest + (v_src * 0.3);
         }
      }

      pBot->bUsingGrenade = TRUE;
      pBot->bCheckTerrain = FALSE;

      pBot->vecGrenade = VecCheckThrow  (pEdict, GetGunPosition (pEdict), v_dest, 1.0);
      if (pBot->vecGrenade == g_vecZero && !bMoveToGoal)
         pBot->vecGrenade = VecCheckToss  (pEdict, GetGunPosition (pEdict), v_dest);

      // We're done holding the Button (about to throw) ?
      if ((pBot->vecGrenade == g_vecZero) || (BotGetSafeTask (pBot)->fTime < gpGlobals->time)
          || (pEdict->v.weapons & (1 << CS_WEAPON_FLASHBANG) == 0))
      {
         if (pBot->vecGrenade == g_vecZero)
         {
            pBot->f_grenade_check_time = gpGlobals->time + RANDOM_FLOAT (2, 5);
            BotSelectBestWeapon (pBot);
         }

         BotTaskComplete (pBot);
      }
      else
      {
         pEdict->v.button |= IN_ATTACK;

         // Select Grenade if we're not already using it
         if (pBot->current_weapon.iId != CS_WEAPON_FLASHBANG)
         {
            if (pBot->current_weapon.iId != CS_WEAPON_INSWITCH)
            {
               SelectWeaponByName (pBot, "weapon_flashbang");
               BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
            }
            else
               BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
         }
      }
      pEdict->v.button |= pBot->iCampButtons;
      break;

   // Smoke Grenade Throw Behaviour
   // A bit different to the others because it mostly
   // tries to throw the Gren on the ground
   case TASK_THROWSMOKEGRENADE:
      pBot->iAimFlags |= AIM_GRENADE;
      if (!(pBot->iStates & STATE_SEEINGENEMY))
      {
         pBot->f_move_speed = 0.0;
         pBot->f_sidemove_speed = 0.0;
         bMoveToGoal = FALSE;
      }
      pBot->bCheckTerrain = FALSE;
      pBot->bUsingGrenade = TRUE;
      v_src = pBot->vecLastEnemyOrigin;
      v_src = v_src - pEdict->v.velocity;

      // Predict where the enemy is in 0.5 secs
      if (!FNullEnt (pBot->pBotEnemy))
         v_src = v_src + pBot->pBotEnemy->v.velocity * 0.5;

      pBot->vecGrenade = v_src;
      if ((BotGetSafeTask (pBot)->fTime < gpGlobals->time)
          || !(pEdict->v.weapons & (1 << CS_WEAPON_SMOKEGRENADE)))
      {
         BotTaskComplete (pBot);
         break;
      }

      pEdict->v.button |= IN_ATTACK;
      if (pBot->current_weapon.iId != CS_WEAPON_SMOKEGRENADE)
      {
         if (pBot->current_weapon.iId != CS_WEAPON_INSWITCH)
         {
            SelectWeaponByName(pBot, "weapon_smokegrenade");
            BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
         }
         else
            BotGetSafeTask (pBot)->fTime = gpGlobals->time + TIME_GRENPRIME;
      }
      break;

   // Shooting breakables in the way action
   case TASK_SHOOTBREAKABLE:
      pBot->iAimFlags |= AIM_OVERRIDE;

      // Breakable destroyed ?
      if (!BotFindBreakable (pBot))
      {
         BotTaskComplete (pBot);
         break;
      }
      pEdict->v.button |= pBot->iCampButtons;

      pBot->bCheckTerrain = FALSE;
      bMoveToGoal = FALSE;
      pBot->f_wpt_timeset = gpGlobals->time;
      v_src = pBot->vecBreakable;
      pBot->vecCamp = v_src;

      flDot = GetShootingConeDeviation (pEdict, &v_src);

      // Is Bot facing the Breakable ?
      if (flDot>= 0.90)
      {
         pBot->f_move_speed = 0.0;
         pBot->f_sidemove_speed = 0.0;
         pBot->bWantsToFire = TRUE;
      }
      else
      {
         pBot->bCheckTerrain = TRUE;
         bMoveToGoal = TRUE;
      }
      break;

   // Picking up Items and stuff behaviour
   case TASK_PICKUPITEM:
      if (FNullEnt (pBot->pBotPickupItem))
      {
         pBot->pBotPickupItem = NULL;
         BotTaskComplete (pBot);
         break;
      }

      // func Models need special origin handling
      if ((strncmp ("func_", STRING (pBot->pBotPickupItem->v.classname), 5) == 0)
          || (pBot->pBotPickupItem->v.flags & FL_MONSTER))
         v_dest = VecBModelOrigin (pBot->pBotPickupItem);
      else
         v_dest = pBot->pBotPickupItem->v.origin;

      pBot->dest_origin = v_dest;
      pBot->vecEntity = v_dest;

      // find the distance to the item
      float f_item_distance = (v_dest - pEdict->v.origin).Length ();

      switch (pBot->iPickupType)
      {
      case PICKUP_WEAPON:
         pBot->iAimFlags |= AIM_DEST;

         // Near to Weapon ?
         if (f_item_distance < 50)
         {
            if (BotHasShield (pBot))
               FakeClientCommand (pEdict, "drop"); // discard both shield and pistol

            // Get current best weapon to check if it's a primary in need to be dropped
            int iWeaponNum = HighestWeaponOfEdict (pEdict);
            if (iWeaponNum > 6)
            {
               if (pBot->current_weapon.iId != cs_weapon_select[iWeaponNum].iId)
               {
                  if (pBot->current_weapon.iId != CS_WEAPON_INSWITCH)
                     SelectWeaponbyNumber (pBot, iWeaponNum);
               }
               else
                  FakeClientCommand (pEdict, "drop");
            }
            else
               pBot->iNumWeaponPickups++;
         }
         break;

      case PICKUP_SHIELD:
         pBot->iAimFlags |= AIM_DEST;

         // shield code courtesy of Wei Mingzhi
         if (BotHasShield (pBot))
         {
            pBot->pBotPickupItem = NULL;
            break;
         }

         // Near to Weapon ?
         else if (f_item_distance < 50)
         {
            // Get current best weapon to check if it's a primary in need to be dropped
            int iWeaponNum = HighestWeaponOfEdict (pEdict);
            if ((iWeaponNum > 6) || BotHasShield (pBot))
            {
               SelectWeaponbyNumber (pBot, iWeaponNum);
               FakeClientCommand (pEdict, "drop");
            }
         }
         break;

      case PICKUP_HOSTAGE:
         pBot->iAimFlags |= AIM_ENTITY;
         v_src = pEdict->v.origin + pEdict->v.view_ofs;

         if (f_item_distance < 50)
         {
            float angle_to_entity = BotInFieldOfView (pBot, v_dest - v_src);

            // Bot faces hostage ?
            if (angle_to_entity <= 10)
            {
               pEdict->v.button |= IN_USE;

               // Notify Team
               FakeClientCommand (pBot->pEdict, "say_team Using a Hostage!\n");

               // Store ptr to hostage so other Bots don't steal
               // from this one or Bot tries to reuse it
               for (i = 0; i < MAX_HOSTAGES; i++)
               {
                  if (FNullEnt (pBot->pHostages[i]))
                  {
                     pBot->pHostages[i] = pBot->pBotPickupItem;
                     pBot->pBotPickupItem = NULL;
                     break;
                  }
               }
            }
         }
         break;

      case PICKUP_PLANTED_C4:
         pBot->iAimFlags |= AIM_ENTITY;

         // Bomb Defuse needs to be checked
         if ((pBot->bot_team == TEAM_CS_COUNTER) && (f_item_distance < 50))
         {
            bMoveToGoal = FALSE;
            pBot->bCheckTerrain = FALSE;
            pBot->f_move_speed = 0;
            pBot->f_sidemove_speed = 0;
            pEdict->v.button |= IN_DUCK;

            // Notify Team of defusing
            BotPlayRadioMessage (pBot, RADIO_NEEDBACKUP);
            FakeClientCommand (pBot->pEdict, "say_team Trying to defuse the Bomb!\n");

            bottask_t TempTask = {NULL, NULL, TASK_DEFUSEBOMB, TASKPRI_DEFUSEBOMB, -1, 0.0, FALSE};
            BotPushTask (pBot, &TempTask);
         }
         break;

      case PICKUP_DEFUSEKIT:
         pBot->iAimFlags |= AIM_DEST; // don't bother looking at it

         if (pBot->b_has_defuse_kit)
         {
            pBot->pBotPickupItem = NULL;
            pBot->iPickupType = PICKUP_NONE;
         }
         break;
      }
      break;
   }

   // --- End of executing Task Actions ---

   // Get current Waypoint Flags
   // FIXME: Would make more sense to store it each time
   // in the Bot struct when a Bot gets a new wpt instead doing this here
   if (pBot->curr_wpt_index != -1)
      pBot->iWPTFlags = paths[pBot->curr_wpt_index]->flags;
   else
      pBot->iWPTFlags = 0;

   BotChooseAimDirection (pBot);
   BotFacePosition (pBot, pBot->vecLookAt);

   // Get Speed Multiply Factor by dividing Target FPS by real FPS
   float fSpeedFactor = CVAR_GET_FLOAT ("fps_max") / (1.0 / gpGlobals->frametime);
   if (fSpeedFactor < 1)
      fSpeedFactor = 1.0;

   if (pBot->iAimFlags > AIM_ENEMY)
   {
      BotChangeYaw (pBot, pEdict->v.yaw_speed * fSpeedFactor);
      BotChangePitch (pBot, pEdict->v.pitch_speed * fSpeedFactor);
   }
   else
   {
      BotChangeYaw (pBot, pEdict->v.yaw_speed * 0.3 * fSpeedFactor);
      BotChangePitch (pBot, pEdict->v.pitch_speed * 0.3 * fSpeedFactor);
   }

   pEdict->v.angles.x = -pEdict->v.v_angle.x / 3;
   pEdict->v.angles.y = pEdict->v.v_angle.y;
   UTIL_ClampVector (&pEdict->v.angles);
   UTIL_ClampVector (&pEdict->v.v_angle);
   pEdict->v.angles.z = pEdict->v.v_angle.z = 0;

   // Enemy behind Obstacle ? Bot wants to fire ?
   if ((pBot->iStates & STATE_SUSPECTENEMY) && pBot->bWantsToFire)
   {
      int iTask = BotGetSafeTask (pBot)->iTask;

      // Don't allow shooting through walls when camping
      if ((iTask == TASK_PAUSE) || (iTask == TASK_CAMP))
         pBot->bWantsToFire = FALSE;
   }

   // The Bots wants to fire at something ?
   if (pBot->bWantsToFire && !pBot->bUsingGrenade
       && (pBot->f_shoot_time <= gpGlobals->time))
   {
      // If Bot didn't fire a bullet try again next frame
      if (!BotFireWeapon (pBot->vecLookAt - GetGunPosition (pEdict), pBot))
         pBot->f_shoot_time = gpGlobals->time;
   }

   // Set the reaction time (surprise momentum) different each frame
   // according to skill
   pBot->f_ideal_reaction_time = RANDOM_FLOAT (BotSkillDelays[pBot->bot_skill/20].fMinSurpriseDelay,
      BotSkillDelays[pBot->bot_skill/20].fMaxSurpriseDelay);

   // Calculate 2 direction Vectors, 1 without the up/down component
   v_direction = pBot->dest_origin - (pEdict->v.origin + (pEdict->v.velocity * pBot->fTimeFrameInterval));
   Vector vecDirectionNormal = v_direction.Normalize ();
   Vector vecDirection = vecDirectionNormal;
   vecDirectionNormal.z = 0.0;

   Vector vecMoveAngles = UTIL_VecToAngles (v_direction);
   vecMoveAngles.x = -vecMoveAngles.x;
   vecMoveAngles.z = 0;
   UTIL_ClampVector (&vecMoveAngles);

   // Allowed to move to a destination position ?
   if (bMoveToGoal)
   {
      GetValidWaypoint (pBot);

      // Press duck button if we need to
      if ((paths[pBot->curr_wpt_index]->flags & W_FL_CROUCH)
          && !(paths[pBot->curr_wpt_index]->flags & W_FL_CAMP)
          && ((!(pEdict->v.flags & FL_ONGROUND) && !pBot->bInWater)
              || (paths[pBot->curr_wpt_index]->origin.z < pEdict->v.origin.z + 32)))
         pEdict->v.button |= IN_DUCK;

      float fDistance = (pBot->dest_origin - (pEdict->v.origin + (pEdict->v.velocity * pBot->fTimeFrameInterval))).Length2D ();
      if (fDistance < (pBot->f_move_speed * pBot->fTimeFrameInterval))
         pBot->f_move_speed = fDistance;

      if (pBot->f_move_speed < 2.0)
         pBot->f_move_speed = 2.0;

      pBot->fTimeWaypointMove = gpGlobals->time;

      // Special Movement for swimming here
      if (pBot->bInWater)
      {
         // Check if we need to go forward or back

         // Press the correct buttons
         if (BotInFieldOfView (pBot, pBot->dest_origin - GetGunPosition (pEdict)) > 90)
            pEdict->v.button |= IN_BACK;
         else
            pEdict->v.button |= IN_FORWARD;

         if (vecMoveAngles.x > 60.0)
            pEdict->v.button |= IN_DUCK;
         else if (vecMoveAngles.x < -60.0)
            pEdict->v.button |= IN_JUMP;
      }
   }

   // Are we allowed to check blocking Terrain (and react to it) ?
   if (pBot->bCheckTerrain)
   {
      edict_t *pent;
      bool bBackOffPlayer = FALSE;
      bool bBotIsStuck = FALSE;

      Vector v_angles = UTIL_VecToAngles (v_direction);

      // Test if there's a shootable breakable in our way
      v_src = pEdict->v.origin + pEdict->v.view_ofs; // EyePosition ()
      v_dest = v_src + vecDirection * 50;
      TRACE_HULL (v_src, v_dest, dont_ignore_monsters, head_hull, pEdict, &tr);

      if (tr.flFraction != 1.0)
      {
         if (strcmp ("func_breakable", STRING (tr.pHit->v.classname)) == 0)
         {
            pent = tr.pHit;
            if (IsShootableBreakable (pent))
            {
               pBot->pShootBreakable = pent;
               pBot->iCampButtons = pEdict->v.button & IN_DUCK;
               bottask_t TempTask = {NULL, NULL, TASK_SHOOTBREAKABLE, TASKPRI_SHOOTBREAKABLE, -1, 0.0, FALSE};
               BotPushTask (pBot, &TempTask);
            }
         }
      }
      else
      {
         v_src = pEdict->v.origin;
         v_dest = v_src + vecDirection * 50;
         TRACE_HULL (v_src, v_dest, dont_ignore_monsters, head_hull, pEdict, &tr);

         if (tr.flFraction != 1.0)
         {
            if (strcmp ("func_breakable", STRING (tr.pHit->v.classname)) == 0)
            {
               pent = tr.pHit;

               // Check if this isn't a triggered (bomb) breakable and
               // if it takes damage. If true, shoot the crap!
               if (IsShootableBreakable (pent))
               {
                  pBot->pShootBreakable = pent;
                  pBot->iCampButtons = pEdict->v.button & IN_DUCK;
                  bottask_t TempTask = {NULL, NULL, TASK_SHOOTBREAKABLE, TASKPRI_SHOOTBREAKABLE, -1, 0.0, FALSE};
                  BotPushTask (pBot, &TempTask);
               }
            }
         }
      }

      // No Breakable blocking ?
      if (FNullEnt (pBot->pShootBreakable))
      {
         // Standing still, no need to check ?
         // FIXME: Doesn't care for ladder movement (handled separately)
         // should be included in some way
         if ((pBot->f_move_speed != 0) || (pBot->f_sidemove_speed != 0))
         {
            pent = NULL;
            edict_t *pNearestPlayer = NULL;
            float f_nearestdistance = 256.0;
            float f_distance_now;

            // Find nearest player to Bot
            while (!FNullEnt (pent = FIND_ENTITY_IN_SPHERE (pent, pEdict->v.origin, pEdict->v.maxspeed)))
            {
               // Spectator or not drawn ?
               if (pent->v.effects & EF_NODRAW)
                  continue;

               // Player Entity ?
               if (pent->v.flags & FL_CLIENT)
               {
                  // Our Team, alive, moving and not myself ?
                  if ((UTIL_GetTeam (pent) != pBot->bot_team)
                      || !IsAlive (pent) || (pent == pEdict))
                     continue;

                  f_distance_now = (pent->v.origin - pEdict->v.origin).Length ();
                  if (f_distance_now < f_nearestdistance)
                  {
                     pNearestPlayer = pent;
                     f_nearestdistance = f_distance_now;
                  }
               }
            }

            // Found somebody ?
            if (!FNullEnt (pNearestPlayer) && FInViewCone (&pNearestPlayer->v.origin, pEdict))
            {
               // bot found a visible teammate
               float teammate_angle = pNearestPlayer->v.velocity.y - pEdict->v.velocity.y;
               float teammate_viewangle = pNearestPlayer->v.v_angle.y - pEdict->v.v_angle.y;
               UTIL_ClampAngle (&teammate_angle);
               UTIL_ClampAngle (&teammate_viewangle);

               // is that teammate near us OR coming in front of us and within a certain distance ?
               if ((f_nearestdistance < 100)
                   || ((f_nearestdistance < 300)
                       && (fabs (teammate_angle) > 160)
                       && (fabs (teammate_viewangle) > 165)))
               {
                  // if we are moving full speed AND there's room forward OR teammate is very close...
                  if ((f_nearestdistance < 70)
                      || ((tr.flFraction == 1.0) && (pEdict->v.velocity.Length2D () > 50)))
                  {
                     bBackOffPlayer = TRUE;

                     // is the player coming on the left ?
                     if (teammate_angle > 0)
                        pBot->f_sidemove_speed = pEdict->v.maxspeed;

                     // else is the player coming on the right ?
                     else if (teammate_angle < 0)
                        pBot->f_sidemove_speed = -pEdict->v.maxspeed;

                     if (f_nearestdistance <= 56.0)
                        pBot->f_move_speed = -pEdict->v.maxspeed;

                     BotResetCollideState (pBot);

                     if (moved_distance < 2.0)
                        pEdict->v.button |= IN_DUCK;
                  }
               }
            }
         }

         // No Player collision ?
         if (!bBackOffPlayer && (pBot->fNoCollTime < gpGlobals->time)
             && (BotGetSafeTask (pBot)->iTask != TASK_ATTACK))
         {
            // Didn't we move enough previously ?
            if ((moved_distance < 2.0) && (pBot->prev_speed >= 1.0))
            {
               // Then consider being stuck
               pBot->prev_time = gpGlobals->time;
               bBotIsStuck = TRUE;
               if (pBot->f_firstcollide_time == 0.0)
                  pBot->f_firstcollide_time = gpGlobals->time + 0.2;
            }

            // Not stuck yet
            else
            {
               // Test if there's something ahead blocking the way
               if (BotCantMoveForward (pBot, vecDirectionNormal, &tr) && !pBot->bOnLadder)
               {
                  if (pBot->f_firstcollide_time == 0.0)
                     pBot->f_firstcollide_time = gpGlobals->time + 0.2;
                  else if (pBot->f_firstcollide_time <= gpGlobals->time)
                     bBotIsStuck = TRUE;
               }
               else
                  pBot->f_firstcollide_time = 0.0;
            }

            // Not stuck ?
            if (!bBotIsStuck)
            {
               if (pBot->f_probe_time + 0.5 < gpGlobals->time)
               {
                  // Reset Collision Memory if not being stuck for 0.5 secs
                  BotResetCollideState(pBot);
               }
               else
               {
                  // Remember to keep pressing duck if it was necessary ago
                  if (pBot->cCollideMoves[pBot->cCollStateIndex] == COLLISION_DUCK)
                     pEdict->v.button |= IN_DUCK;
               }
            }

            // Bot is stuck !!
            else
            {
               // Not yet decided what to do ?
               if (pBot->cCollisionState == COLLISION_NOTDECIDED)
               {
                  char cBits = 0;

                  if (pBot->bInWater)
                  {
                     cBits |= PROBE_JUMP;
                     cBits |= PROBE_STRAFE;
                  }
                  else
                  {
                     cBits |= PROBE_JUMP;
                     cBits |= PROBE_DUCK;
                     cBits |= PROBE_STRAFE;
                  }

                  // Collision check allowed if not flying through the air
                  if (pEdict->v.flags & FL_ONGROUND)
                  {
                     char cState[8];
                     i = 0;

                     // First 4 Entries hold the possible
                     // Collision States
                     cState[i] = COLLISION_JUMP;
                     i++;
                     cState[i] = COLLISION_DUCK;
                     i++;
                     cState[i] = COLLISION_STRAFELEFT;
                     i++;
                     cState[i] = COLLISION_STRAFERIGHT;
                     i++;

                     // Now weight all possible States
                     if (cBits & PROBE_JUMP)
                     {
                        cState[i] = 0;

                        if (BotCanJumpUp (pBot, vecDirectionNormal))
                           cState[i] += 10;
                        if (pBot->dest_origin.z >= pEdict->v.origin.z + 18.0)
                           cState[i] += 5;

                        if (BotEntityIsVisible (pBot, pBot->dest_origin))
                        {
                           MAKE_VECTORS (vecMoveAngles);
                           v_src = pEdict->v.origin + pEdict->v.view_ofs;
                           v_src = v_src + gpGlobals->v_right * 15;
                           UTIL_TraceLine (v_src, pBot->dest_origin, ignore_monsters, ignore_glass, pEdict, &tr);

                           if (tr.flFraction >= 1.0)
                           {
                              v_src = pEdict->v.origin + pEdict->v.view_ofs;
                              v_src = v_src + (-gpGlobals->v_right * 15);
                              UTIL_TraceLine (v_src, pBot->dest_origin, ignore_monsters, ignore_glass, pEdict, &tr);

                              if (tr.flFraction >= 1.0)
                                 cState[i] += 5;
                           }
                        }

                        if (pEdict->v.flags & FL_DUCKING)
                           v_src = pEdict->v.origin;
                        else
                           v_src = pEdict->v.origin + Vector (0, 0, -17);
                        v_dest = v_src + vecDirectionNormal * 30;
                        UTIL_TraceLine (v_src, v_dest, ignore_monsters, ignore_glass, pEdict, &tr);

                        if (tr.flFraction != 1.0)
                           cState[i] += 10;
                     }
                     else
                        cState[i] = 0;

                     i++;

                     if (cBits & PROBE_DUCK)
                     {
                        cState[i] = 0;

                        if (BotCanDuckUnder (pBot, vecDirectionNormal))
                           cState[i] += 10;

                        if ((pBot->dest_origin.z + 36.0 <= pEdict->v.origin.z)
                            && BotEntityIsVisible (pBot, pBot->dest_origin))
                           cState[i] += 5;
                     }
                     else
                        cState[i] = 0;

                     i++;

                     if (cBits & PROBE_STRAFE)
                     {
                        cState[i] = 0;
                        cState[i + 1] = 0;
                        Vector2D vec2DirToPoint;
                        Vector2D vec2RightSide;

                        // to start strafing, we have to first figure out if the target is on the left side or right side
                        MAKE_VECTORS (vecMoveAngles);

                        vec2DirToPoint =  (pEdict->v.origin - pBot->dest_origin).Make2D ().Normalize ();
                        vec2RightSide = gpGlobals->v_right.Make2D ().Normalize ();
                        bool bDirRight = FALSE;
                        bool bDirLeft = FALSE;
                        bool bBlockedLeft = FALSE;
                        bool bBlockedRight = FALSE;

                        if (pBot->f_move_speed > 0)
                           vecDirection = gpGlobals->v_forward;
                        else
                           vecDirection = -gpGlobals->v_forward;

                        if (DotProduct  (vec2DirToPoint, vec2RightSide) > 0)
                           bDirRight = TRUE;
                        else
                           bDirLeft = TRUE;

                        // Now check which side is blocked
                        v_src = pEdict->v.origin + gpGlobals->v_right * 32;
                        v_dest = v_src + vecDirection * 32;
                        TRACE_LINE (v_src, v_dest, ignore_monsters, pEdict, &tr);

                        if (tr.flFraction != 1.0)
                           bBlockedRight = TRUE;

                        v_src = pEdict->v.origin + -gpGlobals->v_right * 32;
                        v_dest = v_src + vecDirection * 32;
                        TRACE_LINE (v_src, v_dest, ignore_monsters, pEdict, &tr);

                        if (tr.flFraction != 1.0)
                           bBlockedLeft = TRUE;

                        if (bDirLeft)
                           cState[i] += 5;
                        else
                           cState[i] -= 5;

                        if (bBlockedLeft)
                           cState[i] -= 5;

                        i++;

                        if (bDirRight)
                           cState[i] += 5;
                        else
                           cState[i] -= 5;

                        if (bBlockedRight)
                           cState[i] -= 5;
                     }
                     else
                     {
                        cState[i] = 0;
                        i++;
                        cState[i] = 0;
                     }

                     // Weighted all possible Moves, now sort them to start with most probable
                     char cTemp;
                     bool bSorting;
                     do
                     {
                        bSorting = FALSE;
                        for (i = 0; i < 3; i++)
                        {
                           if (cState[i + 4] < cState[i + 1 + 4])
                           {
                              cTemp = cState[i];
                              cState[i] = cState[i + 1];
                              cState[i + 1] = cTemp;
                              cTemp = cState[i + 4];
                              cState[i + 4] = cState[i + 1 + 4];
                              cState[i + 1 + 4] = cTemp;
                              bSorting = TRUE;
                           }
                        }
                     } while (bSorting);

                     for (i = 0; i < 4; i++)
                        pBot->cCollideMoves[i] = cState[i];

                     pBot->f_probe_time = gpGlobals->time + 0.5;
                     pBot->cCollisionProbeBits = cBits;
                     pBot->cCollisionState = COLLISION_PROBING;
                     pBot->cCollStateIndex = 0;
                  }
               }

               if (pBot->cCollisionState == COLLISION_PROBING)
               {
                  if (pBot->f_probe_time < gpGlobals->time)
                  {
                     pBot->cCollStateIndex++;
                     pBot->f_probe_time = gpGlobals->time + 0.5;

                     if (pBot->cCollStateIndex > 4)
                     {
                        pBot->f_wpt_timeset = gpGlobals->time - 5.0;
                        BotResetCollideState (pBot);
                     }
                  }
                  if (pBot->cCollStateIndex <= 4)
                  {
                     switch (pBot->cCollideMoves[pBot->cCollStateIndex])
                     {
                     case COLLISION_JUMP:
                        if ((pEdict->v.flags & FL_ONGROUND)
                            || pBot->bInWater || !pBot->bOnLadder)
                           pEdict->v.button |= IN_JUMP;
                        break;

                     case COLLISION_DUCK:
                        pEdict->v.button |= IN_DUCK;
                        break;

                     case COLLISION_STRAFELEFT:
                        BotSetStrafeSpeed (pBot, vecDirectionNormal, -pEdict->v.maxspeed);
                        break;

                     case COLLISION_STRAFERIGHT:
                        BotSetStrafeSpeed (pBot, vecDirectionNormal, pEdict->v.maxspeed);
                        break;
                     }
                  }
               }
            }
         }
      }
   }

   // Must avoid a Grenade ?
   if (pBot->cAvoidGrenade != 0)
   {
      // Don't duck to get away faster
      pEdict->v.button &= ~IN_DUCK;
      pBot->f_move_speed = -pEdict->v.maxspeed;
      pBot->f_sidemove_speed = pEdict->v.maxspeed * pBot->cAvoidGrenade;
   }

   // FIXME: time to reach waypoint should be calculated when getting this waypoint
   // depending on maxspeed and movetype instead of being hardcoded
   if ((pBot->f_wpt_timeset + 5.0 < gpGlobals->time) && FNullEnt (pBot->pBotEnemy))
   {
      GetValidWaypoint (pBot);

      // Clear these pointers, Bot might be stuck getting to them
      if (!FNullEnt (pBot->pBotPickupItem))
         pBot->pItemIgnore = pBot->pBotPickupItem;

      pBot->pBotPickupItem = NULL;
      pBot->iPickupType = PICKUP_NONE;
      pBot->f_itemcheck_time = gpGlobals->time + 5.0;
      pBot->pShootBreakable = NULL;
   }

   if (pEdict->v.button & IN_JUMP)
      pBot->f_jumptime = gpGlobals->time;

   if (pBot->f_jumptime + 1.0 > gpGlobals->time)
   {
      if (!(pEdict->v.flags & FL_ONGROUND) && !pBot->bInWater)
         pEdict->v.button |= IN_DUCK;
   }

   if (!(pEdict->v.button & (IN_FORWARD | IN_BACK)))
   {
      if (pBot->f_move_speed > 0)
         pEdict->v.button |= IN_FORWARD;
      else if (pBot->f_move_speed < 0)
         pEdict->v.button |= IN_BACK;
   }

   if (!(pEdict->v.button & (IN_MOVELEFT | IN_MOVERIGHT)))
   {
      if (pBot->f_sidemove_speed > 0)
         pEdict->v.button |= IN_MOVERIGHT;
      else if (pBot->f_sidemove_speed < 0)
         pEdict->v.button |= IN_MOVELEFT;
   }

   // save the previous speed (for checking if stuck)
   pBot->prev_speed = fabs (pBot->f_move_speed);

   // Reset Damage
   pBot->iLastDamageType = -1;

   UTIL_ClampVector (&pEdict->v.angles);
   UTIL_ClampVector (&pEdict->v.v_angle);
   UTIL_ClampAngle (&pEdict->v.idealpitch);
   UTIL_ClampAngle (&pEdict->v.ideal_yaw);

   assert ((pEdict->v.v_angle.x > -181.0) && (pEdict->v.v_angle.x < 181.0)
           && (pEdict->v.v_angle.y > -181.0) && (pEdict->v.v_angle.y < 181.0)
           && (pEdict->v.angles.x > -181.0) && (pEdict->v.angles.x < 181.0)
           && (pEdict->v.angles.y > -181.0) && (pEdict->v.angles.y < 181.0));

   g_engfuncs.pfnRunPlayerMove (pEdict, vecMoveAngles, pBot->f_move_speed, pBot->f_sidemove_speed, 0, pEdict->v.button, 0, msecval);
   return;
}


bool BotHasHostage (bot_t *pBot)
{
   int i;

   for (i = 0; i < MAX_HOSTAGES; i++)
      if (!FNullEnt (pBot->pHostages[i]))
         return (TRUE);

   return (FALSE);
}


void BotResetCollideState (bot_t *pBot)
{
   pBot->f_probe_time = 0.0;
   pBot->cCollisionProbeBits = 0;
   pBot->cCollisionState = COLLISION_NOTDECIDED;
   pBot->cCollStateIndex = 0;
}


bool IsDeadlyDrop (bot_t *pBot, Vector vecTargetPos)
{
   // Returns if given location would hurt Bot with falling damage

   edict_t *pEdict = pBot->pEdict;
   Vector vecBot = pEdict->v.origin;
   TraceResult tr;
   float height, last_height, distance;

   Vector vecMove = UTIL_VecToAngles (vecTargetPos - vecBot);
   vecMove.x = 0; // reset pitch to 0 (level horizontally)
   vecMove.z = 0; // reset roll to 0 (straight up and down)
   MAKE_VECTORS (vecMove);

   Vector v_direction = (vecTargetPos - vecBot).Normalize (); // 1 unit long
   Vector v_check = vecBot;
   Vector v_down = vecBot;

   v_down.z = v_down.z - 1000.0; // straight down 1000 units

   TRACE_LINE (v_check, v_down, ignore_monsters, pEdict, &tr);

   // We're not on ground anymore ?
   if (tr.flFraction > 0.036)
      tr.flFraction = 0.036;

   last_height = tr.flFraction * 1000.0; // height from ground
   distance = (vecTargetPos - v_check).Length (); // distance from goal

   while (distance > 16.0)
   {
      // move 10 units closer to the goal...
      v_check = v_check + (v_direction * 16.0);

      v_down = v_check;
      v_down.z = v_down.z - 1000.0; // straight down 1000 units

      TRACE_LINE (v_check, v_down, ignore_monsters, pEdict, &tr);

      // Wall blocking ?
      if (tr.fStartSolid)
         return (FALSE);

      height = tr.flFraction * 1000.0; // height from ground

      // Drops more than 100 Units ?
      if (last_height < height - 100)
         return (TRUE);

      last_height = height;

      distance = (vecTargetPos - v_check).Length (); // distance from goal
   }

   return (FALSE);
}


void BotFreeAllMemory (void)
{
   STRINGNODE *pNextNode;
   replynode_t *pNextReply;
   PATH *pNextPath;
   int i;

   for (i = 0; i < 32; i++)
   {
      DeleteSearchNodes (&bots[i]); // Delete Nodes from Pathfinding
      BotResetTasks (&bots[i]);
   }

   // Delete all Waypoint Data

   while (paths[0] != NULL)
   {
      pNextPath = paths[0]->next;
      delete (paths[0]);
      paths[0] = pNextPath;
   }
   paths[0] = NULL;

   memset (paths, 0, sizeof (paths));
   g_iNumWaypoints = 0;
   g_vecLastWaypoint = g_vecZero;
   g_fWPDisplayTime = 0.0;

   if (pBotExperienceData != NULL)
      delete [](pBotExperienceData);
   pBotExperienceData = NULL;

   if (g_pFloydDistanceMatrix != NULL)
      delete [](g_pFloydDistanceMatrix);
   g_pFloydDistanceMatrix = NULL;

   if (g_pFloydPathMatrix != NULL)
      delete [](g_pFloydPathMatrix);
   g_pFloydPathMatrix = NULL;

   if (g_pWithHostageDistMatrix != NULL)
      delete [](g_pWithHostageDistMatrix);
   g_pWithHostageDistMatrix = NULL;

   if (g_pWithHostagePathMatrix != NULL)
      delete [](g_pWithHostagePathMatrix);
   g_pWithHostagePathMatrix = NULL;

   // Delete all Textnodes/strings

   while (pChatReplies != NULL)
   {
      while (pChatReplies->pReplies != NULL)
      {
         pNextNode = pChatReplies->pReplies->Next;
         delete (pChatReplies->pReplies);
         pChatReplies->pReplies = pNextNode;
      }
      pChatReplies->pReplies = NULL;

      pNextReply = pChatReplies->pNextReplyNode;
      delete (pChatReplies);
      pChatReplies = pNextReply;
   }
   pChatReplies = NULL;

   return; // KABLAM! everything is nuked, wiped, cleaned, memory stick is shining like a coin =)
}


STRINGNODE *GetNodeSTRING (STRINGNODE *pNode, int NodeNum)
{
   STRINGNODE *pTempNode = pNode;
   int i = 0;

   while (i < NodeNum)
   {
      pTempNode = pTempNode->Next;
      assert (pTempNode!= NULL);

      if (pTempNode == NULL)
         break;
      i++;
   }

   return (pTempNode);
}
