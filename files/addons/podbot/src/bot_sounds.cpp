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
// bot_sounds.cpp
//
// Hooks to let Bots 'hear' otherwise unnoticed things. Base code & idea from killaruna/ParaBot

#include "bot_globals.h"


void SoundAttachToThreat (edict_t *pEdict, const char *pszSample, float fVolume)
{
   // Called by the Sound Hooking Code (in EMIT_SOUND)
   // Enters the played Sound into the Array associated with the Entity

   Vector vecPosition;
   int iIndex;

   if (FNullEnt (pEdict))
      return;

   // Hit/Fall Sound ?
   if ((strncmp ("player/bhit_flesh", pszSample, 17) == 0)
       || (strncmp ("player/headshot", pszSample, 15) == 0))
   {
      iIndex = ENTINDEX (pEdict) - 1;

      // crash fix courtesy of Wei Mingzhi
      if ((iIndex < 0) || (iIndex >= gpGlobals->maxClients))
         iIndex = UTIL_GetNearestPlayerIndex (VecBModelOrigin (pEdict));

      clients[iIndex].fHearingDistance = 800.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 0.5;
      clients[iIndex].vecSoundPosition = pEdict->v.origin;
   }

   // Weapon Pickup ?
   else if (strncmp ("items/gunpickup", pszSample, 15) == 0)
   {
      iIndex = ENTINDEX (pEdict) - 1;

      // crash fix courtesy of Wei Mingzhi
      if ((iIndex < 0) || (iIndex >= gpGlobals->maxClients))
         iIndex = UTIL_GetNearestPlayerIndex (VecBModelOrigin (pEdict));

      clients[iIndex].fHearingDistance = 800.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 0.5;
      clients[iIndex].vecSoundPosition = pEdict->v.origin;
   }

   // Sniper zooming ?
   else if (strncmp ("weapons/zoom", pszSample, 12) == 0)
   {
      iIndex = ENTINDEX (pEdict) - 1;

      // crash fix courtesy of Wei Mingzhi
      if ((iIndex < 0) || (iIndex >= gpGlobals->maxClients))
         iIndex = UTIL_GetNearestPlayerIndex (VecBModelOrigin (pEdict));

      clients[iIndex].fHearingDistance = 500.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 0.1;
      clients[iIndex].vecSoundPosition = pEdict->v.origin;
   }

   // Reload ?
   else if (strncmp ("weapons/reload", pszSample, 14) == 0)
   {
      iIndex = ENTINDEX (pEdict) - 1;

      // crash fix courtesy of Wei Mingzhi
      if ((iIndex < 0) || (iIndex >= gpGlobals->maxClients))
         iIndex = UTIL_GetNearestPlayerIndex (VecBModelOrigin (pEdict));

      clients[iIndex].fHearingDistance = 500.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 0.5;
      clients[iIndex].vecSoundPosition = pEdict->v.origin;
   }

   // The following Sounds don't have the Player Entity associated
   // so we need to search the nearest Player

   // Ammo Pickup ?
   else if (strncmp ("items/9mmclip", pszSample, 13) == 0)
   {
      vecPosition = pEdict->v.origin;
      iIndex = UTIL_GetNearestPlayerIndex (vecPosition);
      clients[iIndex].fHearingDistance = 500.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 0.1;
      clients[iIndex].vecSoundPosition = pEdict->v.origin;
   }

   // CT used Hostage ?
   else if (strncmp ("hostage/hos", pszSample, 11) == 0)
   {
      vecPosition = VecBModelOrigin (pEdict);
      iIndex = UTIL_GetNearestPlayerIndex (vecPosition);
      clients[iIndex].fHearingDistance = 1024.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 5.0;
      clients[iIndex].vecSoundPosition = vecPosition;
   }

   // Broke something ?
   else if ((strncmp ("debris/bustmetal", pszSample, 16) == 0)
            || (strncmp ("debris/bustglass", pszSample, 16) == 0))
   {
      vecPosition = VecBModelOrigin (pEdict);
      iIndex = UTIL_GetNearestPlayerIndex (vecPosition);
      clients[iIndex].fHearingDistance = 1024.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 2.0;
      clients[iIndex].vecSoundPosition = vecPosition;
   }

   // Someone opened a door
   else if (strncmp ("doors/doormove", pszSample, 14) == 0)
   {
      vecPosition = VecBModelOrigin (pEdict);
      iIndex = UTIL_GetNearestPlayerIndex (vecPosition);
      clients[iIndex].fHearingDistance = 1024.0 * fVolume;
      clients[iIndex].fTimeSoundLasting = gpGlobals->time + 3.0;
      clients[iIndex].vecSoundPosition = vecPosition;
   }
}


void SoundSimulateUpdate (int iPlayerIndex)
{
   // Tries to simulate playing of Sounds to let the Bots hear
   // sounds which aren't captured through Server Sound hooking

   edict_t *pPlayer = clients[iPlayerIndex].pEdict;
   float fVelocity = pPlayer->v.velocity.Length2D ();
   float fHearDistance = 0.0;
   float fTimeSound;

   // Pressed Attack Button ?
   if (pPlayer->v.oldbuttons & IN_ATTACK)
   {
      fHearDistance = 4096.0;
      fTimeSound = gpGlobals->time + 0.5;
   }

   // Pressed Used Button ?
   else if (pPlayer->v.oldbuttons & IN_USE)
   {
      fHearDistance = 1024.0;
      fTimeSound = gpGlobals->time + 0.5;
   }

   // Uses Ladder ?
   else if (pPlayer->v.movetype == MOVETYPE_FLY)
   {
      if (fabs (pPlayer->v.velocity.z) > 50)
      {
         fHearDistance = 1024.0;
         fTimeSound = gpGlobals->time + 0.3;
      }
   }

   // Moves fast enough ?
   else
   {
      static float fMaxSpeed = 0.0;

      if (fMaxSpeed == 0.0)
         fMaxSpeed = CVAR_GET_FLOAT ("sv_maxspeed");
      fHearDistance = 1024.0 * (fVelocity / fMaxSpeed);
      fTimeSound = gpGlobals->time + 0.3;
   }

   // Did issue Sound ?
   if (fHearDistance > 0.0)
   {
      // Some sound already associated ?
      if (clients[iPlayerIndex].fTimeSoundLasting > gpGlobals->time)
      {
         // New Sound louder (bigger range) than old sound ?
         if (clients[iPlayerIndex].fHearingDistance <= fHearDistance)
         {
            // Override it with new
            clients[iPlayerIndex].fHearingDistance = fHearDistance;
            clients[iPlayerIndex].fTimeSoundLasting = fTimeSound;
            clients[iPlayerIndex].vecSoundPosition = pPlayer->v.origin;
         }
      }
      // New sound ?
      else
      {
         // Just remember it
         clients[iPlayerIndex].fHearingDistance = fHearDistance;
         clients[iPlayerIndex].fTimeSoundLasting = fTimeSound;
         clients[iPlayerIndex].vecSoundPosition = pPlayer->v.origin;
      }
   }
}
