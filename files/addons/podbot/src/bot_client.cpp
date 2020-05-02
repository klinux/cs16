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
// bot_client.cpp
//
// Handles Messages sent from the Server to a Client Bot

#include "bot_globals.h"


void BotClient_CS_VGUI (void *p, int bot_index)
{
   // This message is sent when the VGUI menu is displayed.

   if (state == 0)
   {
      if ((*(int *) p) == 2)  // is it a team select menu?
         bots[bot_index].start_action = MSG_CS_TEAM_SELECT;
      else if ((*(int *) p) == 26)  // is it a Terrorist class selection menu?
         bots[bot_index].start_action = MSG_CS_T_SELECT;
      else if ((*(int *) p) == 27)  // is it a CT class selection menu?
         bots[bot_index].start_action = MSG_CS_CT_SELECT;
   }
}


void BotClient_CS_ShowMenu (void *p, int bot_index)
{
   // This message is sent when a menu is being displayed.

   if (state < 3)
      return; // ignore first 3 fields of message

   // Team Selection Messages
   if (strcmp ((char *) p, "#Team_Select") == 0)  // team select menu?
      bots[bot_index].start_action = MSG_CS_TEAM_SELECT;
   else if (strcmp ((char *) p, "#CT_Select") == 0)  // CT model select menu?
      bots[bot_index].start_action = MSG_CS_CT_SELECT;
   else if (strcmp ((char *) p, "#Terrorist_Select") == 0)  // T model select?
      bots[bot_index].start_action = MSG_CS_T_SELECT;
}


void BotClient_CS_StatusIcon (void *p, int bot_index)
{
   // this message tells a game client to display (or stop displaying) a certain status icon on
   // his player's HUD.

   static int icon_state = 0;

   if (state == 0)
      icon_state = *(int *) p;

   else if (state == 1)
   {
      // is it the C4 icon ?
      if (strcmp ("c4", (char *) p) == 0)
      {
         // is icon blinking ?
         if (icon_state == 2)
            bots[bot_index].b_bomb_blinking = TRUE; // bomb icon is blinking
         else
            bots[bot_index].b_bomb_blinking = FALSE;
      }

      // else is it the defuser icon ?
      else if (strcmp ("defuser", (char *) p) == 0)
      {
         // is icon lit ?
         if (icon_state > 0)
            bots[bot_index].b_has_defuse_kit = TRUE; // Bot has Defuse Kit
         else
            bots[bot_index].b_has_defuse_kit = FALSE;
      }

      // else is it the buy zone icon ?
      else if (strcmp ("buyzone", (char *) p) == 0)
      {
         // is icon lit ?
         if (icon_state > 0)
            bots[bot_index].b_can_buy = TRUE; // bot can buy
         else
            bots[bot_index].b_can_buy = FALSE;
      }
   }
}


void BotClient_CS_WeaponList (void *p, int bot_index)
{
   // This message is sent when a client joins the game.  All of the weapons
   // are sent with the weapon ID and information about what ammo is used.

   static bot_weapon_t bot_weapon;

   if (state == 0)
      strcpy (bot_weapon.szClassname, (char *) p);
   else if (state == 1)
      bot_weapon.iAmmo1 = *(int *) p;  // ammo index 1
   else if (state == 2)
      bot_weapon.iAmmo1Max = *(int *) p;  // max ammo1
   else if (state == 3)
      bot_weapon.iAmmo2 = *(int *) p;  // ammo index 2
   else if (state == 4)
      bot_weapon.iAmmo2Max = *(int *) p;  // max ammo2
   else if (state == 5)
      bot_weapon.iSlot = *(int *) p;  // slot for this weapon
   else if (state == 6)
      bot_weapon.iPosition = *(int *) p;  // position in slot
   else if (state == 7)
      bot_weapon.iId = *(int *) p;  // weapon ID
   else if (state == 8)
   {
      bot_weapon.iFlags = *(int *) p;  // flags for weapon (WTF???)

      // store away this weapon with it's ammo information...
      weapon_defs[bot_weapon.iId] = bot_weapon;
   }
}


void BotClient_CS_CurrentWeapon (void *p, int bot_index)
{
   // This message is sent when a weapon is selected (either by the bot chosing
   // a weapon or by the server auto assigning the bot a weapon).
   // In CS it's also called when Ammo is increased/decreased

   static int iState;
   static int iId;
   static int iClip;

   bot_t *pBot = &bots[bot_index];

   if (state == 0)
      iState = *(int *) p;  // state of the current weapon (WTF???)
   else if (state == 1)
      iId = *(int *) p;  // weapon ID of current weapon
   else if (state == 2)
   {
      iClip = *(int *) p;  // ammo currently in the clip for this weapon

      if ((iId <= 31) && (iState == 1))
      {
         // Ammo amount decreased ? Must have fired a bullet...
         if ((iId == pBot->current_weapon.iId) && (pBot->current_weapon.iClip > iClip))
         {
            // Time fired withing burst firing time ?
            if (pBot->fTimeLastFired + 1.0 > gpGlobals->time)
               pBot->iBurstShotsFired++;

            pBot->fTimeLastFired = gpGlobals->time; // Remember the last bullet time
         }
         pBot->current_weapon.iId = iId;
         pBot->current_weapon.iClip = iClip;

         // update the ammo counts for this weapon...
         pBot->current_weapon.iAmmo1 = pBot->m_rgAmmo[weapon_defs[iId].iAmmo1];
         pBot->current_weapon.iAmmo2 = pBot->m_rgAmmo[weapon_defs[iId].iAmmo2];
      }
   }
}


void BotClient_CS_AmmoX (void *p, int bot_index)
{
   // This message is sent whenever ammo ammounts are adjusted (up or down).
   // NOTE: Logging reveals that CS uses it very unreliable !

   static int index;
   int ammo_index;

   bot_t *pBot = &bots[bot_index];

   if (state == 0)
      index = *(int *) p; // ammo index (for type of ammo)
   else if (state == 1)
   {
      pBot->m_rgAmmo[index] = *(int *) p; // store it away

      if (pBot->current_weapon.iId > CS_WEAPON_INSWITCH)
      {
         ammo_index = pBot->current_weapon.iId;

         // update the ammo counts for this weapon...
         pBot->current_weapon.iAmmo1 = pBot->m_rgAmmo[weapon_defs[ammo_index].iAmmo1];
         pBot->current_weapon.iAmmo2 = pBot->m_rgAmmo[weapon_defs[ammo_index].iAmmo2];
      }
   }
}


void BotClient_CS_AmmoPickup (void *p, int bot_index)
{
   // This message is sent when the bot picks up some ammo (AmmoX messages are
   // also sent so this message is probably not really necessary except it
   // allows the HUD to draw pictures of ammo that have been picked up.  The
   // bots don't really need pictures since they don't have any eyes anyway.

   static int index;
   int ammo_index;

   if (state == 0)
      index = *(int *) p;
   else if (state == 1)
   {
      bots[bot_index].m_rgAmmo[index] = *(int *) p;
      ammo_index = bots[bot_index].current_weapon.iId;

      // update the ammo counts for this weapon (ONLY if bot knows its current weapon)...
      if ((ammo_index >= 0) && (ammo_index < MAX_WEAPONS))
      {
         bots[bot_index].current_weapon.iAmmo1 = bots[bot_index].m_rgAmmo[weapon_defs[ammo_index].iAmmo1];
         bots[bot_index].current_weapon.iAmmo2 = bots[bot_index].m_rgAmmo[weapon_defs[ammo_index].iAmmo2];
      }
   }
}


void BotClient_CS_Damage (void *p, int bot_index)
{
   // This message gets sent when the bots are getting damaged.

   static int damage_armor;
   static int damage_taken;
   static int damage_bits;
   static Vector damage_origin;

   if (state == 0)
      damage_armor = *(int *) p;
   else if (state == 1)
      damage_taken = *(int *) p;
   else if (state == 2)
      damage_bits = *(int *) p;
   else if (state == 3)
      damage_origin.x = *(float *) p;
   else if (state == 4)
      damage_origin.y = *(float *) p;
   else if (state == 5)
   {
      damage_origin.z = *(float *) p;

      if ((damage_armor > 0) || (damage_taken > 0))
      {
         bot_t *pBot = &bots[bot_index];
         pBot->iLastDamageType = damage_bits;
         edict_t *pEdict = pBot->pEdict;

         BotCollectGoalExperience (pBot, damage_taken);

         edict_t *pEnt = pEdict->v.dmg_inflictor;

         if (pEnt->v.flags & FL_CLIENT)
         {
            if (UTIL_GetTeam (pEnt) == pBot->bot_team)
            {
               // FIXFIXFIXFIXFIXME: THIS IS BLATANTLY CHEATING!!!!
               if (RANDOM_LONG (1, 100) < 10)
               {
                  if (FNullEnt (pBot->pBotEnemy) && (pBot->f_bot_see_enemy_time + 2.0 < gpGlobals->time))
                  {
                     pBot->f_bot_see_enemy_time = gpGlobals->time;
                     pBot->pBotEnemy = pEnt;
                     pBot->pLastEnemy = pEnt;
                     pBot->vecLastEnemyOrigin = pEnt->v.origin;
                  }
               }
            }
            else
            {
               if (pBot->pEdict->v.health > 70)
               {
                  pBot->fAgressionLevel += 0.1;
                  if (pBot->fAgressionLevel > 1.0)
                     pBot->fAgressionLevel = 1.0;
               }
               else
               {
                  pBot->fFearLevel += 0.05;
                  if (pBot->fFearLevel > 1.0)
                     pBot->fFearLevel = 1.0;
               }

               // Stop Bot from Hiding
               BotRemoveCertainTask (pBot, TASK_HIDE);

               // FIXFIXFIXFIXFIXME: THIS IS BLATANTLY CHEATING!!!!
               if (FNullEnt (pBot->pBotEnemy))
               {
                  pBot->pLastEnemy = pEnt;
                  pBot->vecLastEnemyOrigin = pEnt->v.origin;

                  // FIXME - Bot doesn't necessary sees this enemy
                  pBot->f_bot_see_enemy_time = gpGlobals->time;
               }

               BotCollectExperienceData (pEdict, pEnt, damage_armor + damage_taken);
            }
         }

         // Check old waypoint
         else
         {
            if (!WaypointReachable (pEdict->v.origin, pBot->dest_origin, pBot->pEdict))
            {
               DeleteSearchNodes (pBot);
               BotFindWaypoint (pBot);
            }
         }
      }
   }
}


void BotClient_CS_Money (void *p, int bot_index)
{
   // This message gets sent when the bots money ammount changes

   if (state == 0)
      bots[bot_index].bot_money = *(int *) p;  // amount of money
}


void BotClient_CS_DeathMsg (void *p, int bot_index)
{
   // This message gets sent when someone got killed

   static int killer_index;
   static int victim_index;
   static edict_t *killer_edict;
   static bot_t *pBot;

   if (state == 0)
      killer_index = *(int *) p; // ENTINDEX() of killer
   else if (state == 1)
      victim_index = *(int *) p; // ENTINDEX() of victim
   else if (state == 2)
   {
      if ((killer_index != 0) && (killer_index != victim_index))
      {
         killer_edict = INDEXENT (killer_index);
         pBot = UTIL_GetBotPointer (killer_edict);

         // is this message about a bot who killed somebody ?
         if (pBot != NULL)
         {
            pBot->pLastVictim = INDEXENT (victim_index);
            pBot->f_shootatdead_time = gpGlobals->time + RANDOM_FLOAT (0.0, 2.0);
         }

         else // Did a human kill a Bot on his team ?
         {
            edict_t *victim_edict = INDEXENT (victim_index);
            pBot = UTIL_GetBotPointer (victim_edict);

            if (pBot != NULL)
               pBot->bDead = TRUE;
         }
      }
   }
}


void BotClient_CS_ScreenFade (void *p, int bot_index)
{
   // This message gets sent when the Screen fades (Flashbang)

   static unsigned char r;
   static unsigned char g;
   static unsigned char b;

   if (state == 3)
      r = *(unsigned char *) p;
   else if (state == 4)
      g = *(unsigned char *) p;
   else if (state == 5)
      b = *(unsigned char *) p;
   else if (state == 6)
   {
      unsigned char alpha = *(unsigned char *) p;

      if ((r == 255) && (g == 255) && (b == 255) && (alpha > 200))
      {
         bot_t *pBot = &bots[bot_index];
         pBot->pBotEnemy = NULL;
         pBot->f_view_distance = 1;

         // About 3 seconds
         pBot->f_blind_time = gpGlobals->time + ((float) alpha - 200.0) / 15;

         if (pBot->bot_skill < 50)
         {
            pBot->f_blindmovespeed_forward = 0.0;
            pBot->f_blindmovespeed_side = 0.0;
         }
         else if (pBot->bot_skill < 80)
         {
            pBot->f_blindmovespeed_forward = -pBot->pEdict->v.maxspeed;
            pBot->f_blindmovespeed_side = 0.0;
         }
         else
         {
            if (RANDOM_LONG (1, 100) < 50)
            {
               if (RANDOM_LONG (1, 100) < 50)
                  pBot->f_blindmovespeed_side = pBot->pEdict->v.maxspeed;
               else
                  pBot->f_blindmovespeed_side = -pBot->pEdict->v.maxspeed;
            }
            else
            {
               if (pBot->pEdict->v.health > 80)
                  pBot->f_blindmovespeed_forward = pBot->pEdict->v.maxspeed;
               else
                  pBot->f_blindmovespeed_forward = -pBot->pEdict->v.maxspeed;
            }
         }
      }
   }
}


void BotClient_CS_SayText (void *p, int bot_index)
{
   static unsigned char ucEntIndex;

   if (state == 0)
      ucEntIndex = *(unsigned char *) p;
   else if (state == 1)
   {
      bot_t *pBot = &bots[bot_index];

      if (ENTINDEX (pBot->pEdict) != ucEntIndex)
      {
         pBot->SaytextBuffer.iEntityIndex = (int) ucEntIndex;
         strcpy (pBot->SaytextBuffer.szSayText, (char *) p);
         pBot->SaytextBuffer.fTimeNextChat = gpGlobals->time + pBot->SaytextBuffer.fChatDelay;
      }
   }
}


void BotClient_CS_HLTV (void *p, int bot_index)
{
   // This message gets sent when the round restarts in CS 1.6, among other things.
   // Courtesy of stefanhendriks...

   static int players;

   if (state == 0)
      players = *(int *) p;
   else if (state == 1)
   {
      // new round in CS 1.6
      if ((players == 0) && (*(int *) p == 0))
         UTIL_RoundStart ();
   }
}


void BotClient_CS_BombDrop (void *p, int bot_index)
{
   edict_t *pent = NULL;
   bot_t *pBot = &bots[bot_index];

   // is the bot receiving this message alive and T ?
   if (pBot->is_used && !pBot->bDead && (pBot->bot_team == TEAM_CS_TERRORIST))
   {
      BotRemoveCertainTask (pBot, TASK_CAMP);
      DeleteSearchNodes (pBot); // make all Ts reevaluate their paths immediately

      // find the bomb
      while (!FNullEnt (pent = FIND_ENTITY_BY_STRING (pent, "classname", "weaponbox")))
      {
         if (strcmp (STRING (pent->v.model), "models/w_backpack.mdl") == 0)
         {
            pBot->vecPosition = pent->v.origin;

            // Push move task on to stack
            bottask_t TempTask = {NULL, NULL, TASK_MOVETOPOSITION, TASKPRI_MOVETOPOSITION, -1, 0.0, TRUE};
            BotPushTask (pBot, &TempTask);
            break;
         }
      }
   }

   return;
}


void BotClient_CS_BombPickup (void *p, int bot_index)
{
   bot_t *pBot = &bots[bot_index];

   if (pBot->is_used && !pBot->bDead && (pBot->bot_team == TEAM_CS_COUNTER))
   {
      DeleteSearchNodes (pBot); // make all Ts reevaluate their paths immediately
      BotResetTasks (pBot); // barbarian, but fits the job perfectly.
   }

   return;
}


void BotClient_CS_TextMsgAll (void *p, int bot_index)
{
   int i;
   bot_t *pBot;

   // Check if it's the "Bomb Planted" Message
   if ((state == 1) && (strcmp ("#Bomb_Planted", (char *) p) == 0))
   {
      g_bBombPlanted = g_bBombSayString = TRUE;
      g_fTimeBombPlanted = gpGlobals->time;

      for (i = 0; i < gpGlobals->maxClients; i++)
      {
         pBot = &bots[i];

         if (pBot->is_used && !pBot->bDead && (pBot->bot_team == TEAM_CS_COUNTER))
         {
            DeleteSearchNodes (pBot); // make all CTs reevaluate their paths immediately
            BotResetTasks (pBot); // barbarian, but fits the job perfectly.
         }
      }
   }
}
