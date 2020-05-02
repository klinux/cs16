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
// bot_chat.cpp
//
// Contains parsing stuff & chat selection for chatting Bots

#include "bot_globals.h"


inline void StripClanTags (char *pszTemp1, char *pszReturn, char *cTag1, char *cTag2)
{
   // Strips out Words between Chars like []

   memset (pszReturn, 0, sizeof (pszReturn));

   unsigned char ucLen = strlen (pszTemp1);
   char* pszEndPattern;
   char* pszStartPattern = strstr (pszTemp1, cTag1);

   if (pszStartPattern)
   {
      pszStartPattern++;

      if (*pszStartPattern != 0)
      {
         pszEndPattern = strstr (pszTemp1, cTag2);

         if (pszEndPattern)
         {
            if (pszEndPattern - pszStartPattern < ucLen)
            {
               if (pszStartPattern - 1 != pszTemp1)
                  strncpy (pszReturn,pszTemp1, (pszStartPattern - pszTemp1) - 1);

               if (pszEndPattern < pszTemp1 + ucLen)
                  strcat (pszReturn,pszEndPattern + 1);
            }
         }
      }
   }
   else
      strcpy (pszReturn,pszTemp1);
}


void ConvertNameToHuman (char *pszName, char *pszReturn)
{
   // Converts given Names to a more human like style for output

   char szTemp1[80];
   char szTemp2[80];
   unsigned char ucLen = 1;
   unsigned char ucActLen = 1;

   memset (szTemp1, 0, sizeof (szTemp1));
   memset (szTemp2, 0, sizeof (szTemp1));

   StripClanTags (pszName, szTemp1, "[", "]");
   StripClanTags (szTemp1, szTemp2, "(", ")");
   StripClanTags (szTemp2, szTemp1, "{", "}");

   char *pszToken = strtok (szTemp1, " ");

   while (pszToken)
   {
      ucActLen = strlen (pszToken);

      if (ucActLen > ucLen)
      {
         strcpy (szTemp2, pszToken);
         ucLen = ucActLen;
      }

      pszToken = strtok (NULL, " '");
   }

   strcpy (pszReturn, szTemp2);
}


void BotPrepareChatMessage (bot_t *pBot, char *pszText)
{
   // Parses Messages from the Botchat, replaces Keywords
   // and converts Names into a more human style

   int iLen;
   char szNamePlaceholder[80];

   memset (&pBot->szMiscStrings, 0, sizeof (pBot->szMiscStrings));

   char *pszTextStart = pszText;
   char *pszPattern = pszText;
   edict_t *pTalkEdict = NULL;

   while (pszPattern)
   {
      // all replacement placeholders start with a %
      pszPattern = strstr (pszTextStart, "%");

      if (pszPattern)
      {
         iLen = pszPattern - pszTextStart;
         if (iLen > 0)
            strncpy (pBot->szMiscStrings, pszTextStart, iLen);
         pszPattern++;

         // Player with most frags ?
         if (*pszPattern == 'f')
         {
            int iHighestFrags = -9000; // just pick some start value
            int iCurrFrags;
            int iIndex = 0;
            int i;

            for (i = 0; i < gpGlobals->maxClients; i++)
            {
               if (!clients[i].IsUsed
                   || (clients[i].pEdict == pBot->pEdict))
                  continue;

               iCurrFrags = clients[i].pEdict->v.frags;

               if (iCurrFrags > iHighestFrags)
               {
                  iHighestFrags = iCurrFrags;
                  iIndex = i;
               }
            }

            // fix fix fix, all day long...
            if (iIndex < gpGlobals->maxClients)
            {
               pTalkEdict = clients[iIndex].pEdict;

               if (!FNullEnt (pTalkEdict))
               {
                  ConvertNameToHuman ((char *) STRING (pTalkEdict->v.netname), szNamePlaceholder);
                  strcat (pBot->szMiscStrings, szNamePlaceholder);
               }
            }
         }

         // Mapname ?
         else if (*pszPattern == 'm')
            strcat (pBot->szMiscStrings, STRING (gpGlobals->mapname));

         // Roundtime ?
         else if (*pszPattern == 'r')
         {
            char szTime[] = "000:00";
            int iTime = (int) (g_fTimeRoundEnd - gpGlobals->time);

            sprintf (szTime, "%02d:%02d", iTime / 60, iTime % 60);
            strcat (pBot->szMiscStrings, szTime);
         }

         // Chat Reply ?
         else if (*pszPattern == 's')
         {
            // crash fixes, crash fixes...
            if ((pBot->SaytextBuffer.iEntityIndex > 0)
                && (pBot->SaytextBuffer.iEntityIndex <= gpGlobals->maxClients))
            {
               pTalkEdict = INDEXENT (pBot->SaytextBuffer.iEntityIndex);

               if (!FNullEnt (pTalkEdict))
               {
                  ConvertNameToHuman ((char *) STRING (pTalkEdict->v.netname), szNamePlaceholder);
                  strcat (pBot->szMiscStrings, szNamePlaceholder);
               }
            }
         }

         // Teammate alive ?
         else if (*pszPattern == 't')
         {
	         int i;

            for (i = 0; i < gpGlobals->maxClients; i++)
            {
               if (!clients[i].IsUsed
                   || !clients[i].IsAlive
                   || (clients[i].iTeam != pBot->bot_team)
                   || (clients[i].pEdict == pBot->pEdict))
                  continue;

               break;
            }

            if (i < gpGlobals->maxClients)
            {
               pTalkEdict = clients[i].pEdict;

               if (!FNullEnt (pTalkEdict))
               {
                  ConvertNameToHuman ((char *) STRING (pTalkEdict->v.netname), szNamePlaceholder);
                  strcat (pBot->szMiscStrings, szNamePlaceholder);
               }
            }
         }

         else if (*pszPattern == 'v')
         {
            pTalkEdict = pBot->pLastVictim;

            if (!FNullEnt (pTalkEdict))
            {
               ConvertNameToHuman ((char *) STRING (pTalkEdict->v.netname), szNamePlaceholder);
               strcat (pBot->szMiscStrings, szNamePlaceholder);
            }
         }

         pszPattern++;
         pszTextStart = pszPattern;
      }
   }

   strcat (pBot->szMiscStrings, pszTextStart);

   // removes trailing '\n'
   iLen = strlen (pBot->szMiscStrings);
   if (pBot->szMiscStrings[iLen - 1] == '\n')
      pBot->szMiscStrings[iLen - 1] = 0;

   return;
}


bool BotCheckKeywords(char *pszMessage, char *pszReply)
{
   replynode_t *pReply = pChatReplies;
   char szKeyword[128];
   char *pszCurrKeyword;
   char *pszKeywordEnd;
   int iLen, iRandom;
   char cNumRetries;

   while (pReply != NULL)
   {
      pszCurrKeyword = (char *) &pReply->szKeywords;

      while (pszCurrKeyword)
      {
         pszKeywordEnd = strstr (pszCurrKeyword, "@");

         if (pszKeywordEnd)
         {
            iLen = pszKeywordEnd - pszCurrKeyword;
            strncpy (szKeyword, pszCurrKeyword, iLen);
            szKeyword[iLen] = 0x0;

            // Parse Text for occurences of keywords
            char *pPattern = strstr (pszMessage, szKeyword);

            if (pPattern)
            {
               STRINGNODE *pNode = pReply->pReplies;

               if (pReply->cNumReplies == 1)
                  strcpy (pszReply, pNode->szString);
               else
               {
                  cNumRetries = 0;
                  do
                  {
                     iRandom = RANDOM_LONG (1, pReply->cNumReplies);
                     cNumRetries++;
                  } while ((iRandom == pReply->cLastReply) && (cNumRetries <= pReply->cNumReplies));

                  pReply->cLastReply = iRandom;
                  cNumRetries = 1;

                  while (cNumRetries < iRandom)
                  {
                     pNode = pNode->Next;
                     cNumRetries++;
                  }

                  strcpy (pszReply, pNode->szString);
               }

               return (TRUE);
            }

            pszKeywordEnd++;

            if (*pszKeywordEnd == 0)
               pszKeywordEnd = NULL;
         }

         pszCurrKeyword = pszKeywordEnd;
      }

      pReply = pReply->pNextReplyNode;
   }

   // Didn't find a keyword ? // 50% of the time use some universal reply
   if (RANDOM_LONG (1, 100) < 50)
   {
      strcpy (pszReply, szNoKwChat[RANDOM_LONG (0, iNumNoKwChats - 1)]);
      return (TRUE);
   }

   return (FALSE);
}


bool BotParseChat (bot_t *pBot, char *pszReply)
{
   char szMessage[512];
   int iMessageLen;
   int i = 0;

   // Copy to safe place
   strcpy (szMessage, pBot->SaytextBuffer.szSayText);

   // Text to uppercase for Keyword parsing
   iMessageLen = strlen (szMessage);
   for (i = 0; i < iMessageLen; i++)
      szMessage[i] = (char) toupper ((int) szMessage[i]);
   szMessage[i] = 0;

   // Find the : char behind the name to get the start of the real text
   while (i <= iMessageLen)
   {
      if (szMessage[i] == ':')
         break;
      i++;
   }

   return (BotCheckKeywords (&szMessage[i], pszReply));
}


bool BotRepliesToPlayer (bot_t *pBot)
{
   char szText[256];

   if ((pBot->SaytextBuffer.iEntityIndex > 0)
       && (pBot->SaytextBuffer.iEntityIndex <= gpGlobals->maxClients)
       && (pBot->SaytextBuffer.szSayText[0] != 0))
   {
      if (pBot->SaytextBuffer.fTimeNextChat < gpGlobals->time)
      {
         if ((RANDOM_LONG (1, 100) < pBot->SaytextBuffer.cChatProbability)
             && BotParseChat (pBot, (char *) &szText))
         {
            BotPrepareChatMessage (pBot, (char *) &szText);
            BotPushMessageQueue (pBot, MSG_CS_SAY);
            pBot->SaytextBuffer.iEntityIndex = -1;
            pBot->SaytextBuffer.szSayText[0] = 0x0;
            pBot->SaytextBuffer.fTimeNextChat = gpGlobals->time + pBot->SaytextBuffer.fChatDelay;
            return (TRUE);
         }

         pBot->SaytextBuffer.iEntityIndex = -1;
         pBot->SaytextBuffer.szSayText[0] = 0x0;
      }
   }

   return (FALSE);
}
