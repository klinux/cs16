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
// engine.cpp
//
// Does the major work of calling the original Engine Functions

#include "bot_globals.h"


void pfnEmitSound (edict_t *entity, int channel, const char *sample, float volume, float attenuation, int fFlags, int pitch)
{
   SoundAttachToThreat (entity, sample, volume);

   RETURN_META (MRES_IGNORED);
}


edict_t *pfnFindEntityByString (edict_t *pEdictStartSearchAfter, const char *pszField, const char *pszValue)
{
   // new round in CS 1.5
   if (strcmp ("info_map_parameters", pszValue) == 0)
      UTIL_RoundStart (); // the round has restarted

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


void pfnClientCommand (edict_t *pEdict, char *szFmt, ...)
{
   va_list argptr;
   static char string[1024];

   va_start (argptr, szFmt);
   vsprintf (string, szFmt, argptr);
   va_end (argptr);

   // is the target entity an official bot, a third party bot or a real player ?
   if (pEdict->v.flags & FL_FAKECLIENT)
      RETURN_META (MRES_SUPERCEDE); // prevent bots to be forced to issue client commands

   RETURN_META (MRES_IGNORED);
}


void pfnMessageBegin (int msg_dest, int msg_type, const float *pOrigin, edict_t *ed)
{
   // Called each Time a Message is about to sent

   int index;
   int tab_index;

   botMsgFunction = NULL; // no msg function until known otherwise
   state = 0;

   // Bot involved ?
   if (!FNullEnt (ed))
   {
      index = ENTINDEX (ed) - 1;

      // is this message for a bot?
      if ((index >= 0) && (index < gpGlobals->maxClients) && (bots[index].pEdict == ed))
      {
         botMsgIndex = index; // index of bot receiving message

         // Message handling is done in bot_client.cpp
         if (msg_type == GET_USER_MSG_ID (PLID, "VGUIMenu", NULL))
            botMsgFunction = BotClient_CS_VGUI;
         else if (msg_type == GET_USER_MSG_ID (PLID, "ShowMenu", NULL))
            botMsgFunction = BotClient_CS_ShowMenu;
         else if (msg_type == GET_USER_MSG_ID (PLID, "StatusIcon", NULL))
            botMsgFunction = BotClient_CS_StatusIcon;
         else if (msg_type == GET_USER_MSG_ID (PLID, "WeaponList", NULL))
            botMsgFunction = BotClient_CS_WeaponList;
         else if (msg_type == GET_USER_MSG_ID (PLID, "CurWeapon", NULL))
            botMsgFunction = BotClient_CS_CurrentWeapon;
         else if (msg_type == GET_USER_MSG_ID (PLID, "AmmoX", NULL))
            botMsgFunction = BotClient_CS_AmmoX;
         else if (msg_type == GET_USER_MSG_ID (PLID, "AmmoPickup", NULL))
            botMsgFunction = BotClient_CS_AmmoPickup;
         else if (msg_type == GET_USER_MSG_ID (PLID, "Damage", NULL))
            botMsgFunction = BotClient_CS_Damage;
         else if (msg_type == GET_USER_MSG_ID (PLID, "Money", NULL))
            botMsgFunction = BotClient_CS_Money;
         else if (msg_type == GET_USER_MSG_ID (PLID, "ScreenFade", NULL))
            botMsgFunction = BotClient_CS_ScreenFade;
         else if (msg_type == GET_USER_MSG_ID (PLID, "BombDrop", NULL))
            botMsgFunction = BotClient_CS_BombDrop;
         else if (msg_type == GET_USER_MSG_ID (PLID, "BombPickup", NULL))
            botMsgFunction = BotClient_CS_BombPickup;
         else if (msg_type == GET_USER_MSG_ID (PLID, "SayText", NULL))
            botMsgFunction = BotClient_CS_SayText;
      }
   }

   // round restart in CS 1.6
   if (!g_bIsOldCS15 && (msg_dest == MSG_SPEC) && (msg_type == GET_USER_MSG_ID (PLID, "HLTV", NULL)))
      botMsgFunction = BotClient_CS_HLTV;

   else if (msg_dest == MSG_ALL)
   {
      botMsgIndex = -1; // index of bot receiving message (none)

      if (msg_type == GET_USER_MSG_ID (PLID, "DeathMsg", NULL))
         botMsgFunction = BotClient_CS_DeathMsg;
      else if (msg_type == GET_USER_MSG_ID (PLID, "WeaponList", NULL))
         botMsgFunction = BotClient_CS_WeaponList;
      else if (msg_type == GET_USER_MSG_ID (PLID, "TextMsg", NULL))
         botMsgFunction = BotClient_CS_TextMsgAll;
      else if (msg_type == SVC_INTERMISSION)
      {
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

         // Save collected Experience on Map Change
         SaveExperienceTab ();
         SaveVisTab ();
      }
   }

   RETURN_META (MRES_IGNORED);
}


void pfnMessageEnd (void)
{
   botMsgFunction = NULL;
   state = 0;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteByte (int iValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &iValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteChar (int iValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &iValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteShort (int iValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &iValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteLong (int iValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &iValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteAngle (float flValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &flValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteCoord (float flValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &flValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteString (const char *sz)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) sz, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnWriteEntity (int iValue)
{
   // if this message is for a bot, call the client message function...
   if (botMsgFunction)
      (*botMsgFunction) ((void *) &iValue, botMsgIndex);

   state++;

   RETURN_META (MRES_IGNORED);
}


void pfnClientPrintf (edict_t *pEdict, PRINT_TYPE ptype, const char *szMsg)
{
   if (pEdict->v.flags & FL_FAKECLIENT)
      RETURN_META (MRES_SUPERCEDE); // disallow client printings for bots

   RETURN_META (MRES_IGNORED);
}


const char *pfnCmd_Args (void)
{
   // this function returns a pointer to the whole current client command string. Since bots
   // have no client DLL and we may want a bot to execute a client command, we had to implement
   // a g_argv string in the bot DLL for holding the bots' commands, and also keep track of the
   // argument count. Hence this hook not to let the engine ask an unexistent client DLL for a
   // command we are holding here. Of course, real clients commands are still retrieved the
   // normal way, by asking the engine.

   if (isFakeClientCommand)
   {
      // is it a "say" or "say_team" client command ?
      if (strncmp ("say ", g_argv, 4) == 0)
         RETURN_META_VALUE (MRES_SUPERCEDE, &g_argv[0] + 4); // skip the "say" bot client command (bug in HL engine)
      else if (strncmp ("say_team ", g_argv, 9) == 0)
         RETURN_META_VALUE (MRES_SUPERCEDE, &g_argv[0] + 9); // skip the "say_team" bot client command (bug in HL engine)

      RETURN_META_VALUE (MRES_SUPERCEDE, &g_argv[0]); // else return the whole bot client command string we know
   }

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


const char *pfnCmd_Argv (int argc)
{
   // this function returns a pointer to a certain argument of the current client command. Since
   // bots have no client DLL and we may want a bot to execute a client command, we had to
   // implement a g_argv string in the bot DLL for holding the bots' commands, and also keep
   // track of the argument count. Hence this hook not to let the engine ask an unexistent client
   // DLL for a command we are holding here. Of course, real clients commands are still retrieved
   // the normal way, by asking the engine.

   if (isFakeClientCommand)
      RETURN_META_VALUE (MRES_SUPERCEDE, GetField (g_argv, argc)); // returns the wanted argument

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


int pfnCmd_Argc (void)
{
   // this function returns the number of arguments the current client command string has. Since
   // bots have no client DLL and we may want a bot to execute a client command, we had to
   // implement a g_argv string in the bot DLL for holding the bots' commands, and also keep
   // track of the argument count. Hence this hook not to let the engine ask an unexistent client
   // DLL for a command we are holding here. Of course, real clients commands are still retrieved
   // the normal way, by asking the engine.

   if (isFakeClientCommand)
      RETURN_META_VALUE (MRES_SUPERCEDE, fake_arg_count); // return the argument count

   RETURN_META_VALUE (MRES_IGNORED, 0);
}


void pfnSetClientMaxspeed (const edict_t *pEdict, float fNewMaxspeed)
{
   bot_t *pBot = UTIL_GetBotPointer ((edict_t*) pEdict);
   if (pBot != NULL)
      pBot->pEdict->v.maxspeed = fNewMaxspeed;

   RETURN_META (MRES_IGNORED);
}


const char *pfnGetPlayerAuthId (edict_t *e)
{
   if (e->v.flags & FL_FAKECLIENT)
      RETURN_META_VALUE (MRES_SUPERCEDE, "0");

   RETURN_META_VALUE (MRES_IGNORED, NULL);
}


C_DLLEXPORT int GetEngineFunctions (enginefuncs_t *pengfuncsFromEngine, int *interfaceVersion)
{
   meta_engfuncs.pfnEmitSound = pfnEmitSound;
   meta_engfuncs.pfnFindEntityByString = pfnFindEntityByString;
   meta_engfuncs.pfnClientCommand = pfnClientCommand;
   meta_engfuncs.pfnMessageBegin = pfnMessageBegin;
   meta_engfuncs.pfnMessageEnd = pfnMessageEnd;
   meta_engfuncs.pfnWriteByte = pfnWriteByte;
   meta_engfuncs.pfnWriteChar = pfnWriteChar;
   meta_engfuncs.pfnWriteShort = pfnWriteShort;
   meta_engfuncs.pfnWriteLong = pfnWriteLong;
   meta_engfuncs.pfnWriteAngle = pfnWriteAngle;
   meta_engfuncs.pfnWriteCoord = pfnWriteCoord;
   meta_engfuncs.pfnWriteString = pfnWriteString;
   meta_engfuncs.pfnWriteEntity = pfnWriteEntity;
   meta_engfuncs.pfnClientPrintf = pfnClientPrintf;
   meta_engfuncs.pfnCmd_Args = pfnCmd_Args;
   meta_engfuncs.pfnCmd_Argv = pfnCmd_Argv;
   meta_engfuncs.pfnCmd_Argc = pfnCmd_Argc;
   meta_engfuncs.pfnSetClientMaxspeed = pfnSetClientMaxspeed;
   meta_engfuncs.pfnGetPlayerAuthId = pfnGetPlayerAuthId;

   memcpy (pengfuncsFromEngine, &meta_engfuncs, sizeof (enginefuncs_t));
   return (TRUE);
}
