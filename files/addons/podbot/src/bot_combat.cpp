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
// bot_combat.cpp
//
// Does Enemy Sensing (spotting), combat movement and firing weapons

#include "bot_globals.h"


int NumTeammatesNearPos (bot_t *pBot, Vector vecPosition, int iRadius)
{
   int iCount = 0;
   float fDistance;
   edict_t *pEdict = pBot->pEdict;
   int i;

   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      if (!clients[i].IsUsed
          || !clients[i].IsAlive
          || (clients[i].iTeam != pBot->bot_team)
          || (clients[i].pEdict == pEdict))
         continue;

      fDistance = (clients[i].vOrigin - vecPosition).Length ();
      if (fDistance < iRadius)
         iCount++;
   }

   return (iCount);
}


int NumEnemiesNearPos (bot_t *pBot, Vector vecPosition, int iRadius)
{
   int iCount = 0;
   float fDistance;
   edict_t *pEdict = pBot->pEdict;
   int i;

   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      if (!clients[i].IsUsed
          || !clients[i].IsAlive
          || (clients[i].iTeam == pBot->bot_team))
         continue;

      fDistance = (clients[i].vOrigin - vecPosition).Length ();
      if (fDistance < iRadius)
         iCount++;
   }

   return (iCount);
}


bool BotFindEnemy (bot_t *pBot)
{
   // Returns if an Enemy can be seen
   // FIXME: Bot should lock onto the best shoot position for
   // a target instead of going through all of them everytime

   Vector vecEnd;
   static bool flag = TRUE;
   float distance;
   float nearestdistance = pBot->f_view_distance;
   edict_t *pNewEnemy = NULL;
   edict_t *pPlayer;
   edict_t *pEdict = pBot->pEdict;
   Vector vecVisible;
   unsigned char cHit;
   int i, j;

   pBot->ucVisibility = 0;
   pBot->vecEnemy = Vector (0, 0, 0);

   // We're blind and can't see anything !!
   if (pBot->f_blind_time > gpGlobals->time)
      return (FALSE);

   // Setup Potentially Visible Set for this Bot
   Vector vecOrg = pEdict->v.origin + pEdict->v.view_ofs;
   if (pEdict->v.flags & FL_DUCKING)
      vecOrg = vecOrg + (VEC_HULL_MIN - VEC_DUCK_HULL_MIN);

   unsigned char *pvs = ENGINE_SET_PVS ((float *) &vecOrg);

   // Clear suspected Flag
   pBot->iStates &= ~STATE_SUSPECTENEMY;

   if (!FNullEnt (pBot->pBotEnemy) && (pBot->fEnemyUpdateTime > gpGlobals->time))
   {
      pPlayer = pBot->pBotEnemy;

      if (IsAlive (pPlayer))
      {
         vecEnd = pPlayer->v.origin + pPlayer->v.view_ofs;
         if (FInViewCone (&vecEnd, pEdict) && FBoxVisible (pEdict, pPlayer, &vecVisible, &cHit))
         {
            pNewEnemy = pPlayer;
            pBot->vecEnemy = vecVisible;
            pBot->ucVisibility = cHit;
         }
      }
   }

   if (FNullEnt (pNewEnemy))
   {
      pBot->fEnemyUpdateTime = gpGlobals->time + 0.5;

      // search the world for players...
      for (i = 0; i < gpGlobals->maxClients; i++)
      {
         if (!clients[i].IsUsed
             || !clients[i].IsAlive
             || (clients[i].iTeam == pBot->bot_team)
             || (clients[i].pEdict == pEdict))
            continue;

         pPlayer = clients[i].pEdict;

         // Let the Engine check if this Player is potentially visible
         if (!ENGINE_CHECK_VISIBILITY (pPlayer, pvs))
            continue;

         vecEnd = pPlayer->v.origin + pPlayer->v.view_ofs;

         // see if bot can see the player...
         if (FInViewCone (&vecEnd, pEdict) && FBoxVisible (pEdict, pPlayer, &vecVisible, &cHit))
         {
            distance = (pPlayer->v.origin - pEdict->v.origin).Length ();

            if (distance < nearestdistance)
            {
               nearestdistance = distance;
               pNewEnemy = pPlayer;
               pBot->vecEnemy = vecVisible;
               pBot->ucVisibility = cHit;

               // On Assault Maps target VIP first !
               if ((g_iMapType & MAP_AS)
                   && (strcmp ("vip", INFOKEY_VALUE (GET_INFOKEYBUFFER (pEdict), "model")) == 0)) // Is VIP ?
                  break;
            }
         }
      }
   }

   if (pNewEnemy)
   {
      g_bBotsCanPause = TRUE;
      pBot->iAimFlags |= AIM_ENEMY;

      if (pNewEnemy == pBot->pBotEnemy)
      {
         // if enemy is still visible and in field of view, keep it
         pBot->f_bot_see_enemy_time = gpGlobals->time; // keep track of when we last saw an enemy

         // Zero out reaction time
         pBot->f_actual_reaction_time = 0.0;
         pBot->pLastEnemy = pNewEnemy;
         pBot->vecLastEnemyOrigin = pBot->vecEnemy;

         return (TRUE);
      }
      else
      {
         if ((pBot->f_bot_see_enemy_time + 3.0 < gpGlobals->time)
             && ((pEdict->v.weapons & (1 << CS_WEAPON_C4))
                 || BotHasHostage (pBot) || !FNullEnt (pBot->pBotUser)))
            BotPlayRadioMessage (pBot, RADIO_ENEMYSPOTTED);

         pBot->f_enemy_surprise_time = gpGlobals->time + pBot->f_actual_reaction_time;

         // Zero out reaction time
         pBot->f_actual_reaction_time = 0.0;
         pBot->pBotEnemy = pNewEnemy;
         pBot->pLastEnemy = pNewEnemy;
         pBot->vecLastEnemyOrigin = pBot->vecEnemy;
         pBot->vecEnemyVelocity = Vector (0, 0, 0);
         pBot->fEnemyReachableTimer = 0.0;

         // keep track of when we last saw an enemy
         pBot->f_bot_see_enemy_time = gpGlobals->time;

         // Now alarm all Teammates who see this Bot &
         // don't have an actual Enemy of the Bots Enemy
         // Should simulate human players seeing a Teammate firing
         bot_t *pFriendlyBot;
         for (j = 0; j < gpGlobals->maxClients; j++)
         {
            if (!clients[j].IsUsed
                || !clients[j].IsAlive
                || (clients[j].iTeam != pBot->bot_team)
                || (clients[j].pEdict == pEdict))
               continue;

            pFriendlyBot = UTIL_GetBotPointer (clients[j].pEdict);

            if (pFriendlyBot != NULL)
            {
               if ((pFriendlyBot->f_bot_see_enemy_time + 3.0 < gpGlobals->time)
                   || FNullEnt (pFriendlyBot->pLastEnemy))
               {
                  if (FVisible (pEdict->v.origin, pFriendlyBot->pEdict))
                  {
                     pFriendlyBot->pLastEnemy = pNewEnemy;
                     pFriendlyBot->vecLastEnemyOrigin = pBot->vecLastEnemyOrigin;
                     pFriendlyBot->f_bot_see_enemy_time = gpGlobals->time;
                  }
               }
            }

         }

         return (TRUE);
      }
   }

   else if (!FNullEnt (pBot->pBotEnemy))
   {
      pNewEnemy = pBot->pBotEnemy;
      pBot->pLastEnemy = pNewEnemy;

      if (!IsAlive (pNewEnemy))
      {
         pBot->pBotEnemy = NULL;
         return (FALSE);
      }

      // If no Enemy visible check if last one shootable thru Wall
      int iShootThruFreq = BotAimTab[pBot->bot_skill / 20].iSeenShootThruProb;

      if (g_bShootThruWalls && (RANDOM_LONG (1, 100) < iShootThruFreq) && WeaponShootsThru (pBot->current_weapon.iId))
      {
         if (IsShootableThruObstacle (pEdict, pNewEnemy->v.origin))
         {
            pBot->f_bot_see_enemy_time = gpGlobals->time;
            pBot->iStates |= STATE_SUSPECTENEMY;
            pBot->iAimFlags |= AIM_LASTENEMY;
            pBot->pLastEnemy = pNewEnemy;
            pBot->vecLastEnemyOrigin = pNewEnemy->v.origin;
            return (TRUE);
         }
      }

      return (FALSE);
   }

   return (FALSE);
}


Vector BotBodyTarget (edict_t *pBotEnemy, bot_t *pBot)
{
   // Returns the aiming Vector for an Enemy
   // FIXME: Doesn't take the spotted part of the enemy

   Vector target;
   unsigned char ucVis = pBot->ucVisibility;
   edict_t *pEdict = pBot->pEdict;
   Vector vecVel = pBot->vecEnemyVelocity;

   // No Up/Down Compensation
   vecVel.z = 0.0;
   float fSkillMult = 0.1 - ((float) pBot->bot_skill / 1000.0);
   vecVel = vecVel * fSkillMult;

   // More Precision if using sniper weapon
   if (BotUsesSniper (pBot))
      vecVel = vecVel / 2;

   // Waist Visible ?
   else if (ucVis & WAIST_VISIBLE)
   {
      // Use Waist as Target for big distances
      float fDistance = (pBotEnemy->v.origin - pEdict->v.origin).Length ();
      if (fDistance > 1500)
         ucVis &= ~HEAD_VISIBLE;
   }

   // If we only suspect an Enemy behind a Wall take the worst Skill
   if (pBot->iStates & STATE_SUSPECTENEMY)
   {
      target = pBotEnemy->v.origin;
      target.x = target.x + RANDOM_FLOAT (-32.0, 32.0);
      target.y = target.y + RANDOM_FLOAT (-32.0, 32.0);
      target.z = target.z + RANDOM_FLOAT (-32.0, 32.0);
   }
   else
   {
      if ((ucVis & HEAD_VISIBLE) && (ucVis & WAIST_VISIBLE))
      {
         if (RANDOM_LONG (1, 100) < BotAimTab[pBot->bot_skill / 20].iHeadShot_Frequency)
            target = pBotEnemy->v.origin + pBotEnemy->v.view_ofs;  // aim for the head
         else
            target = pBotEnemy->v.origin;  // aim for body
      }
      else if (ucVis & HEAD_VISIBLE)
      {
         target = pBotEnemy->v.origin + pBotEnemy->v.view_ofs;  // aim for the head
         target.z -= 8.0;
      }
      else if (ucVis & WAIST_VISIBLE)
         target = pBotEnemy->v.origin;  // aim for body
      else if (ucVis & CUSTOM_VISIBLE)
         target = pBot->vecEnemy;  // aim for custom part

      // Something went wrong - use last enemy origin
      else
      {
         assert (pBot == NULL);
         target = pBot->vecLastEnemyOrigin;
      }
   }

   pBot->vecEnemyVelocity = -pBotEnemy->v.velocity;

   pBot->vecEnemy = target;
   return (target);
}


bool WeaponShootsThru (int iId)
{
   // Returns if Weapon can pierce thru a wall

   int i = 0;

   while (cs_weapon_select[i].iId)
   {
      if (cs_weapon_select[i].iId == iId)
      {
         if (cs_weapon_select[i].bShootsThru)
            return (TRUE);

         return (FALSE);
      }

      i++;
   }

   return (FALSE);
}


bool WeaponIsSniper (int iId)
{
   if ((iId == CS_WEAPON_AWP) || (iId == CS_WEAPON_G3SG1)
       || (iId == CS_WEAPON_SCOUT || iId == CS_WEAPON_SG550))
      return (TRUE);

   return (FALSE);
}


bool FireHurtsFriend (bot_t *pBot, float fDistance)
{
   edict_t *pEdict = pBot->pEdict;
   edict_t *pPlayer;
   int i;

   // search the world for players...
   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      if (!clients[i].IsUsed
          || !clients[i].IsAlive
          || (clients[i].iTeam != pBot->bot_team)
          || (clients[i].pEdict == pEdict))
         continue;

      pPlayer = clients[i].pEdict;

      if (GetShootingConeDeviation (pEdict, &pPlayer->v.origin) > 0.9)
      {
         if ((pPlayer->v.origin - pEdict->v.origin).Length () <= fDistance)
            return (TRUE);
      }
   }

   return (FALSE);
}


bool IsShootableThruObstacle (edict_t *pEdict, Vector vecDest)
{
   // Returns if enemy can be shoot through some obstacle
   // TODO: After seeing the disassembled CS Routine it could be speedup and simplified a lot

   Vector vecSrc = pEdict->v.origin+pEdict->v.view_ofs;
   Vector vecDir = (vecDest - vecSrc).Normalize (); // 1 unit long
   Vector vecPoint;
   int iThickness = 0;
   int iHits = 0;

   edict_t *pentIgnore = pEdict;
   TraceResult tr;

   UTIL_TraceLine (vecSrc, vecDest, ignore_monsters, ignore_glass, pentIgnore, &tr);

   while ((tr.flFraction != 1.0) && (iHits < 3))
   {
      iHits++;
      iThickness++;
      vecPoint = tr.vecEndPos + vecDir;

      while ((POINT_CONTENTS (vecPoint) == CONTENTS_SOLID) && (iThickness < 64))
      {
         vecPoint = vecPoint + vecDir;
         iThickness++;
      }

      UTIL_TraceLine (vecPoint, vecDest, ignore_monsters, ignore_glass, pentIgnore, &tr);
   }

   if ((iHits < 3) && (iThickness < 64))
   {
      float f_distance = (vecDest - vecPoint).Length ();

      if (f_distance < 112)
         return (TRUE);
   }

   return (FALSE);
}


bool BotDoFirePause (bot_t *pBot, float fDistance, bot_fire_delay_t* pDelay)
{
   // Returns true if Bot needs to pause between firing to compensate for
   // punchangle & weapon spread

   if (fDistance < MIN_BURST_DISTANCE)
      return (FALSE);

   else if (pBot->fTimeFirePause>gpGlobals->time)
   {
      pBot->f_shoot_time = gpGlobals->time;
      return (TRUE);
   }
   else if (pDelay->iMaxFireBullets + RANDOM_LONG (0, 1) <= pBot->iBurstShotsFired)
   {
      pBot->fTimeFirePause = gpGlobals->time + (fDistance / pDelay->fMinBurstPauseFactor);
      pBot->f_shoot_time = gpGlobals->time;
      pBot->iBurstShotsFired = 0;
      return (TRUE);
   }

   return (FALSE);
}


bool BotFireWeapon (Vector v_enemy, bot_t *pBot)
{
   // BotFireWeapon will return (TRUE) if weapon was fired, FALSE otherwise

   bot_weapon_select_t *pSelect = NULL;
   bot_fire_delay_t *pDelay = NULL;
   int iId;
   int select_index = 0;
   int iChosenWeaponIndex = 0;
   edict_t *pEdict = pBot->pEdict;
   edict_t *pEnemy = pBot->pBotEnemy;
   float distance = v_enemy.Length (); // how far away is the enemy?

   // Currently switching Weapon ?
   if ((pBot->current_weapon.iId == CS_WEAPON_INSWITCH) || pBot->bUsingGrenade)
      return (FALSE);

   // Don't shoot through TeamMates !
   if (FireHurtsFriend (pBot,distance))
      return (FALSE);

   iId = pBot->current_weapon.iId;

   // TODO: Ammo Check doesn't always work in CS !! It seems to be because
   // AmmoX and CurrentWeapon Messages don't work very well together
   if ((pBot->current_weapon.iClip == 0) && (weapon_defs[iId].iAmmo1 != -1)
       && (pBot->current_weapon.iAmmo1 > 0))
   {
      if (pBot->bIsReloading)
         return (FALSE);

      pEdict->v.button |= IN_RELOAD;   // reload
      pBot->bIsReloading = TRUE;
      return (FALSE);
   }

   pBot->bIsReloading = FALSE;

   pSelect = &cs_weapon_select[0];
   pDelay = &cs_fire_delay[0];

   if (!FNullEnt (pBot->pBotEnemy))
   {
      bool bUseKnife = FALSE;

      // Use Knife if near and good skill (l33t dude!)
      if (g_bJasonMode)
         bUseKnife = TRUE;

      if (pBot->bot_skill > 80)
      {
         if ((distance < 100) && (pBot->pEdict->v.health > 80)
             && (pBot->pEdict->v.health > pEnemy->v.health)
             && !IsGroupOfEnemies (pBot, pEdict->v.origin))
            bUseKnife = TRUE;
      }

      if (bUseKnife)
         goto WeaponSelectEnd;
   }

   // loop through all the weapons until terminator is found...
   while (pSelect[select_index].iId)
   {

      // is the bot NOT carrying this weapon?
      if  (!(pEdict->v.weapons & (1 << pSelect[select_index].iId)))
      {
         select_index++;  // skip to next weapon
         continue;
      }

      iId = pSelect[select_index].iId;

      // Check if it's the currently used weapon because
      // otherwise Ammo in Clip will be ignored
      if ((iId == pBot->current_weapon.iId)
          && (pBot->current_weapon.iClip > 0 || weapon_defs[iId].iAmmo1 == -1))
         iChosenWeaponIndex = select_index;

      // is primary percent less than weapon primary percent AND
      // no ammo required for this weapon OR
      // enough ammo available to fire AND
      // the bot is far enough away to use primary fire AND
      // the bot is close enough to the enemy to use primary fire
      else if (((weapon_defs[iId].iAmmo1 == -1)
                || (pBot->m_rgAmmo[weapon_defs[iId].iAmmo1] >= pSelect[select_index].min_primary_ammo))
               && (distance >= pSelect[select_index].primary_min_distance)
               && (distance <= pSelect[select_index].primary_max_distance))
         iChosenWeaponIndex = select_index;

      select_index++;
   }
   select_index = iChosenWeaponIndex;

WeaponSelectEnd:
   iId = pSelect[select_index].iId;

   // select this weapon if it isn't already selected
   if (pBot->current_weapon.iId != iId)
   {
      if (pBot->current_weapon.iId != CS_WEAPON_INSWITCH)
      {
         SelectWeaponByName(pBot, pSelect[select_index].weapon_name);

         // Reset Burst Fire Variables
         pBot->fTimeLastFired = 0.0;
         pBot->fTimeFirePause = 0.0;
         pBot->iBurstShotsFired = 0;
      }

      return (FALSE);
   }

   if (BotHasShieldDrawn (pBot))
      pEdict->v.button |= IN_ATTACK2;

   if (BotUsesSniper (pBot) && (pBot->f_zoomchecktime < gpGlobals->time))
   {
      // Check Distance for correct Sniper Zooming
      int iZoomMagnification;

      if (distance < 1500)
         iZoomMagnification = 1;
      else
         iZoomMagnification = 2;

      bool bZoomChange = FALSE;

      switch(iZoomMagnification)
      {
      case 1:
         if (pEdict->v.fov != 40)
            bZoomChange = TRUE;
         break;

      case 2:
         if (pEdict->v.fov < 15)
            bZoomChange = TRUE;
      }

      if (bZoomChange)
         pEdict->v.button |= IN_ATTACK2;

      pBot->f_zoomchecktime = gpGlobals->time + 2.0;
   }


   if (pDelay[select_index].iId != iId)
      return (FALSE);

   // Need to care for burst fire ?
   if (distance < MIN_BURST_DISTANCE || pBot->f_blind_time > gpGlobals->time)
   {
      if (iId == CS_WEAPON_KNIFE)
      {
         if (distance < 64)
         {
            if (RANDOM_LONG (1, 100) > 60)
               pEdict->v.button |= IN_ATTACK;  // use primary attack
            else
               pEdict->v.button |= IN_ATTACK2;  // use secondary attack
         }
      }
      else
      {
         // If Automatic Weapon, just press attack
         if (pSelect[select_index].primary_fire_hold)
               pEdict->v.button |= IN_ATTACK;
         // if not, toggle buttons
         else
         {
            if ((pEdict->v.oldbuttons & IN_ATTACK) == 0)
               pEdict->v.button |= IN_ATTACK;
         }
      }

      pBot->f_shoot_time = gpGlobals->time;
   }
   else
   {
      if (BotDoFirePause (pBot, distance, &pDelay[select_index]))
         return (FALSE);

      // Don't attack with knife over long distance
      if (iId == CS_WEAPON_KNIFE)
      {
         pBot->f_shoot_time = gpGlobals->time;
         return (FALSE);
      }

      if (pSelect[select_index].primary_fire_hold)
      {
         pBot->f_shoot_time = gpGlobals->time;
         pEdict->v.button |= IN_ATTACK;  // use primary attack
      }
      else
      {
         pEdict->v.button |= IN_ATTACK;  // use primary attack

         int skill = abs ((pBot->bot_skill / 20) - 5);
         float base_delay, min_delay, max_delay;

         base_delay = pDelay[select_index].primary_base_delay;
         min_delay = pDelay[select_index].primary_min_delay[skill];
         max_delay = pDelay[select_index].primary_max_delay[skill];

         pBot->f_shoot_time = gpGlobals->time + base_delay + RANDOM_FLOAT (min_delay, max_delay);
      }
   }

   return (TRUE);
}


void BotFocusEnemy (bot_t *pBot)
{
   if (FNullEnt (pBot->pBotEnemy))
      return;

   edict_t *pEdict = pBot->pEdict;

   // aim for the head and/or body
   Vector vecEnemy = BotBodyTarget (pBot->pBotEnemy, pBot);
   pBot->vecLookAt = vecEnemy;

   if (pBot->f_enemy_surprise_time > gpGlobals->time)
      return;

   vecEnemy = vecEnemy - GetGunPosition(pEdict);
   vecEnemy.z = 0;  // ignore z component (up & down)
   float f_distance = vecEnemy.Length ();  // how far away is the enemy scum?

   if (f_distance < 128)
   {
      if (pBot->current_weapon.iId == CS_WEAPON_KNIFE)
      {
         if (f_distance < 80)
            pBot->bWantsToFire = TRUE;
      }
      else
         pBot->bWantsToFire = TRUE;
   }
   else
   {
      float flDot = GetShootingConeDeviation (pEdict, &pBot->vecEnemy);

      if (flDot < 0.90)
         pBot->bWantsToFire = FALSE;
      else
      {
         float flEnemyDot = GetShootingConeDeviation (pBot->pBotEnemy, &pEdict->v.origin);

         // Enemy faces Bot ?
         if (flEnemyDot >= 0.90)
            pBot->bWantsToFire = TRUE;
         else
         {
            if (flDot > 0.99)
               pBot->bWantsToFire = TRUE;
            else
               pBot->bWantsToFire = FALSE;
         }
      }
   }
}


// Does the (unwaypointed) attack movement
void BotDoAttackMovement (bot_t *pBot)
{
   // No enemy ? No need to do strafing
   if (FNullEnt (pBot->pBotEnemy))
      return;

   pBot->dest_origin = pBot->pBotEnemy->v.origin;

   float f_distance;
   TraceResult tr;
   edict_t *pEdict = pBot->pEdict;
   Vector vecEnemy = pBot->vecLookAt;
   vecEnemy = vecEnemy - GetGunPosition(pEdict);
   vecEnemy.z = 0;  // ignore z component (up & down)
   f_distance = vecEnemy.Length ();  // how far away is the enemy scum?

   if (pBot->fTimeWaypointMove + pBot->fTimeFrameInterval + 0.5 < gpGlobals->time)
   {
      int iId = pBot->current_weapon.iId;
      int iApproach;
      bool bUsesSniper = BotUsesSniper(pBot);

      // If suspecting Enemy stand still
      if (pBot->iStates & STATE_SUSPECTENEMY)
         iApproach = 49;

      // If reloading or VIP back off
      else if (pBot->bIsReloading || pBot->bIsVIP)
         iApproach = 29;
      else if (iId == CS_WEAPON_KNIFE) // Knife ?
         iApproach = 100;
      else
      {
         iApproach = pBot->pEdict->v.health * pBot->fAgressionLevel;
         if (bUsesSniper && (iApproach > 49))
            iApproach = 49;
      }

      if (iApproach < 30)
      {
         pBot->f_move_speed = -pEdict->v.maxspeed;
         BotGetSafeTask(pBot)->iTask = TASK_SEEKCOVER;
         BotGetSafeTask(pBot)->bCanContinue = TRUE;
         BotGetSafeTask(pBot)->fDesire = TASKPRI_ATTACK + 1;
      }
      else if (iApproach < 50)
         pBot->f_move_speed = 0.0;
      else
         pBot->f_move_speed = pEdict->v.maxspeed;

      if ((f_distance < 96) && (iId != CS_WEAPON_KNIFE))
         pBot->f_move_speed = -pEdict->v.maxspeed;

      bool bUsesRifle = BotUsesRifle (pBot);

      if (bUsesRifle)
      {
         if (pBot->f_lastfightstylecheck + 3.0 < gpGlobals->time)
         {
            int iRand = RANDOM_LONG (1, 100);

            if (f_distance < 500)
               pBot->byFightStyle = 0;
            else if (f_distance < 1024)
            {
               if (iRand < 50)
                  pBot->byFightStyle = 0;
               else
                  pBot->byFightStyle = 1;
            }
            else
            {
               if (iRand < 90)
                  pBot->byFightStyle = 1;
               else
                  pBot->byFightStyle = 0;
            }
            pBot->f_lastfightstylecheck = gpGlobals->time;
         }
      }
      else
         pBot->byFightStyle = 0;

      if ((pBot->bot_skill > 60) && (pBot->byFightStyle == 0))
      {
         if (pBot->f_StrafeSetTime < gpGlobals->time)
         {
            Vector2D vec2DirToPoint;
            Vector2D vec2RightSide;

            // to start strafing, we have to first figure out if the target is on the left side or right side
            MAKE_VECTORS (pBot->pBotEnemy->v.v_angle);

            vec2DirToPoint = (pEdict->v.origin - pBot->pBotEnemy->v.origin).Make2D ().Normalize ();
            vec2RightSide = gpGlobals->v_right.Make2D ().Normalize ();

            if  (DotProduct  (vec2DirToPoint, vec2RightSide) < 0)
               pBot->byCombatStrafeDir = 1;
            else
               pBot->byCombatStrafeDir = 0;

            if (RANDOM_LONG (1, 100) < 30)
               pBot->byCombatStrafeDir ^= 1;

            pBot->f_StrafeSetTime = gpGlobals->time + RANDOM_FLOAT (0.5, 3.0);
         }

         if (pBot->byCombatStrafeDir == 0)
         {
            if (!BotCheckWallOnLeft (pBot))
               pBot->f_sidemove_speed = -pEdict->v.maxspeed;
            else
            {
               pBot->byCombatStrafeDir ^= 1;
               pBot->f_StrafeSetTime = gpGlobals->time + 1.0;
            }
         }
         else
         {
            if (!BotCheckWallOnRight (pBot))
               pBot->f_sidemove_speed = pEdict->v.maxspeed;
            else
            {
               pBot->byCombatStrafeDir ^= 1;
               pBot->f_StrafeSetTime = gpGlobals->time + 1.0;
            }
         }
         if (pBot->bot_skill > 80)
         {
            if ((pBot->f_jumptime + 1.5 < gpGlobals->time) && (pEdict->v.flags & FL_ONGROUND))
            {
               if ((RANDOM_LONG (1, 100) < 5) && (pEdict->v.velocity.Length2D () > 150))
                  pEdict->v.button |= IN_JUMP;
            }
         }
      }
      else if (pBot->byFightStyle == 1)
      {
         pEdict->v.button |= IN_DUCK;

         if (pBot->byCombatStrafeDir == 0)
         {
            if (!BotCheckWallOnLeft (pBot))
               pBot->f_sidemove_speed = -pEdict->v.maxspeed;
            else
               pBot->byCombatStrafeDir ^= 1;
         }
         else
         {
            if (!BotCheckWallOnRight (pBot))
               pBot->f_sidemove_speed = pEdict->v.maxspeed;
            else
               pBot->byCombatStrafeDir ^= 1;
         }

         // Don't run towards enemy
         if (pBot->f_move_speed > 0)
            pBot->f_move_speed = 0;
      }
   }
   else if ((pBot->bot_skill > 80) && (pEdict->v.flags & FL_ONGROUND))
   {
      if (f_distance < 500)
      {
         if ((RANDOM_LONG (1, 100) < 5) && (pEdict->v.velocity.Length2D () > 150))
            pEdict->v.button |= IN_JUMP;
      }
      else
         pEdict->v.button |= IN_DUCK;
   }

   if (pBot->bIsReloading)
      pBot->f_move_speed = -pEdict->v.maxspeed;

   if (!pBot->bInWater && !pBot->bOnLadder
      && ((pBot->f_move_speed != 0) || (pBot->f_sidemove_speed != 0)))
   {
      float fTimeRange = pBot->fTimeFrameInterval;
      Vector vecForward = (gpGlobals->v_forward * pBot->f_move_speed) * 0.2;
      Vector vecSide = (gpGlobals->v_right * pBot->f_sidemove_speed) * 0.2;
      Vector vecTargetPos = pEdict->v.origin + vecForward+vecSide + (pEdict->v.velocity * fTimeRange);

      if (IsDeadlyDrop (pBot, vecTargetPos))
      {
         pBot->f_sidemove_speed = -pBot->f_sidemove_speed;
         pBot->f_move_speed = -pBot->f_move_speed;
         pEdict->v.button &= ~IN_JUMP;
      }
   }

   return;
}


bool BotHasPrimaryWeapon (bot_t *pBot)
{
   bot_weapon_select_t *pSelect = &cs_weapon_select[7];
   int iWeapons = pBot->pEdict->v.weapons;

   // loop through all the weapons until terminator is found...
   while (pSelect->iId)
   {
      // is the bot carrying this weapon?
      if (iWeapons & (1 << pSelect->iId))
         return (TRUE);

      pSelect++;
   }

   return (FALSE);
}


bool BotHasShield (bot_t *pBot)
{
   // code courtesy of Wei Mingzhi. He stuffed all the bot stuff into a CBaseBot class, but
   // I'm a lazy bugger so I won't do the same.

   return (strncmp (STRING (pBot->pEdict->v.viewmodel), "models/shield/v_shield_", 23) == 0);
}


bool BotHasShieldDrawn (bot_t *pBot)
{
   // code courtesy of Wei Mingzhi. BTW check out his YaPB !

   if (!BotHasShield (pBot))
      return (FALSE);

   return ((pBot->pEdict->v.weaponanim == 6) || (pBot->pEdict->v.weaponanim == 7));
}


bool BotUsesSniper (bot_t *pBot)
{
   int iId = pBot->current_weapon.iId;

   if ((iId == CS_WEAPON_AWP) || (iId == CS_WEAPON_G3SG1)
       || (iId == CS_WEAPON_SCOUT) || (iId == CS_WEAPON_SG550))
      return (TRUE);

   return (FALSE);
}


bool BotUsesRifle (bot_t *pBot)
{
   bot_weapon_select_t *pSelect = &cs_weapon_select[0];
   int iId = pBot->current_weapon.iId;
   int iCount = 0;

   while (pSelect->iId)
   {
      if (iId == pSelect->iId)
         break;

      pSelect++;
      iCount++;
   }

   if (pSelect->iId && (iCount > 13))
      return (TRUE);

   return (FALSE);
}


int BotCheckGrenades (bot_t *pBot)
{
   int weapons = pBot->pEdict->v.weapons;

   if (weapons & (1 << CS_WEAPON_HEGRENADE))
      return (CS_WEAPON_HEGRENADE);
   else if (weapons & (1 << CS_WEAPON_FLASHBANG))
      return (CS_WEAPON_FLASHBANG);
   else if (weapons & (1 << CS_WEAPON_SMOKEGRENADE))
      return (CS_WEAPON_SMOKEGRENADE);

   return (-1);
}


void BotSelectBestWeapon(bot_t *pBot)
{
   bot_weapon_select_t *pSelect = &cs_weapon_select[0];
   int select_index = 0;
   int iChosenWeaponIndex = 0;
   int iId;
   int iWeapons = pBot->pEdict->v.weapons;

   // loop through all the weapons until terminator is found...
   while (pSelect[select_index].iId)
   {

      // is the bot NOT carrying this weapon?
      if (!(iWeapons & (1 << pSelect[select_index].iId)))
      {
         select_index++;  // skip to next weapon
         continue;
      }

      iId = pSelect[select_index].iId;

      // is primary percent less than weapon primary percent AND
      // no ammo required for this weapon OR
      // enough ammo available to fire AND
      // the bot is far enough away to use primary fire AND
      // the bot is close enough to the enemy to use primary fire

      if (((weapon_defs[iId].iAmmo1 == -1)
          || (pBot->m_rgAmmo[weapon_defs[iId].iAmmo1] >= pSelect[select_index].min_primary_ammo)))
         iChosenWeaponIndex = select_index;

      select_index++;
   }

   iChosenWeaponIndex %= NUM_WEAPONS + 1;
   select_index = iChosenWeaponIndex;

   iId = pSelect[select_index].iId;

   // select this weapon if it isn't already selected
   if (pBot->current_weapon.iId != iId)
      SelectWeaponByName (pBot, pSelect[select_index].weapon_name);
}


int HighestWeaponOfEdict (edict_t *pEdict)
{
   bot_weapon_select_t *pSelect = &cs_weapon_select[0];
   int iWeapons = pEdict->v.weapons;
   int iNum = 0;
   int i = 0;

   // loop through all the weapons until terminator is found...
   while (pSelect->iId)
   {
      // is the bot carrying this weapon?
      if ((iWeapons & (1 << pSelect->iId)))
         iNum = i;
      i++;
      pSelect++;
   }

   return (iNum);
}


void SelectWeaponByName (bot_t *pBot, char *pszName)
{
   pBot->current_weapon.iId = CS_WEAPON_INSWITCH;
   pBot->fTimeWeaponSwitch = gpGlobals->time;
   FakeClientCommand (pBot->pEdict, pszName);
}


void SelectWeaponbyNumber (bot_t *pBot, int iNum)
{
   pBot->current_weapon.iId = CS_WEAPON_INSWITCH;
   pBot->fTimeWeaponSwitch = gpGlobals->time;
   FakeClientCommand (pBot->pEdict, (char *) &cs_weapon_select[iNum].weapon_name);
}


void BotCommandTeam (bot_t *pBot)
{
   // Prevent spamming
   if (pBot->fTimeTeamOrder + 5.0 < gpGlobals->time)
   {
      bool bMemberNear = FALSE;
      edict_t *pTeamEdict;
      edict_t *pEdict = pBot->pEdict;
      int ind;

      // Search Teammates seen by this Bot
      for (ind = 0; ind < gpGlobals->maxClients; ind++)
      {
         if (!clients[ind].IsUsed
             || !clients[ind].IsAlive
             || (clients[ind].iTeam != pBot->bot_team)
             || (clients[ind].pEdict == pEdict))
            continue;

         pTeamEdict = clients[ind].pEdict;

         if (BotEntityIsVisible (pBot, pTeamEdict->v.origin))
         {
            bMemberNear = TRUE;
            break;
         }
      }

      // Has Teammates ?
      if (bMemberNear)
      {
         if ((pBot->bot_personality == 1) && !pBot->bIsVIP)
            BotPlayRadioMessage (pBot, RADIO_STORMTHEFRONT);
         else
            BotPlayRadioMessage (pBot, RADIO_FALLBACK);
      }
      else
         BotPlayRadioMessage (pBot, RADIO_TAKINGFIRE);

      pBot->fTimeTeamOrder = gpGlobals->time;
   }
}


bool IsGroupOfEnemies (bot_t *pBot, Vector vLocation)
{
   edict_t *pPlayer;
   edict_t *pEdict = pBot->pEdict;
   int iNumPlayers = 0;
   float distance;
   int i;

   // search the world for enemy players...
   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      if (!clients[i].IsUsed || !clients[i].IsAlive || (clients[i].pEdict == pEdict))
         continue;

      pPlayer = clients[i].pEdict;
      distance = (pPlayer->v.origin - vLocation).Length ();

      if (distance < 256)
      {
         // don't target our teammates...
         if (clients[i].iTeam == pBot->bot_team)
            return (FALSE);

         iNumPlayers++;
      }
   }

   if (iNumPlayers > 1)
      return (TRUE);

   return (FALSE);
}


//
// VecCheckToss - returns the velocity at which an object should be lobbed from vecspot1 to land near vecspot2.
// returns g_vecZero if toss is not feasible.
//
Vector VecCheckToss (edict_t *pEdict, const Vector &vecSpot1, Vector vecSpot2)
{
   float flGravityAdj = 0.5;
   TraceResult tr;
   Vector vecMidPoint; // halfway point between Spot1 and Spot2
   Vector vecApex; // highest point
   Vector vecScale;
   Vector vecGrenadeVel;
   Vector vecTemp;
   float flGravity = CVAR_GET_FLOAT ("sv_gravity") * flGravityAdj;

   vecSpot2 = vecSpot2 - pEdict->v.velocity;
   vecSpot2.z -= 15.0;

   if (vecSpot2.z - vecSpot1.z > 500)
      return g_vecZero; // to high, fail

   // calculate the midpoint and apex of the 'triangle'
   // UNDONE: normalize any Z position differences between spot1 and spot2 so that triangle is always RIGHT

   // How much time does it take to get there?

   // get a rough idea of how high it can be thrown
   vecMidPoint = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
   TRACE_LINE (vecMidPoint, vecMidPoint + Vector (0, 0, 500), ignore_monsters, pEdict, &tr);
   if (tr.flFraction != 1.0)
   {
      vecMidPoint = tr.vecEndPos;
      vecMidPoint.z = tr.pHit->v.absmin.z;
      vecMidPoint.z--;
   }

   if (vecMidPoint.z < vecSpot2.z)
      return (g_vecZero); // to not enough space, fail

   // How high should the grenade travel to reach the apex
   float distance1 = (vecMidPoint.z - vecSpot1.z);
   float distance2 = (vecMidPoint.z - vecSpot2.z);

   // How long will it take for the grenade to travel this distance
   float time1 = sqrt (distance1 / (0.5 * flGravity));
   float time2 = sqrt (distance2 / (0.5 * flGravity));

   if (time1 < 0.1)
      return (g_vecZero); // too close

   // how hard to throw sideways to get there in time.
   vecGrenadeVel = (vecSpot2 - vecSpot1) / (time1 + time2);

   // how hard upwards to reach the apex at the right time.
   vecGrenadeVel.z = flGravity * time1;

   // find the apex
   vecApex  = vecSpot1 + vecGrenadeVel * time1;
   vecApex.z = vecMidPoint.z;

   TRACE_HULL (vecSpot1, vecApex, dont_ignore_monsters, head_hull, pEdict, &tr);
   if (tr.flFraction != 1.0 || tr.fAllSolid)
      return (g_vecZero); // fail!

   TRACE_HULL (vecSpot2, vecApex, ignore_monsters, head_hull, pEdict, &tr);
   if (tr.flFraction != 1.0)
   {
      Vector vecDir = (vecApex - vecSpot2).Normalize ();
      float n = -DotProduct (tr.vecPlaneNormal, vecDir);

      if ((n > 0.7) || (tr.flFraction < 0.8)) // 60 degrees
         return (g_vecZero);
   }

   return (vecGrenadeVel * 0.6667);
}


//
// VecCheckThrow - returns the velocity vector at which an object should be thrown from vecspot1 to hit vecspot2.
// returns g_vecZero if throw is not feasible.
//
Vector VecCheckThrow (edict_t *pEdict, const Vector &vecSpot1, Vector vecSpot2, float flSpeed)
{
   float flGravityAdj = 1.0;
   float flGravity = CVAR_GET_FLOAT ("sv_gravity") * flGravityAdj;

   vecSpot2 = vecSpot2 - pEdict->v.velocity;
   Vector vecGrenadeVel = (vecSpot2 - vecSpot1);

   // throw at a constant time
   float time = 1.0;
   vecGrenadeVel = vecGrenadeVel * (1.0 / time);

   // adjust upward toss to compensate for gravity loss
   vecGrenadeVel.z += flGravity * time * 0.5;

   Vector vecApex = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
   vecApex.z += 0.5 * flGravity * (time * 0.5) * (time * 0.5);

   TraceResult tr;
   TRACE_HULL (vecSpot1, vecApex, dont_ignore_monsters, head_hull, pEdict, &tr);
   if (tr.flFraction != 1.0 || tr.fAllSolid)
      return (g_vecZero); // fail!

   TRACE_HULL (vecSpot2, vecApex, ignore_monsters, head_hull, pEdict, &tr);
   if (tr.flFraction != 1.0)
   {
      Vector vecDir = (vecApex - vecSpot2).Normalize ();
      float n = -DotProduct(tr.vecPlaneNormal, vecDir);

      if (n > 0.7 || tr.flFraction < 0.8) // 60 degrees
         return g_vecZero;
   }

   return (vecGrenadeVel * 0.6667);
}
