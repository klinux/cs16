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
// util.cpp
//
// Misc utility Functions. Really not optional after all.

#include "bot_globals.h"


Vector UTIL_VecToAngles (const Vector &vec)
{
   float rgflVecOut[3];

   VEC_TO_ANGLES (vec, rgflVecOut);

   return (Vector(rgflVecOut));
}


// Overloaded to add IGNORE_GLASS
void UTIL_TraceLine (const Vector &vecStart, const Vector &vecEnd, IGNORE_MONSTERS igmon, IGNORE_GLASS ignoreGlass, edict_t *pentIgnore, TraceResult *ptr)
{
   TRACE_LINE (vecStart, vecEnd, (igmon == ignore_monsters ? TRUE : FALSE) | (ignoreGlass ? 0x100 : 0), pentIgnore, ptr);
}


void UTIL_TraceLine (const Vector &vecStart, const Vector &vecEnd, IGNORE_MONSTERS igmon, edict_t *pentIgnore, TraceResult *ptr)
{
   TRACE_LINE (vecStart, vecEnd, (igmon == ignore_monsters ? TRUE : FALSE), pentIgnore, ptr);
}


unsigned short FixedUnsigned16 (float value, float scale)
{
   int output;

   output = value * scale;
   if (output < 0)
      output = 0;
   if (output > 0xFFFF)
      output = 0xFFFF;

   return ((unsigned short) output);
}


short FixedSigned16 (float value, float scale)
{
   int output;

   output = value * scale;

   if (output > 32767)
      output = 32767;

   if (output < -32768)
      output = -32768;

   return ((short) output);
}


int UTIL_GetTeam (edict_t *pEntity)
{
   // return team number 0 through 3 based what MOD uses for team numbers

   char model_name[32];

   strcpy (model_name, (INFOKEY_VALUE (GET_INFOKEYBUFFER (pEntity), "model")));

   if ((model_name[2] == 'b') // urBan
       || (model_name[2] == 'g') // gsG9, giGn
       || (model_name[2] == 's') // saS
       || (model_name[2] == 'p')) // viP
      return (TEAM_CS_COUNTER);

   return (TEAM_CS_TERRORIST); // teRror, leEt, guErilla, arCtic
}


bot_t *UTIL_GetBotPointer (edict_t *pEdict)
{
   int index = ENTINDEX (pEdict) - 1;

   if ((index >= 0) && (index < gpGlobals->maxClients) && (bots[index].pEdict == pEdict))
      return (&bots[index]);

   return (NULL); // return NULL if edict is not a bot
}


bool IsAlive (edict_t *pEdict)
{
   return ((pEdict->v.deadflag == DEAD_NO)
           && (pEdict->v.health > 0)
           && (pEdict->v.movetype != MOVETYPE_NOCLIP));
}


bool FInViewCone (Vector *pOrigin, edict_t *pEdict)
{
   Vector2D vec2LOS;
   float flDot;
   float fov;

   MAKE_VECTORS (pEdict->v.v_angle);

   vec2LOS = (*pOrigin - pEdict->v.origin).Make2D ().Normalize ();

   flDot = DotProduct (vec2LOS, gpGlobals->v_forward.Make2D ());

   if (pEdict->v.fov > 0)
      fov = pEdict->v.fov;
   else
      fov = 90;

   if (flDot >= cos ((fov / 2) * M_PI / 180))
      return (TRUE);

   return (FALSE);
}


float GetShootingConeDeviation (edict_t *pEdict, Vector *pvecPosition)
{
   Vector vecDir = (*pvecPosition - GetGunPosition (pEdict)).Normalize ();
   Vector vecAngle = pEdict->v.v_angle;

   MAKE_VECTORS (vecAngle);

   // He's facing it, he meant it
   return (DotProduct (gpGlobals->v_forward, vecDir));
}


bool IsShootableBreakable (edict_t *pent)
{
   return ((pent->v.impulse == 0) && (pent->v.takedamage > 0)
           && (pent->v.health < 1000.0) && !(pent->v.spawnflags & SF_BREAK_TRIGGER_ONLY));
}


bool FBoxVisible (edict_t *pEdict, edict_t *pTargetEdict, Vector *pvHit, unsigned char *ucBodyPart)
{
   int i;

   *ucBodyPart = 0;

   // don't look through water
   if (((pEdict->v.waterlevel != 3) && (pTargetEdict->v.waterlevel == 3))
       || ((pEdict->v.waterlevel == 3) && (pTargetEdict->v.waterlevel == 0)))
      return (FALSE);

   TraceResult tr;
   Vector vecLookerOrigin = pEdict->v.origin + pEdict->v.view_ofs;
   Vector vecTarget = pTargetEdict->v.origin;

   // Check direct Line to waist
   UTIL_TraceLine (vecLookerOrigin, vecTarget, ignore_monsters, ignore_glass, pEdict, &tr);
   if (tr.flFraction == 1.0)
   {
      *pvHit = tr.vecEndPos;
      *ucBodyPart |= WAIST_VISIBLE;
   }

   // Check direct Line to head
   vecTarget = vecTarget + pTargetEdict->v.view_ofs;
   UTIL_TraceLine (vecLookerOrigin, vecTarget, ignore_monsters, ignore_glass, pEdict, &tr);
   if (tr.flFraction == 1.0)
   {
      *pvHit = tr.vecEndPos;
      *ucBodyPart |= HEAD_VISIBLE;
   }

   if (*ucBodyPart != 0)
      return (TRUE);

   // Nothing visible - check randomly other Parts of Body
   for (i = 0; i < 5; i++)
   {
      Vector vecTarget = pTargetEdict->v.origin;
      vecTarget.x += RANDOM_FLOAT (pTargetEdict->v.mins.x, pTargetEdict->v.maxs.x);
      vecTarget.y += RANDOM_FLOAT (pTargetEdict->v.mins.y, pTargetEdict->v.maxs.y);
      vecTarget.z += RANDOM_FLOAT (pTargetEdict->v.mins.z, pTargetEdict->v.maxs.z);

      UTIL_TraceLine (vecLookerOrigin, vecTarget, ignore_monsters, ignore_glass, pEdict, &tr);

      if (tr.flFraction == 1.0)
      {
         // Return seen position
         *pvHit = tr.vecEndPos;
         *ucBodyPart |= CUSTOM_VISIBLE;
         return (TRUE);
      }
   }

   return (FALSE);
}


bool FVisible (const Vector &vecOrigin, edict_t *pEdict)
{
   TraceResult tr;
   Vector vecLookerOrigin;

   // look through caller's eyes
   vecLookerOrigin = pEdict->v.origin + pEdict->v.view_ofs;

   // don't look through water
   if ((POINT_CONTENTS (vecOrigin) == CONTENTS_WATER)
       != (POINT_CONTENTS (vecLookerOrigin) == CONTENTS_WATER))
      return (FALSE);

   UTIL_TraceLine (vecLookerOrigin, vecOrigin, ignore_monsters, ignore_glass, pEdict, &tr);

   if (tr.flFraction != 1.0)
      return (FALSE);  // Line of sight is not established

   return (TRUE);  // line of sight is valid.
}


Vector GetGunPosition (edict_t *pEdict)
{
   return (pEdict->v.origin + pEdict->v.view_ofs);
}


int UTIL_GetNearestPlayerIndex (Vector vecOrigin)
{
   float fDistance;
   float fMinDistance = 9999.0;
   int index = 0;
   int i;

   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      if (!clients[i].IsAlive || !clients[i].IsUsed)
         continue;

      fDistance = (clients[i].pEdict->v.origin - vecOrigin).Length();

      if (fDistance < fMinDistance)
      {
         index = i;
         fMinDistance = fDistance;
      }
   }

   return (index);
}


Vector VecBModelOrigin (edict_t *pEdict)
{
   return (pEdict->v.absmin + (pEdict->v.size * 0.5));
}


void UTIL_ShowMenu (menutext_t *pMenu)
{
   if (FNullEnt (pHostEdict))
      return;

   if (GET_USER_MSG_ID (PLID, "ShowMenu", NULL) == 0)
      REG_USER_MSG ("ShowMenu", -1);

   if (pMenu != NULL)
   {
      MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, GET_USER_MSG_ID (PLID, "ShowMenu", NULL), NULL, pHostEdict);
      WRITE_SHORT (pMenu->ValidSlots);
      WRITE_CHAR (-1);
      WRITE_BYTE (0);
      WRITE_STRING (pMenu->szMenuText);
      MESSAGE_END();

      pUserMenu = pMenu;
   }
   else
   {
      MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, GET_USER_MSG_ID (PLID, "ShowMenu", NULL), NULL, pHostEdict);
      WRITE_SHORT (0);
      WRITE_CHAR (0);
      WRITE_BYTE (0);
      WRITE_STRING ("");
      MESSAGE_END();

      pUserMenu = NULL;
   }

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "player/geiger1.wav", 1.0, ATTN_NORM, 0, 100);
}


void UTIL_DisplayWpMenuWelcomeMessage (void)
{
   if (FNullEnt (pHostEdict))
      return;

   MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, NULL, pHostEdict);
   WRITE_BYTE (TE_TEXTMESSAGE);
   WRITE_BYTE (1); // channel
   WRITE_SHORT (0); // x coordinates * 8192
   WRITE_SHORT (0); // y coordinates * 8192
   WRITE_BYTE (0); // effect (fade in/out)
   WRITE_BYTE (128); // initial RED
   WRITE_BYTE (0); // initial GREEN
   WRITE_BYTE (0); // initial BLUE
   WRITE_BYTE (1); // initial ALPHA
   WRITE_BYTE (255); // effect RED
   WRITE_BYTE (255); // effect GREEN
   WRITE_BYTE (255); // effect BLUE
   WRITE_BYTE (1); // effect ALPHA
   WRITE_SHORT (256); // fade-in time in seconds * 256
   WRITE_SHORT (256); // fade-out time in seconds * 256
   WRITE_SHORT (1280); // hold time in seconds * 256
   WRITE_STRING (WPMENU_WELCOMEMSG); // write message
   MESSAGE_END (); // end
}


void UTIL_DecalTrace (TraceResult *pTrace, char *pszDecalName)
{
   short entityIndex;
   int index;
   int message;

   index = DECAL_INDEX(pszDecalName);
   if (index<0)
      index = 0;

   if (pTrace->flFraction == 1.0)
      return;

   // Only decal BSP models
   if (pTrace->pHit)
   {
      edict_t *pHit = pTrace->pHit;

      if ((pHit->v.solid == SOLID_BSP) || (pHit->v.movetype == MOVETYPE_PUSHSTEP))
         entityIndex = ENTINDEX (pHit);
      else
         return;
   }
   else
      entityIndex = 0;

   message = TE_DECAL;
   if (entityIndex != 0)
   {
      if (index > 255)
      {
         message = TE_DECALHIGH;
         index -= 256;
      }
   }
   else
   {
      message = TE_WORLDDECAL;
      if (index > 255)
      {
         message = TE_WORLDDECALHIGH;
         index -= 256;
      }
   }

   MESSAGE_BEGIN (MSG_BROADCAST, SVC_TEMPENTITY);
   WRITE_BYTE (message);
   WRITE_COORD (pTrace->vecEndPos.x);
   WRITE_COORD (pTrace->vecEndPos.y);
   WRITE_COORD (pTrace->vecEndPos.z);
   WRITE_BYTE (index);
   if (entityIndex)
      WRITE_SHORT (entityIndex);
   MESSAGE_END();
}


void UTIL_HostPrint (const char *fmt, ...)
{
   va_list argptr;
   static char pszMessage[1024];

   // concatenate all the arguments in one string
   va_start (argptr, fmt);
   vsprintf (pszMessage, fmt, argptr);
   va_end (argptr);

   if (!FNullEnt (pHostEdict))
   {
      if (GET_USER_MSG_ID (PLID, "TextMsg", NULL) == 0)
         REG_USER_MSG ("TextMsg", -1);

      MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, GET_USER_MSG_ID (PLID, "TextMsg", NULL), NULL, pHostEdict);
      WRITE_BYTE (HUD_PRINTCENTER);
      WRITE_STRING (pszMessage);
      MESSAGE_END ();

      SERVER_PRINT (pszMessage);
   }
   else
      SERVER_PRINT (pszMessage);
}


void UTIL_ServerPrint (const char *fmt, ...)
{
   va_list argptr;
   static char pszMessage[1024];

   // concatenate all the arguments in one string
   va_start (argptr, fmt);
   vsprintf (pszMessage, fmt, argptr);
   va_end (argptr);

   SERVER_PRINT (pszMessage);
}


void UTIL_ClampAngle (float *fAngle)
{
   // Whistler, TEST your bugfixes before submitting them!!! :D
   if (*fAngle >= 180)
      *fAngle -= 360 * ((int) (*fAngle / 360) + 1); // and not 0.5
   if (*fAngle < -180)
      *fAngle += 360 * ((int) (-*fAngle / 360) + 1); // and not 0.5

   if ((*fAngle >= 180) || (*fAngle < -180))
      *fAngle = 0; // heck, if we're still above the limit then something's REALLY fuckedup!
}


void UTIL_ClampVector (Vector *vecAngles)
{
   // Whistler, TEST your bugfixes before submitting them!!! :D
   if (vecAngles->x >= 180)
      vecAngles->x -= 360 * ((int) (vecAngles->x / 360) + 1); // and not 0.5
   if (vecAngles->x < -180)
      vecAngles->x += 360 * ((int) (-vecAngles->x / 360) + 1); // and not 0.5
   if (vecAngles->y >= 180)
      vecAngles->y -= 360 * ((int) (vecAngles->y / 360) + 1); // and not 0.5
   if (vecAngles->y < -180)
      vecAngles->y += 360 * ((int) (-vecAngles->y / 360) + 1); // and not 0.5
   vecAngles->z = 0.0;

   if (vecAngles->x > 89)
      vecAngles->x = 89;
   else if (vecAngles->x < -89)
      vecAngles->x = -89;

   if ((vecAngles->x >= 180) || (vecAngles->x < -180))
      vecAngles->x = 0; // heck, if we're still above the limit then something's REALLY fuckedup!
   if ((vecAngles->y >= 180) || (vecAngles->y < -180))
      vecAngles->y = 0; // heck, if we're still above the limit then something's REALLY fuckedup!
}


void UTIL_RoundStart (void)
{
   // function to be called each time a round starts in CS 1.5 or 1.6

   int i;

   for (i = 0; i < 32; i++)
   {
      if (bots[i].is_used == TRUE)
         BotSpawnInit (&bots[i]);
      iRadioSelect[i] = 0;
   }

   g_bBombPlanted = FALSE;
   g_bBombSayString = FALSE;
   g_fTimeBombPlanted = 0.0;
   g_vecBomb = g_vecZero;

   // Clear Waypoint Indices of visited Bomb Spots
   for (i = 0; i < MAXNUMBOMBSPOTS; i++)
      g_rgiBombSpotsVisited[i] = -1;

   g_iLastBombPoint = -1;
   g_fTimeNextBombUpdate = 0.0;

   g_bLeaderChosenT = FALSE;
   g_bLeaderChosenCT = FALSE;

   g_bHostageRescued = FALSE;
   g_rgfLastRadioTime[0] = 0.0;
   g_rgfLastRadioTime[1] = 0.0;
   g_bBotsCanPause = FALSE;

   // Clear Array of Player Stats
   for (i = 0; i < gpGlobals->maxClients; i++)
   {
      clients[i].vecSoundPosition = g_vecZero;
      clients[i].fHearingDistance = 0.0;
      clients[i].fTimeSoundLasting = 0.0;
   }

   // Update Experience Data on Round Start
   UpdateGlobalExperienceData ();

   // Calculate the Round Mid/End in World Time
   g_fTimeRoundStart = gpGlobals->time + CVAR_GET_FLOAT ("mp_freezetime");
   g_fTimeRoundMid = g_fTimeRoundStart + CVAR_GET_FLOAT ("mp_roundtime") * 60 / 2;
   g_fTimeRoundEnd = g_fTimeRoundStart + CVAR_GET_FLOAT ("mp_roundtime") * 60;

   // Show the Waypoint copyright Message right at round start
   g_bMapInitialised = TRUE;

   return;
}


int printf (const char *fmt, ...)
{
   va_list argptr;
   static char string[1024];

   // concatenate all the arguments in one string
   va_start (argptr, fmt);
   vsprintf (string, fmt, argptr);
   va_end (argptr);

   // are we running a listen server ?
   if (!FNullEnt (pHostEdict))
   {
      MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, GET_USER_MSG_ID (PLID, "SayText", NULL), NULL, pHostEdict); // then print to HUD
      WRITE_BYTE (ENTINDEX (pHostEdict));
      WRITE_STRING (string);
      MESSAGE_END ();
   }
   else
      SERVER_PRINT (string); // else print to console

   return (0); // printf() HAS to return a value
}
