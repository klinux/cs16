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
// waypoint.cpp
//
// Features the Waypoint Code (Editor + Bot Navigation)

#include "bot_globals.h"


void WaypointAddPath (short int add_index, short int path_index, float fDistance)
{
   PATH *p;
   int i;
   int count = 0;

   g_bWaypointsChanged = TRUE;

   p = paths[add_index];

   // Don't allow Paths get connected to the same Waypoint
   if (add_index == path_index)
   {
      UTIL_ServerPrint ("Denied path creation from %d to %d (same waypoint)\n", add_index, path_index);
      return;
   }

   // Don't allow Paths get connected twice
   for (i = 0; i < MAX_PATH_INDEX; i++)
      if (p->index[i] == path_index)
      {
         UTIL_ServerPrint ("Denied path creation from %d to %d (path already exists)\n", add_index, path_index);
         return;
      }

   // Check for free space in the Connection indices
   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      if (p->index[i] == -1)
      {
         p->index[i] = path_index;
         p->distance[i] = fabs (fDistance);

         UTIL_ServerPrint ("Path added from %d to %d\n", add_index, path_index);
         return;
      }
   }

   // There wasn't any free space. Try exchanging it with a long-distance path
   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      if (p->distance[i] > fabs (fDistance))
      {
         UTIL_ServerPrint ("Path added from %d to %d\n", add_index, path_index);

         p->index[i] = path_index;
         p->distance[i] = fabs (fDistance);
         return;
      }
   }

   return;
}


// find the nearest waypoint to the player and return the index (-1 if not found)
int WaypointFindNearest (void)
{
   int i, index;
   float distance;
   float min_distance;

   // find the nearest waypoint...
   min_distance = 9999.0;

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      distance = (paths[i]->origin - pHostEdict->v.origin).Length ();

      if (distance < min_distance)
      {
         index = i;
         min_distance = distance;
      }
   }

   // if not close enough to a waypoint then just return
   if (min_distance > 50)
      return (-1);

   return (index);
}


// find the nearest waypoint to that Origin and return the index
int WaypointFindNearestToMove (Vector vOrigin)
{
   int i, index;
   float distance;
   float min_distance;

   min_distance = 9999.0;

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      distance = (paths[i]->origin - vOrigin).Length ();

      if (distance < min_distance)
      {
         index = i;
         min_distance = distance;
      }
   }

   return (index);
}


// Returns all Waypoints within Radius from Position
void WaypointFindInRadius (Vector vecPos, float fRadius, int *pTab, int *iCount)
{
   int i, iMaxCount;
   float distance;

   iMaxCount = *iCount;
   *iCount = 0;

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      distance = (paths[i]->origin - vecPos).Length ();

      if (distance < fRadius)
      {
         *pTab++ = i;
         *iCount++;

         if (*iCount == iMaxCount)
            break;
      }
   }

   *iCount--;
   return;
}


void WaypointDrawBeam (Vector start, Vector end, int width, int red, int green, int blue)
{
   if (FNullEnt (pHostEdict))
      return;

   MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, NULL, pHostEdict);
   WRITE_BYTE (TE_BEAMPOINTS);
   WRITE_COORD (start.x);
   WRITE_COORD (start.y);
   WRITE_COORD (start.z);
   WRITE_COORD (end.x);
   WRITE_COORD (end.y);
   WRITE_COORD (end.z);
   WRITE_SHORT (m_spriteTexture);
   WRITE_BYTE (1); // framestart
   WRITE_BYTE (10); // framerate
   WRITE_BYTE (1); // life in 0.1's
   WRITE_BYTE (width); // width
   WRITE_BYTE (0); // noise
   WRITE_BYTE (red); // r, g, b
   WRITE_BYTE (green); // r, g, b
   WRITE_BYTE (blue); // r, g, b
   WRITE_BYTE (255); // brightness
   WRITE_BYTE (0); // speed
   MESSAGE_END ();

   return;
}


void WaypointAdd (int wpt_type)
{
   int index, i;
   float radius = 40;
   float distance;
   PATH *p, *prev;
   bool bPlaceNew = TRUE;
   Vector vecNewWaypoint;
   TraceResult tr;
   float min_distance;
   int iDestIndex;
   int flags;

   g_bWaypointsChanged = TRUE;
   vecNewWaypoint = pHostEdict->v.origin;

   if (wpt_type == WAYPOINT_ADD_CAMP_END)
   {
      index = WaypointFindNearest ();

      if (index != -1)
      {
         p = paths[index];

         if (!(p->flags & W_FL_CAMP))
         {
            UTIL_ServerPrint ("This is no Camping Waypoint !\n");
            return;
         }

         p->fcampendx = pHostEdict->v.v_angle.x;
         p->fcampendy = pHostEdict->v.v_angle.y;
      }

      EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "common/wpn_hudon.wav", 1.0, ATTN_NORM, 0, 100);
      return;
   }

   else if (wpt_type == WAYPOINT_ADD_JUMP_START)
   {
      index = WaypointFindNearest ();

      if (index != -1)
      {
         distance = (paths[index]->origin - pHostEdict->v.origin).Length ();

         if (distance < 50)
         {
            bPlaceNew = FALSE;
            p = paths[index];
            p->origin = (p->origin + vecLearnPos) / 2;
         }
      }
      else
         vecNewWaypoint = vecLearnPos;
   }

   else if (wpt_type == WAYPOINT_ADD_JUMP_END)
   {
      index = WaypointFindNearest ();

      if (index != -1)
      {
         distance = (paths[index]->origin - pHostEdict->v.origin).Length ();

         if (distance < 50)
         {
            bPlaceNew = FALSE;
            p = paths[index];
            flags = 0;

            for (i = 0; i < MAX_PATH_INDEX; i++)
               flags += p->connectflag[i];

            if (flags == 0)
               p->origin = (p->origin + pHostEdict->v.origin) / 2;
         }
      }
   }

   if (bPlaceNew)
   {
      if (g_iNumWaypoints + 1 >= MAX_WAYPOINTS)
      {
         UTIL_HostPrint ("Max. Waypoint reached! Can't add Waypoint!\n");
         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
         return;
      }

      index = 0;

      // find the next available slot for the new waypoint...
      p = paths[0];
      prev = NULL;

      // find an empty slot for new path_index...
      while (p != NULL)
      {
         prev = p;
         p = p->next;
         index++;
      }

      paths[index] = new PATH;
      if (paths[index] == NULL)
         return; // ERROR ALLOCATING MEMORY!!!

      p = paths[index];

      if (prev)
         prev->next = p;

      // increment total number of waypoints
      g_iNumWaypoints++;
      p->iPathNumber = index;
      p->flags = 0;

      // store the origin (location) of this waypoint
      p->origin = vecNewWaypoint;
      p->fcampstartx = 0;
      p->fcampstarty = 0;
      p->fcampendx = 0;
      p->fcampendy = 0;

      for (i = 0; i < MAX_PATH_INDEX; i++)
      {
         p->index[i] = -1;
         p->distance[i] = 0;
         p->connectflag[i] = 0;
         p->vecConnectVel[i] = g_vecZero;
      }

      p->next = NULL;

      // store the last used waypoint for the auto waypoint code...
      g_vecLastWaypoint = pHostEdict->v.origin;
   }

   if (wpt_type == WAYPOINT_ADD_JUMP_START)
      g_iLastJumpWaypoint = index;

   else if (wpt_type == WAYPOINT_ADD_JUMP_END)
   {
      distance = (paths[g_iLastJumpWaypoint]->origin - pHostEdict->v.origin).Length ();
      WaypointAddPath (g_iLastJumpWaypoint, index, distance);

      for (i = 0; i < MAX_PATH_INDEX; i++)
      {
         if (paths[g_iLastJumpWaypoint]->index[i] == index)
         {
            paths[g_iLastJumpWaypoint]->connectflag[i] |= C_FL_JUMP;
            paths[g_iLastJumpWaypoint]->vecConnectVel[i] = vecLearnVelocity;
            break;
         }
      }

      CalculateWaypointWayzone ();
      EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, 100);
      return;
   }

   if (pHostEdict->v.flags & FL_DUCKING)
      p->flags |= W_FL_CROUCH; // set a crouch waypoint

   // *******************************************************
   // look for buttons, lift, ammo, flag, health, armor, etc.
   // *******************************************************

   if (wpt_type == WAYPOINT_ADD_TERRORIST)
      p->flags |= W_FL_TERRORIST;
   else if (wpt_type == WAYPOINT_ADD_COUNTER)
      p->flags |= W_FL_COUNTER;
   else if (wpt_type == WAYPOINT_ADD_LADDER)
      p->flags |= W_FL_LADDER;
   else if (wpt_type == WAYPOINT_ADD_RESCUE)
      p->flags |= W_FL_RESCUE;
   else if (wpt_type == WAYPOINT_ADD_CAMP_START)
   {
      p->flags |= W_FL_CAMP;
      p->fcampstartx = pHostEdict->v.v_angle.x;
      p->fcampstarty = pHostEdict->v.v_angle.y;
   }
   else if (wpt_type == WAYPOINT_ADD_GOAL)
      p->flags |= W_FL_GOAL;

   // Ladder waypoints need careful connections
   if (wpt_type == WAYPOINT_ADD_LADDER)
   {
      min_distance = 9999.0;
      iDestIndex = -1;

      // calculate all the paths to this new waypoint
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         if (i == index)
            continue; // skip the waypoint that was just added

         // Other ladder waypoints should connect to this
         if (paths[i]->flags & W_FL_LADDER)
         {
            // check if the waypoint is reachable from the new one
            TRACE_LINE (vecNewWaypoint, paths[i]->origin, ignore_monsters, pHostEdict, &tr);
            if ((tr.flFraction == 1.0)
                && (fabs (vecNewWaypoint.x - paths[i]->origin.x) < 50)
                && (fabs (vecNewWaypoint.y - paths[i]->origin.y) < 50))
            {
               distance = (paths[i]->origin - vecNewWaypoint).Length ();
               WaypointAddPath (index, i, distance);
               WaypointAddPath (i, index, distance);
            }
         }
         else
         {
            // check if the waypoint is reachable from the new one
            if (WaypointNodeReachable (vecNewWaypoint, paths[i]->origin)
                || WaypointNodeReachable (paths[i]->origin, vecNewWaypoint))
            {
               distance = (paths[i]->origin - vecNewWaypoint).Length ();

               if (distance < min_distance)
               {
                  iDestIndex = i;
                  min_distance = distance;
               }
            }
         }
      }

      if ((iDestIndex > -1) && (iDestIndex < g_iNumWaypoints))
      {
         // check if the waypoint is reachable from the new one (one-way)
         if (WaypointNodeReachable (vecNewWaypoint, paths[iDestIndex]->origin))
         {
            distance = (paths[iDestIndex]->origin - vecNewWaypoint).Length ();
            WaypointAddPath (index, iDestIndex, distance);
         }

         // check if the new one is reachable from the waypoint (other way)
         if (WaypointNodeReachable (paths[iDestIndex]->origin, vecNewWaypoint))
         {
            distance = (paths[iDestIndex]->origin - vecNewWaypoint).Length ();
            WaypointAddPath (iDestIndex, index, distance);
         }
      }
   }
   else
   {
      // calculate all the paths to this new waypoint
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         if (i == index)
            continue; // skip the waypoint that was just added

         // check if the waypoint is reachable from the new one (one-way)
         if (WaypointNodeReachable (vecNewWaypoint, paths[i]->origin))
         {
            distance = (paths[i]->origin - vecNewWaypoint).Length ();
            WaypointAddPath (index, i, distance);
         }

         // check if the new one is reachable from the waypoint (other way)
         if (WaypointNodeReachable (paths[i]->origin, vecNewWaypoint))
         {
            distance = (paths[i]->origin - vecNewWaypoint).Length ();
            WaypointAddPath (i, index, distance);
         }
      }
   }

   CalculateWaypointWayzone ();
   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, 100);
   return;
}


void WaypointDelete (void)
{
   PATH *p_previous = NULL;
   PATH *p;
   int count;
   int wpt_index;
   int i, ix;

   if (g_iNumWaypoints < 1)
      return;

   wpt_index = WaypointFindNearest ();

   if ((wpt_index < 0) || (wpt_index >= g_iNumWaypoints))
   {
      UTIL_HostPrint ("No Waypoint nearby!\n");
      return;
   }

   if ((paths[wpt_index] != NULL) && (wpt_index > 0))
      p_previous = paths[wpt_index - 1];

   count = 0;

   // delete all references to Node
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      p = paths[i];

      for (ix = 0; ix < MAX_PATH_INDEX; ix++)
      {
         if (p->index[ix] == wpt_index)
         {
            p->index[ix] = -1; // unassign this path
            p->connectflag[ix] = 0;
            p->distance[ix] = 0;
            p->vecConnectVel[ix] = g_vecZero;
         }
      }
   }

   // delete all connections to Node
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      p = paths[i];

      // if Pathnumber bigger than deleted Node Number=Number -1
      if (p->iPathNumber > wpt_index)
         p->iPathNumber--;

      for (ix = 0; ix < MAX_PATH_INDEX; ix++)
         if (p->index[ix] > wpt_index)
            p->index[ix]--;
   }

   // free deleted node
   delete paths[wpt_index];
   paths[wpt_index] = NULL;

   // Rotate Path Array down
   for (i = wpt_index; i < g_iNumWaypoints - 1; i++)
      paths[i] = paths[i + 1];

   if (p_previous)
      p_previous->next = paths[wpt_index];

   g_iNumWaypoints--;

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/mine_activate.wav", 1.0, ATTN_NORM, 0, 100);
   g_bWaypointsChanged = TRUE;
   return;
}


// Remember a Waypoint
void WaypointCache (void)
{
   int iNode;

   iNode = WaypointFindNearest ();

   if (iNode == -1)
   {
      g_iCachedWaypoint = -1;
      UTIL_HostPrint ("Cache cleared (no Waypoint nearby!)\n");
      return;
   }

   g_iCachedWaypoint = iNode;
   UTIL_HostPrint ("Waypoint #%d has been put into memory\n");
   return;
}


// change a waypoint's radius
void WaypointChangeRadius (float radius)
{
   int wpt_index;

   wpt_index = WaypointFindNearest ();

   if ((wpt_index < 0) || (wpt_index >= g_iNumWaypoints))
   {
      UTIL_HostPrint ("No Waypoint nearby!\n");
      return;
   }

   paths[wpt_index]->Radius = radius;

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "common/wpn_hudon.wav", 1.0, ATTN_NORM, 0, 100);
   g_bWaypointsChanged = TRUE;
   return;
}


// switch a waypoint's flag on/off
void WaypointChangeFlag (int flag, char status)
{
   int wpt_index;

   wpt_index = WaypointFindNearest ();

   if ((wpt_index < 0) || (wpt_index >= g_iNumWaypoints))
   {
      UTIL_HostPrint ("No Waypoint nearby!\n");
      return;
   }

   if (status == FLAG_SET)
      paths[wpt_index]->flags |= flag; // set flag
   else if (status == FLAG_CLEAR)
      paths[wpt_index]->flags &= ~flag; // reset flag
   else if (status == FLAG_TOGGLE)
      paths[wpt_index]->flags ^= flag; // Switch flag on/off (XOR it)

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "common/wpn_hudon.wav", 1.0, ATTN_NORM, 0, 100);
   g_bWaypointsChanged = TRUE;
   return;
}


// allow player to manually create a path from one waypoint to another
void WaypointCreatePath (char direction)
{
   int index;
   int iNodeFrom;
   int iNodeTo;
   float distance;
   Vector vToWaypoint;
   Vector vWaypointBound;
   Vector vWaypointAngles;
   float fBestAngle;

   iNodeFrom = WaypointFindNearest ();
   iNodeTo = -1;

   if (iNodeFrom == -1)
   {
      UTIL_HostPrint ("No Waypoint nearby!\n");
      return;
   }

   // find the waypoint the user is pointing at
   fBestAngle = 5;
   for (index = 0; index < g_iNumWaypoints; index++)
   {
      vToWaypoint = paths[index]->origin - pHostEdict->v.origin;
      distance = vToWaypoint.Length ();

      if (distance > 500)
         continue;

      vWaypointAngles = UTIL_VecToAngles (vToWaypoint) - pHostEdict->v.v_angle;
      UTIL_ClampVector (&vWaypointAngles);

      if (fabs (vWaypointAngles.y) > fBestAngle)
         continue;

      fBestAngle = vWaypointAngles.y;

      if (paths[index]->flags & W_FL_CROUCH)
         vWaypointBound = paths[index]->origin - Vector (0, 0, 17);
      else
         vWaypointBound = paths[index]->origin - Vector (0, 0, 34);

      vWaypointAngles = -pHostEdict->v.v_angle;
      vWaypointAngles.x = -vWaypointAngles.x;
      vWaypointAngles = vWaypointAngles + UTIL_VecToAngles (vWaypointBound - pHostEdict->v.origin);
      UTIL_ClampVector (&vWaypointAngles);
      if (vWaypointAngles.x > 0)
         continue;

      if (paths[index]->flags & W_FL_CROUCH)
         vWaypointBound = paths[index]->origin + Vector (0, 0, 17);
      else
         vWaypointBound = paths[index]->origin + Vector (0, 0, 34);

      vWaypointAngles = -pHostEdict->v.v_angle;
      vWaypointAngles.x = -vWaypointAngles.x;
      vWaypointAngles = vWaypointAngles + UTIL_VecToAngles (vWaypointBound - pHostEdict->v.origin);
      UTIL_ClampVector (&vWaypointAngles);
      if (vWaypointAngles.x < 0)
         continue;

      iNodeTo = index;
   }

   if ((iNodeTo < 0) || (iNodeTo >= g_iNumWaypoints))
   {
      if ((g_iCachedWaypoint >= 0) && (g_iCachedWaypoint < g_iNumWaypoints))
         iNodeTo = g_iCachedWaypoint;
      else
      {
         UTIL_HostPrint ("Destination Waypoint not found!\n");
         return;
      }
   }

   if (iNodeTo == iNodeFrom)
   {
      UTIL_HostPrint ("Can't create Path to the same Waypoint!\n");
      return;
   }

   distance = (paths[iNodeTo]->origin - paths[iNodeFrom]->origin).Length ();

   if (direction == PATH_OUTGOING)
      WaypointAddPath (iNodeFrom, iNodeTo, distance);
   else if (direction == PATH_INCOMING)
      WaypointAddPath (iNodeTo, iNodeFrom, distance);
   else
   {
      WaypointAddPath (iNodeFrom, iNodeTo, distance);
      WaypointAddPath (iNodeTo, iNodeFrom, distance);
   }

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "common/wpn_hudon.wav", 1.0, ATTN_NORM, 0, 100);
   g_bWaypointsChanged = TRUE;
   return;
}


// allow player to manually remove a path from one waypoint to another
void WaypointDeletePath (void)
{
   int index;
   int iNodeFrom;
   int iNodeTo;
   float distance;
   Vector vToWaypoint;
   Vector vWaypointBound;
   Vector vWaypointAngles;
   float fBestAngle;

   iNodeFrom = WaypointFindNearest ();
   iNodeTo = -1;

   if (iNodeFrom == -1)
   {
      UTIL_HostPrint ("No Waypoint nearby!\n");
      return;
   }

   // find the waypoint the user is pointing at
   fBestAngle = 5;
   for (index = 0; index < g_iNumWaypoints; index++)
   {
      vToWaypoint = paths[index]->origin - pHostEdict->v.origin;
      distance = vToWaypoint.Length ();

      if (distance > 500)
         continue;

      vWaypointAngles = UTIL_VecToAngles (vToWaypoint) - pHostEdict->v.v_angle;
      UTIL_ClampVector (&vWaypointAngles);

      if (fabs (vWaypointAngles.y) > fBestAngle)
         continue;

      fBestAngle = vWaypointAngles.y;

      if (paths[index]->flags & W_FL_CROUCH)
         vWaypointBound = paths[index]->origin - Vector (0, 0, 17);
      else
         vWaypointBound = paths[index]->origin - Vector (0, 0, 34);

      vWaypointAngles = -pHostEdict->v.v_angle;
      vWaypointAngles.x = -vWaypointAngles.x;
      vWaypointAngles = vWaypointAngles + UTIL_VecToAngles (vWaypointBound - pHostEdict->v.origin);
      UTIL_ClampVector (&vWaypointAngles);
      if (vWaypointAngles.x > 0)
         continue;

      if (paths[index]->flags & W_FL_CROUCH)
         vWaypointBound = paths[index]->origin + Vector (0, 0, 17);
      else
         vWaypointBound = paths[index]->origin + Vector (0, 0, 34);

      vWaypointAngles = -pHostEdict->v.v_angle;
      vWaypointAngles.x = -vWaypointAngles.x;
      vWaypointAngles = vWaypointAngles + UTIL_VecToAngles (vWaypointBound - pHostEdict->v.origin);
      UTIL_ClampVector (&vWaypointAngles);
      if (vWaypointAngles.x < 0)
         continue;

      iNodeTo = index;
   }

   if ((iNodeTo < 0) || (iNodeTo >= g_iNumWaypoints))
   {
      if ((g_iCachedWaypoint >= 0) && (g_iCachedWaypoint < g_iNumWaypoints))
         iNodeTo = g_iCachedWaypoint;
      else
      {
         UTIL_HostPrint ("Destination Waypoint not found!\n");
         return;
      }
   }

   for (index = 0; index < MAX_PATH_INDEX; index++)
   {
      if (paths[iNodeFrom]->index[index] == iNodeTo)
      {
         paths[iNodeFrom]->index[index] = -1; // unassign this path
         paths[iNodeFrom]->connectflag[index] = 0;
         paths[iNodeFrom]->vecConnectVel[index] = g_vecZero;
         paths[iNodeFrom]->distance[index] = 0;

         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/mine_activate.wav", 1.0, ATTN_NORM, 0, 100);
         g_bWaypointsChanged = TRUE;
         return;
      }
   }

   // not found this way ? check for incoming connections then
   index = iNodeFrom;
   iNodeFrom = iNodeTo;
   iNodeTo = index;

   for (index = 0; index < MAX_PATH_INDEX; index++)
   {
      if (paths[iNodeFrom]->index[index] == iNodeTo)
      {
         paths[iNodeFrom]->index[index] = -1; // unassign this path
         paths[iNodeFrom]->connectflag[index] = 0;
         paths[iNodeFrom]->vecConnectVel[index] = g_vecZero;
         paths[iNodeFrom]->distance[index] = 0;

         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/mine_activate.wav", 1.0, ATTN_NORM, 0, 100);
         g_bWaypointsChanged = TRUE;
         return;
      }
   }

   UTIL_HostPrint ("Already no Path to this Waypoint!\n");
   return;
}


// Checks if Waypoint A has a Connection to Waypoint Nr. B
bool ConnectedToWaypoint (int a, int b)
{
   int ix;

   for (ix = 0; ix < MAX_PATH_INDEX; ix++)
      if (paths[a]->index[ix] == b)
         return (TRUE);

   return (FALSE);
}


void CalculateWaypointWayzone (void)
{
   PATH *p;
   Vector start;
   Vector vRadiusEnd;
   Vector v_direction;
   TraceResult tr;
   int iScanDistance;
   float fRadCircle;
   bool bWayBlocked;
   int index;
   int x;

   index = WaypointFindNearest ();
   p = paths[index];

   if ((p->flags & W_FL_LADDER)
       || (p->flags & W_FL_GOAL)
       || (p->flags & W_FL_CAMP)
       || (p->flags & W_FL_RESCUE)
       || (p->flags & W_FL_CROUCH)
       || g_bLearnJumpWaypoint)
   {
      p->Radius = 0;
      return;
   }

   for (x = 0; x < MAX_PATH_INDEX; x++)
   {
      if ((p->index[x] != -1) && (paths[p->index[x]]->flags & W_FL_LADDER))
      {
         p->Radius = 0;
         return;
      }
   }

   bWayBlocked = FALSE;

   for (iScanDistance = 32; iScanDistance < 128; iScanDistance += 16)
   {
      start = p->origin;
      MAKE_VECTORS (g_vecZero);
      vRadiusEnd = start + (gpGlobals->v_forward * iScanDistance);
      v_direction = vRadiusEnd - start;
      v_direction = UTIL_VecToAngles (v_direction);
      p->Radius = iScanDistance;

      for (fRadCircle = 0.0; fRadCircle < 360.0; fRadCircle += 20)
      {
         MAKE_VECTORS (v_direction);
         vRadiusEnd = start + (gpGlobals->v_forward * iScanDistance);
         TRACE_LINE (start, vRadiusEnd, ignore_monsters, pHostEdict, &tr);

         if (tr.flFraction < 1.0)
         {
            if (strncmp ("func_door", STRING (tr.pHit->v.classname), 9) == 0)
            {
               p->Radius = 0;
               bWayBlocked = TRUE;
               break;
            }

            bWayBlocked = TRUE;
            p->Radius -= 16;
            break;
         }

         vRadiusEnd.z += 34;
         TRACE_LINE(start, vRadiusEnd, ignore_monsters, pHostEdict, &tr);

         if (tr.flFraction < 1.0)
         {
            bWayBlocked = TRUE;
            p->Radius -= 16;
            break;
         }

         v_direction.y += fRadCircle;
         UTIL_ClampAngle (&v_direction.y);
      }

      if (bWayBlocked)
         break;
   }

   p->Radius -= 16;
   if (p->Radius < 0)
      p->Radius = 0;

   return;
}


void SaveExperienceTab (void)
{
   char filename[256];
   EXPERIENCE_HDR header;
   experiencesave_t *pExperienceSave;
   int iResult;
   int i, j;

   if ((g_iNumWaypoints <= 0) || !g_bUseExperience || g_bWaypointsChanged || g_bWaypointOn)
      return;

   strcpy (header.filetype, "PODEXP!");
   header.experiencedata_file_version = EXPERIENCE_VERSION;
   header.number_of_waypoints = g_iNumWaypoints;

   sprintf (filename, "cstrike/addons/podbot/%s/%s.pxp", g_szWPTDirname, STRING (gpGlobals->mapname));

   pExperienceSave = new experiencesave_t[g_iNumWaypoints * g_iNumWaypoints];

   if (pExperienceSave == NULL)
   {
      UTIL_ServerPrint ("ERROR: Couldn't allocate Memory for saving Experience Data!\n");
      return;
   }

   UTIL_ServerPrint ("Compressing & saving Experience Data...this may take a while!\n");

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      for (j = 0; j < g_iNumWaypoints; j++)
      {
         (pExperienceSave + (i * g_iNumWaypoints) + j)->uTeam0Damage = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage >> 3;
         (pExperienceSave + (i * g_iNumWaypoints) + j)->uTeam1Damage = (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage >> 3;
         (pExperienceSave + (i * g_iNumWaypoints) + j)->cTeam0Value = (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam0Value / 8;
         (pExperienceSave + (i * g_iNumWaypoints) + j)->cTeam1Value = (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam1Value / 8;
      }
   }

   iResult = Encode (filename, (unsigned char *) &header, sizeof (EXPERIENCE_HDR), (unsigned char *) pExperienceSave, g_iNumWaypoints * g_iNumWaypoints * sizeof (experiencesave_t));

   if (pExperienceSave != NULL)
      delete [](pExperienceSave);
   pExperienceSave = NULL;

   if (iResult == -1)
   {
      UTIL_ServerPrint ("ERROR: Couldn't save Experience Data!\n");
      return;
   }

   UTIL_ServerPrint ("Experience Data saved...\n");
   return;
}


void InitExperienceTab (void)
{
   FILE *bfp = NULL;
   experiencesave_t *pExperienceLoad;
   int iCompare;
   bool bDataLoaded = FALSE;
   bool bExperienceExists = FALSE;
   int i, j;
   EXPERIENCE_HDR header;
   char filename[256];
   char wptfilename[256];

   if (pBotExperienceData != NULL)
      delete [](pBotExperienceData);
   pBotExperienceData = NULL;

   if (!g_bUseExperience)
      return;

   if (g_iNumWaypoints == 0)
      return;

   sprintf (filename, "addons/podbot/%s/%s.pxp", g_szWPTDirname, STRING (gpGlobals->mapname));
   sprintf (wptfilename, "addons/podbot/%s/%s.pwf", g_szWPTDirname, STRING (gpGlobals->mapname));

   pBotExperienceData = new experience_t[g_iNumWaypoints * g_iNumWaypoints];

   if (pBotExperienceData == NULL)
   {
      UTIL_ServerPrint ("ERROR: Couldn't allocate Memory for Experience Data !\n");
      return;
   }

   // Does the Experience File exist & is newer than waypoint file ?
   if (COMPARE_FILE_TIME (filename, wptfilename, &iCompare))
   {
      if (iCompare > 0)
         bExperienceExists = TRUE;
   }

   if (bExperienceExists)
   {
      // Now build the real filename
      sprintf (filename, "cstrike/addons/podbot/%s/%s.pxp", g_szWPTDirname, STRING (gpGlobals->mapname));
      bfp = fopen (filename, "rb");

      // if file exists, read the experience Data from it
      if (bfp != NULL)
      {
         fread (&header, sizeof (EXPERIENCE_HDR), 1, bfp);
         fclose (bfp);

         header.filetype[7] = 0;

         if (strcmp (header.filetype, "PODEXP!") == 0)
         {
            if ((header.experiencedata_file_version == EXPERIENCE_VERSION)
                && (header.number_of_waypoints == g_iNumWaypoints))
            {
               UTIL_ServerPrint ("Loading & decompressing Experience Data\n");

               pExperienceLoad = new experiencesave_t[g_iNumWaypoints * g_iNumWaypoints];

               if (pExperienceLoad == NULL)
               {
                  UTIL_ServerPrint ("ERROR: Couldn't allocate Memory for Experience Data !\n");
                  g_bUseExperience = FALSE; // Turn Experience off to be safe
                  return;
               }

               Decode (filename, sizeof (EXPERIENCE_HDR), (unsigned char *) pExperienceLoad, g_iNumWaypoints * g_iNumWaypoints * sizeof (experiencesave_t));

               for (i = 0; i < g_iNumWaypoints; i++)
               {
                  for (j = 0; j < g_iNumWaypoints; j++)
                  {
                     if (i == j)
                     {
                        (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage = (unsigned short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->uTeam0Damage);
                        (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage = (unsigned short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->uTeam1Damage);
                     }
                     else
                     {
                        (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage = (unsigned short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->uTeam0Damage) << 3;
                        (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage = (unsigned short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->uTeam1Damage) << 3;
                     }

                     (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam0Value = (signed short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->cTeam0Value) * 8;
                     (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam1Value = (signed short) ((pExperienceLoad + (i * g_iNumWaypoints) + j)->cTeam1Value) * 8;
                  }
               }

               if (pExperienceLoad != NULL)
                  delete [](pExperienceLoad);
               pExperienceLoad = NULL;

               bDataLoaded = TRUE;
            }
         }
      }
   }

   if (!bDataLoaded)
   {
      UTIL_ServerPrint ("No Experience Data File or old one - starting new !\n");

      // initialize table by hand to correct values, and NOT zero it out, got it Markus ? ;)
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         for (j = 0; j < g_iNumWaypoints; j++)
         {
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->iTeam0_danger_index = -1;
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->iTeam1_danger_index = -1;
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam0Damage = 0;
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->uTeam1Damage = 0;
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam0Value = 0;
            (pBotExperienceData + (i * g_iNumWaypoints) + j)->wTeam1Value = 0;
         }
      }
   }
   else
      UTIL_ServerPrint ("Experience Data loaded from File...\n");

   return;
}


void SaveVisTab (void)
{
   char filename[256];
   VISTABLE_HDR header;
   int iResult;

   if ((g_iNumWaypoints <= 0) || !g_bUseExperience || g_bWaypointsChanged || g_bWaypointOn)
      return;

   strcpy (header.filetype, "PODVIS!");
   header.vistable_file_version = VISTABLE_VERSION;
   header.number_of_waypoints = g_iNumWaypoints;

   sprintf (filename, "cstrike/addons/podbot/%s/%s.pvi", g_szWPTDirname, STRING (gpGlobals->mapname));

   UTIL_ServerPrint ("Compressing & saving Visibility Table...this may take a while!\n");

   iResult = Encode (filename, (unsigned char *) &header, sizeof (EXPERIENCE_HDR), (unsigned char *) g_rgbyVisLUT, MAX_WAYPOINTS * (MAX_WAYPOINTS / 4) * sizeof (unsigned char));

   if (iResult == -1)
   {
      UTIL_ServerPrint ("ERROR: Couldn't save Visibility Table!\n");
      return;
   }

   UTIL_ServerPrint ("Visibility Table saved...\n");
   return;
}


void InitVisTab (void)
{
   FILE *bfp = NULL;
   int iCompare;
   bool bVisTableLoaded = FALSE;
   bool bVisTableExists = FALSE;
   VISTABLE_HDR header;
   char filename[256];
   char wptfilename[256];

   if (!g_bUseExperience)
      return;

   if (g_iNumWaypoints == 0)
      return;

   sprintf (filename, "addons/podbot/%s/%s.pvi", g_szWPTDirname, STRING (gpGlobals->mapname));
   sprintf (wptfilename, "addons/podbot/%s/%s.pwf", g_szWPTDirname, STRING (gpGlobals->mapname));

   // Does the Experience File exist & is newer than waypoint file ?
   if (COMPARE_FILE_TIME (filename, wptfilename, &iCompare))
   {
      if (iCompare > 0)
         bVisTableExists = TRUE;
   }

   if (bVisTableExists)
   {
      // Now build the real filename
      sprintf (filename, "cstrike/addons/podbot/%s/%s.pvi", g_szWPTDirname, STRING (gpGlobals->mapname));
      bfp = fopen (filename, "rb");

      // if file exists, read the experience Data from it
      if (bfp != NULL)
      {
         fread (&header, sizeof (VISTABLE_HDR), 1, bfp);
         fclose (bfp);

         header.filetype[7] = 0;

         if (strcmp (header.filetype, "PODVIS!") == 0)
         {
            if ((header.vistable_file_version == VISTABLE_VERSION)
                && (header.number_of_waypoints == g_iNumWaypoints))
            {
               UTIL_ServerPrint ("Loading & decompressing Visibility Table\n");

               Decode (filename, sizeof (VISTABLE_HDR), (unsigned char *) g_rgbyVisLUT, MAX_WAYPOINTS * (MAX_WAYPOINTS / 4) * sizeof (unsigned char));
               bVisTableLoaded = TRUE;
            }
         }
      }
   }

   if (!bVisTableLoaded)
   {
      UTIL_ServerPrint ("No Visibility Table File or old one - starting new !\n");

      memset (g_rgbyVisLUT, 0, sizeof (g_rgbyVisLUT));

      g_iCurrVisIndex = 0;
      g_bRecalcVis = TRUE;
      g_fTimeDisplayVisTableMsg = gpGlobals->time;
   }
   else
      UTIL_ServerPrint ("Visibility Table loaded from File...\n");

   return;
}


void InitWaypointTypes (void)
{
   int index;

   g_iNumTerrorPoints = 0;
   g_iNumCTPoints = 0;
   g_iNumGoalPoints = 0;
   g_iNumCampPoints = 0;

   memset (g_rgiTerrorWaypoints, 0, sizeof (g_rgiTerrorWaypoints));
   memset (g_rgiCTWaypoints, 0, sizeof (g_rgiCTWaypoints));
   memset (g_rgiGoalWaypoints, 0, sizeof (g_rgiGoalWaypoints));
   memset (g_rgiCampWaypoints, 0, sizeof (g_rgiCampWaypoints));

   for (index = 0; index < g_iNumWaypoints; index++)
   {
      if (paths[index]->flags & W_FL_TERRORIST)
      {
         g_rgiTerrorWaypoints[g_iNumTerrorPoints] = index;
         g_iNumTerrorPoints++;
      }

      else if (paths[index]->flags & W_FL_COUNTER)
      {
         g_rgiCTWaypoints[g_iNumCTPoints] = index;
         g_iNumCTPoints++;
      }

      else if (paths[index]->flags & W_FL_GOAL)
      {
         g_rgiGoalWaypoints[g_iNumGoalPoints] = index;
         g_iNumGoalPoints++;
      }

      else if (paths[index]->flags & W_FL_CAMP)
      {
         g_rgiCampWaypoints[g_iNumCampPoints] = index;
         g_iNumCampPoints++;
      }
   }

   return;
}


bool WaypointLoad (void)
{
   FILE *bfp = NULL;
   char filename[256];
   WAYPOINT_HDR header;
   int index;
   bool bOldWaypointFormat = FALSE;

   g_bMapInitialised = FALSE;
   g_bRecalcVis = FALSE;
   g_fTimeDisplayVisTableMsg = 0;
   g_bWaypointsSaved = FALSE;

   sprintf (filename, "cstrike/addons/podbot/%s/%s.pwf", g_szWPTDirname, STRING (gpGlobals->mapname));

   bfp = fopen (filename, "rb");
   if (bfp == NULL)
   {
      UTIL_ServerPrint ("Waypoint file %s does not exist!\n", filename);
      sprintf (g_szWaypointMessage, "Waypoint file %s does not exist!\n(you can't add Bots!)\n", filename);
      return (FALSE);
   }

   // if file exists, read the waypoint structure from it
   fread (&header, sizeof (header), 1, bfp);
   header.filetype[7] = 0;
   header.mapname[31] = 0;

   if (strcmp (header.filetype, "PODWAY!") != 0)
   {
      UTIL_ServerPrint ("%s is not a POD Bot waypoint file!\n", filename);
      sprintf (g_szWaypointMessage, "Waypoint file %s does not exist!\n", filename);
      fclose (bfp);
      return (FALSE);
   }

   if (header.waypoint_file_version != WAYPOINT_VERSION7)
   {
      if ((header.waypoint_file_version == WAYPOINT_VERSION6)
          || (header.waypoint_file_version == WAYPOINT_VERSION5))
      {
         UTIL_ServerPrint ("Old POD Bot waypoint file version (V%d)!\nTrying to convert...\n", header.waypoint_file_version);
         bOldWaypointFormat = TRUE;
      }
      else
      {
         UTIL_ServerPrint ("%s Incompatible POD Bot waypoint file version!\nWaypoints not loaded!\n",filename);
         sprintf (g_szWaypointMessage, "%s Incompatible POD Bot waypoint file version!\nWaypoints not loaded!\n", filename);
         fclose (bfp);
         return (FALSE);
      }
   }

   if (strcmp (header.mapname, STRING (gpGlobals->mapname)) != 0)
   {
      UTIL_ServerPrint ("%s POD Bot waypoints are not for this map!\n", filename);
      sprintf (g_szWaypointMessage, "%s POD Bot waypoints are not for this map!\n", filename);
      fclose (bfp);
      return (FALSE);
   }

   g_iNumWaypoints = header.number_of_waypoints;

   // read and add waypoint paths...
   for (index = 0; index < g_iNumWaypoints; index++)
   {
      // Oldest Format to convert
      if (header.waypoint_file_version == WAYPOINT_VERSION5)
      {
         PATH5 convpath;

         paths[index] = new PATH;

         // read 1 oldpath
         fread (&convpath, sizeof (PATH5), 1, bfp);

         // Convert old to new
         paths[index]->iPathNumber = convpath.iPathNumber;
         paths[index]->flags = convpath.flags;
         paths[index]->origin = convpath.origin;
         paths[index]->Radius = convpath.Radius;
         paths[index]->fcampstartx = convpath.fcampstartx;
         paths[index]->fcampstarty = convpath.fcampstarty;
         paths[index]->fcampendx = convpath.fcampendx;
         paths[index]->fcampendy = convpath.fcampendy;
         paths[index]->index[0] = convpath.index[0];
         paths[index]->index[1] = convpath.index[1];
         paths[index]->index[2] = convpath.index[2];
         paths[index]->index[3] = convpath.index[3];
         paths[index]->index[4] = -1;
         paths[index]->index[5] = -1;
         paths[index]->index[6] = -1;
         paths[index]->index[7] = -1;
         paths[index]->distance[0] = convpath.distance[0];
         paths[index]->distance[1] = convpath.distance[1];
         paths[index]->distance[2] = convpath.distance[2];
         paths[index]->distance[3] = convpath.distance[3];
         paths[index]->distance[4] = 0;
         paths[index]->distance[5] = 0;
         paths[index]->distance[6] = 0;
         paths[index]->distance[7] = 0;
         paths[index]->connectflag[0] = 0;
         paths[index]->connectflag[1] = 0;
         paths[index]->connectflag[2] = 0;
         paths[index]->connectflag[3] = 0;
         paths[index]->connectflag[4] = 0;
         paths[index]->connectflag[5] = 0;
         paths[index]->connectflag[6] = 0;
         paths[index]->connectflag[7] = 0;
         paths[index]->vecConnectVel[0] = g_vecZero;
         paths[index]->vecConnectVel[1] = g_vecZero;
         paths[index]->vecConnectVel[2] = g_vecZero;
         paths[index]->vecConnectVel[3] = g_vecZero;
         paths[index]->vecConnectVel[4] = g_vecZero;
         paths[index]->vecConnectVel[5] = g_vecZero;
         paths[index]->vecConnectVel[6] = g_vecZero;
         paths[index]->vecConnectVel[7] = g_vecZero;
      }
      else if (header.waypoint_file_version == WAYPOINT_VERSION6)
      {
         PATH6 convpath;

         paths[index] = new PATH;

         // read 1 oldpath
         fread (&convpath, sizeof (PATH6), 1, bfp);

         // Convert old to new
         paths[index]->iPathNumber = convpath.iPathNumber;
         paths[index]->flags = convpath.flags;
         paths[index]->origin = convpath.origin;
         paths[index]->Radius = convpath.Radius;
         paths[index]->fcampstartx = convpath.fcampstartx;
         paths[index]->fcampstarty = convpath.fcampstarty;
         paths[index]->fcampendx = convpath.fcampendx;
         paths[index]->fcampendy = convpath.fcampendy;
         paths[index]->index[0] = convpath.index[0];
         paths[index]->index[1] = convpath.index[1];
         paths[index]->index[2] = convpath.index[2];
         paths[index]->index[3] = convpath.index[3];
         paths[index]->index[4] = convpath.index[4];
         paths[index]->index[5] = convpath.index[5];
         paths[index]->index[6] = convpath.index[6];
         paths[index]->index[7] = convpath.index[7];
         paths[index]->distance[0] = convpath.distance[0];
         paths[index]->distance[1] = convpath.distance[1];
         paths[index]->distance[2] = convpath.distance[2];
         paths[index]->distance[3] = convpath.distance[3];
         paths[index]->distance[4] = convpath.distance[4];
         paths[index]->distance[5] = convpath.distance[5];
         paths[index]->distance[6] = convpath.distance[6];
         paths[index]->distance[7] = convpath.distance[7];
         paths[index]->connectflag[0] = 0;
         paths[index]->connectflag[1] = 0;
         paths[index]->connectflag[2] = 0;
         paths[index]->connectflag[3] = 0;
         paths[index]->connectflag[4] = 0;
         paths[index]->connectflag[5] = 0;
         paths[index]->connectflag[6] = 0;
         paths[index]->connectflag[7] = 0;
         paths[index]->vecConnectVel[0] = g_vecZero;
         paths[index]->vecConnectVel[1] = g_vecZero;
         paths[index]->vecConnectVel[2] = g_vecZero;
         paths[index]->vecConnectVel[3] = g_vecZero;
         paths[index]->vecConnectVel[4] = g_vecZero;
         paths[index]->vecConnectVel[5] = g_vecZero;
         paths[index]->vecConnectVel[6] = g_vecZero;
         paths[index]->vecConnectVel[7] = g_vecZero;
      }
      else
      {
         paths[index] = new PATH;
         fread (paths[index], sizeof (PATH), 1, bfp); // read the number of paths from this node...
      }
   }

   fclose (bfp);

   for (index = 0; index < g_iNumWaypoints; index++)
      paths[index]->next = paths[index + 1];
   paths[index - 1]->next = NULL;

   sprintf (g_szWaypointMessage, "Waypoints created by %s\n", header.creatorname);

   InitWaypointTypes ();
   InitPathMatrix ();

   g_bWaypointsChanged = FALSE;

   return (TRUE);
}


void WaypointSave (void)
{
   FILE *bfp = NULL;
   char filename[256];
   WAYPOINT_HDR header;
   int i;
   PATH *p;

   g_bWaypointsChanged = TRUE;

   strcpy (header.filetype, "PODWAY!");
   header.waypoint_file_version = WAYPOINT_VERSION7;
   header.number_of_waypoints = g_iNumWaypoints;

   memset (header.mapname, 0, sizeof (header.mapname));
   memset (header.creatorname, 0, sizeof (header.creatorname));
   strncpy (header.mapname, STRING (gpGlobals->mapname), 31);
   header.mapname[31] = 0;
   strcpy (header.creatorname, STRING (pHostEdict->v.netname));

   sprintf (filename, "cstrike/addons/podbot/%s/%s.pwf", g_szWPTDirname, header.mapname);

   bfp = fopen (filename, "wb");

   if (bfp == NULL)
   {
      UTIL_ServerPrint ("Error opening .pwf file for writing! Waypoints NOT saved!\n");
      return;
   }

   // write the waypoint header to the file...
   fwrite (&header, sizeof (header), 1, bfp);

   p = paths[0];

   // save the waypoint paths...
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      fwrite (p, sizeof (PATH), 1, bfp);
      p = p->next;
   }

   fclose (bfp);

   g_bWaypointsSaved = TRUE;
   return;
}


// Returns 2D Traveltime to a Position
float GetTravelTime (float fMaxSpeed, Vector vecSource, Vector vecPosition)
{
   float fDistance = (vecPosition - vecSource).Length2D ();
   return (fDistance / fMaxSpeed);
}


bool WaypointReachable (Vector v_src, Vector v_dest, edict_t *pEntity)
{
   TraceResult tr;
   float distance = (v_dest - v_src).Length ();

   // is the destination close enough?
   if (distance < 200)
   {
      // check if this waypoint is "visible"...
      TRACE_LINE (v_src, v_dest, ignore_monsters, pEntity, &tr);

      // if waypoint is visible from current position (even behind head)...
      if (tr.flFraction >= 1.0)
      {
         // are we in water ?
         if ((pEntity->v.waterlevel == 2) || (pEntity->v.waterlevel == 3))
         {
           // is dest waypoint higher than src? (62 is max jump height)
           if (v_dest.z > v_src.z + 62.0)
              return (FALSE); // can't reach this one

           // is dest waypoint lower than src?
           if (v_dest.z < v_src.z - 100.0)
              return (FALSE); // can't reach this one
         }

         return (TRUE);
      }
   }

   return (FALSE);
}


bool WaypointNodeReachable (Vector v_src, Vector v_dest)
{
   TraceResult tr;
   float height, last_height;
   float distance = (v_dest - v_src).Length ();

   // is the destination NOT close enough?
   if (distance > g_fAutoPathMaxDistance)
      return (FALSE);

   // check if we go through a func_illusionary, in which case return FALSE
   TRACE_HULL (v_src, v_dest, ignore_monsters, head_hull, pHostEdict, &tr);
   if (!FNullEnt (tr.pHit) && (strcmp ("func_illusionary", STRING (tr.pHit->v.classname)) == 0))
      return (FALSE); // don't add pathwaypoints through func_illusionaries

   // check if this waypoint is "visible"...
   TRACE_LINE (v_src, v_dest, ignore_monsters, pHostEdict, &tr);

   // if waypoint is visible from current position (even behind head)...
   if ((tr.flFraction >= 1.0) || (strncmp ("func_door", STRING (tr.pHit->v.classname), 9) == 0))
   {
      // If it's a door check if nothing blocks behind
      if (strncmp ("func_door", STRING (tr.pHit->v.classname), 9) == 0)
      {
         Vector vDoorEnd = tr.vecEndPos;

         TRACE_LINE (vDoorEnd, v_dest, ignore_monsters, tr.pHit, &tr);
         if (tr.flFraction < 1.0)
            return (FALSE);
      }

      // check for special case of both waypoints being in water...
      if ((POINT_CONTENTS (v_src) == CONTENTS_WATER)
          && (POINT_CONTENTS (v_dest) == CONTENTS_WATER))
          return (TRUE); // then they're reachable each other

      // check for special case of waypoint being suspended in mid-air...

      // is dest waypoint higher than src? (45 is max jump height)
      if (v_dest.z > v_src.z + 45.0)
      {
         Vector v_new_src = v_dest;
         Vector v_new_dest = v_dest;

         v_new_dest.z = v_new_dest.z - 50; // straight down 50 units

         TRACE_LINE (v_new_src, v_new_dest, ignore_monsters, pHostEdict, &tr);

         // check if we didn't hit anything, if not then it's in mid-air
         if (tr.flFraction >= 1.0)
            return (FALSE); // can't reach this one
      }

      // check if distance to ground drops more than step height at points
      // between source and destination...

      Vector v_direction = (v_dest - v_src).Normalize(); // 1 unit long
      Vector v_check = v_src;
      Vector v_down = v_src;

      v_down.z = v_down.z - 1000.0; // straight down 1000 units

      TRACE_LINE (v_check, v_down, ignore_monsters, pHostEdict, &tr);

      last_height = tr.flFraction * 1000.0; // height from ground

      distance = (v_dest - v_check).Length (); // distance from goal

      while (distance > 10.0)
      {
         // move 10 units closer to the goal...
         v_check = v_check + (v_direction * 10.0);

         v_down = v_check;
         v_down.z = v_down.z - 1000.0; // straight down 1000 units

         TRACE_LINE (v_check, v_down, ignore_monsters, pHostEdict, &tr);

         height = tr.flFraction * 1000.0; // height from ground

         // is the current height greater than the step height?
         if (height < last_height - 18.0)
            return (FALSE); // can't get there without jumping...

         last_height = height;

         distance = (v_dest - v_check).Length (); // distance from goal
      }

      return (TRUE);
   }

   return (FALSE);
}


void WaypointCalcVisibility (void)
{
   TraceResult tr;
   unsigned char byRes;
   unsigned char byShift;
   Vector vecDest;
   int i;

   if ((g_iCurrVisIndex < 0) || (g_iCurrVisIndex > g_iNumWaypoints))
      g_iCurrVisIndex = 0;

   Vector vecSourceDuck = paths[g_iCurrVisIndex]->origin;
   Vector vecSourceStand = paths[g_iCurrVisIndex]->origin;

   if (paths[g_iCurrVisIndex]->flags & W_FL_CROUCH)
   {
      vecSourceDuck.z += 12.0;
      vecSourceStand.z += 18.0 + 28.0;
   }
   else
   {
      vecSourceDuck.z += -18.0 + 12.0;
      vecSourceStand.z += 28.0;
   }

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      // First check ducked Visibility

      vecDest = paths[i]->origin;

      TRACE_LINE (vecSourceDuck, vecDest, ignore_monsters, NULL, &tr);

      // check if line of sight to object is not blocked (i.e. visible)
      if (tr.flFraction != 1.0)
         byRes = 1;
      else
         byRes = 0;
      byRes <<= 1;

      TRACE_LINE (vecSourceStand, vecDest, ignore_monsters, NULL, &tr);

      // check if line of sight to object is not blocked (i.e. visible)
      if (tr.flFraction != 1.0)
         byRes |= 1;

      if (byRes != 0)
      {
         vecDest = paths[i]->origin;
         // First check ducked Visibility
         if (paths[i]->flags & W_FL_CROUCH)
            vecDest.z += 18.0 + 28.0;
         else
            vecDest.z += 28.0;

         TRACE_LINE (vecSourceDuck, vecDest, ignore_monsters, NULL, &tr);

         // check if line of sight to object is not blocked (i.e. visible)
         if (tr.flFraction != 1.0)
            byRes |= 2;
         else
            byRes &= 1;

         TRACE_LINE (vecSourceStand, vecDest, ignore_monsters, NULL, &tr);

         // check if line of sight to object is not blocked (i.e. visible)
         if (tr.flFraction != 1.0)
            byRes |= 1;
         else
            byRes &= 2;

      }

      byShift = (i % 4) << 1;
      g_rgbyVisLUT[g_iCurrVisIndex][i >> 2] &= ~(3 << byShift);
      g_rgbyVisLUT[g_iCurrVisIndex][i >> 2] |= byRes << byShift;
   }

   g_iCurrVisIndex++;

   if ((g_fTimeDisplayVisTableMsg > 0) && (g_fTimeDisplayVisTableMsg < gpGlobals->time))
   {
      UTIL_HostPrint ("Visibility Table out of Date. Rebuilding... (%d%%)\n", (g_iCurrVisIndex * 100) / g_iNumWaypoints);
      g_fTimeDisplayVisTableMsg = gpGlobals->time + 1.0;
   }

   if (g_iCurrVisIndex == g_iNumWaypoints)
   {
      g_bRecalcVis = FALSE;
      g_fTimeDisplayVisTableMsg = 0;
   }

   return;
}


bool WaypointIsVisible (int iSourceIndex, int iDestIndex)
{
   unsigned char byRes = g_rgbyVisLUT[iSourceIndex][iDestIndex >> 2];
   byRes >>= (iDestIndex % 4) << 1;

   return (!((byRes & 3) == 3));
}


void WaypointThink (void)
{
   PATH *p;
   float distance, min_distance;
   Vector start, end;
   int i, index;
   char msg[512];
   float fRadCircle;
   Vector vRadiusStart;
   Vector vRadiusEnd;
   Vector v_direction;
   bool isJumpWaypoint;

   if (g_bEditNoclip)
      pHostEdict->v.movetype = MOVETYPE_NOCLIP;

   // is auto waypoint on?
   if (g_bAutoWaypoint)
   {
      // find the distance from the last used waypoint
      distance = (g_vecLastWaypoint - pHostEdict->v.origin).Length ();

      if (distance > 128)
      {
         min_distance = 9999.0;

         // check that no other reachable waypoints are nearby...
         for (i = 0; i < g_iNumWaypoints; i++)
         {
            if (WaypointReachable (pHostEdict->v.origin, paths[i]->origin, pHostEdict))
            {
               distance = (paths[i]->origin - pHostEdict->v.origin).Length ();

               if (distance < min_distance)
                  min_distance = distance;
            }
         }

         // make sure nearest waypoint is far enough away...
         if (min_distance >= 128)
            WaypointAdd (WAYPOINT_ADD_NORMAL); // place a waypoint here
      }
   }

   min_distance = 9999.0;

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      distance = (paths[i]->origin - pHostEdict->v.origin).Length ();

      if (distance < 500)
      {
         if (distance < min_distance)
         {
            index = i; // store index of nearest waypoint
            min_distance = distance;
         }

         if (g_fWPDisplayTime < gpGlobals->time)
         {
            if (paths[i]->flags & W_FL_CROUCH)
            {
               start = paths[i]->origin - Vector (0, 0, 17);
               end = start + Vector (0, 0, 34);
            }
            else
            {
               start = paths[i]->origin - Vector (0, 0, 34);
               end = start + Vector (0, 0, 68);
            }

            if (!FVisible (start, pHostEdict) && !FVisible (end, pHostEdict))
               continue;

            if (paths[i]->flags & W_FL_GOAL)
               WaypointDrawBeam (start, end, 30, 255, 0, 255);

            else if (paths[i]->flags & W_FL_LADDER)
               WaypointDrawBeam (start, end, 30, 255, 0, 255);

            else if (paths[i]->flags & W_FL_RESCUE)
               WaypointDrawBeam (start, end, 30, 255, 255, 255);

            else if (paths[i]->flags & W_FL_CAMP)
            {
               if (paths[i]->flags & W_FL_TERRORIST)
                  WaypointDrawBeam (start, end, 30, 255, 160, 160);
               else if (paths[i]->flags & W_FL_COUNTER)
                  WaypointDrawBeam (start, end, 30, 255, 160, 255);
               else
                  WaypointDrawBeam (start, end, 30, 0, 255, 255);
            }

            else
            {
               if (paths[i]->flags & W_FL_TERRORIST)
                  WaypointDrawBeam (start, end, 30, 255, 0, 0);
               else if (paths[i]->flags & W_FL_COUNTER)
                  WaypointDrawBeam (start, end, 30, 0, 0, 255);
               else
                  WaypointDrawBeam (start, end, 30, 0, 255, 0);
            }

            if (g_bShowWpFlags)
            {
               if (paths[i]->flags & W_FL_NOHOSTAGE)
               {
                  WaypointDrawBeam (end + Vector (-8, 0, 0), end + Vector (8, 0, 0), 30, 255, 0, 0);
                  WaypointDrawBeam (end + Vector (0, -8, 0), end + Vector (0, 8, 0), 30, 255, 0, 0);
               }

               if (paths[i]->flags & W_FL_USE_BUTTON)
               {
                  WaypointDrawBeam (end + Vector (-8, 0, -3), end + Vector (8, 0, -3), 30, 0, 255, 0);
                  WaypointDrawBeam (end + Vector (0, -8, -3), end + Vector (0, 8, -3), 30, 0, 255, 0);
               }
            }
         }
      }
   }

   // check if player is close enough to a waypoint and time to draw path and danger...
   if ((min_distance < 50) && (g_fWPDisplayTime < gpGlobals->time))
   {
      p = paths[index];
      isJumpWaypoint = FALSE;

      for (i = 0; i < MAX_PATH_INDEX; i++)
         if ((p->index[i] != -1) && (p->connectflag[i] & C_FL_JUMP))
            isJumpWaypoint = TRUE;

      sprintf (msg, "\n"
                    "\n"
                    "\n"
                    "\n"
                    "        Index Nr.: %d - Path Node Nr.:%d - Radius: %d\n"
                    "        Flags:%s%s%s%s%s%s%s%s%s%s%s%s\n"
                    "        Extra flags:%s%s\n",
                    index,
                    p->iPathNumber,
                    (int) p->Radius,
                    (p->flags == 0 ? " none" : ""),
                    (p->flags & W_FL_USE_BUTTON ? " | USE_BUTTON" : ""),
                    (p->flags & W_FL_LIFT ? " | LIFT" : ""),
                    (p->flags & W_FL_CROUCH ? " | CROUCH" : ""),
                    (p->flags & W_FL_CROSSING ? " | CROSSING" : ""),
                    (p->flags & W_FL_GOAL ? " | GOAL" : ""),
                    (p->flags & W_FL_LADDER ? " | LADDER" : ""),
                    (p->flags & W_FL_RESCUE ? " | RESCUE" : ""),
                    (p->flags & W_FL_CAMP ? " | CAMP" : ""),
                    (p->flags & W_FL_NOHOSTAGE ? " | NOHOSTAGE" : ""),
                    (p->flags & W_FL_TERRORIST ? " | TERRORIST" : ""),
                    (p->flags & W_FL_COUNTER ? " | COUNTER" : ""),
                    (!isJumpWaypoint ? " none" : ""),
                    (isJumpWaypoint ? " | JUMP" : ""));

         
      MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, NULL, pHostEdict);
      WRITE_BYTE (TE_TEXTMESSAGE);
      WRITE_BYTE (1); // channel
      WRITE_SHORT (0); // x coordinates * 8192
      WRITE_SHORT (0); // y coordinates * 8192
      WRITE_BYTE (0); // effect (fade in/out)
      WRITE_BYTE (255); // initial RED
      WRITE_BYTE (255); // initial GREEN
      WRITE_BYTE (255); // initial BLUE
      WRITE_BYTE (1); // initial ALPHA
      WRITE_BYTE (255); // effect RED
      WRITE_BYTE (255); // effect GREEN
      WRITE_BYTE (255); // effect BLUE
      WRITE_BYTE (1); // effect ALPHA
      WRITE_SHORT (0); // fade-in time in seconds * 256
      WRITE_SHORT (0); // fade-out time in seconds * 256
      WRITE_SHORT (256); // hold time in seconds * 256
      WRITE_STRING (msg); // write message
      MESSAGE_END (); // end

      if (p->flags & W_FL_CAMP)
      {
         if (p->flags & W_FL_CROUCH)
            start = p->origin - Vector (0, 0, 17) + Vector (0, 0, 34);
         else
            start = p->origin - Vector (0, 0, 34) + Vector (0, 0, 68);

         MAKE_VECTORS (Vector (p->fcampstartx, p->fcampstarty, 0));
         end = p->origin + gpGlobals->v_forward * 500;
         WaypointDrawBeam (start, end, 30, 255, 0, 0);

         MAKE_VECTORS (Vector (p->fcampendx, p->fcampendy, 0));
         end = p->origin + gpGlobals->v_forward * 500;
         WaypointDrawBeam (start, end, 30, 255, 0, 0);
      }

      for (i = 0; i < MAX_PATH_INDEX; i++)
      {
         if (p->index[i] != -1)
         {
            if (p->connectflag[i] & C_FL_JUMP)
               WaypointDrawBeam (p->origin, paths[p->index[i]]->origin, 10, 255, 0, 0);

            // If 2-way connection draw a yellow line to this index's waypoint
            else if (ConnectedToWaypoint (p->index[i], p->iPathNumber))
               WaypointDrawBeam (p->origin, paths[p->index[i]]->origin, 10, 255, 255, 0);

            // draw a white line to this index's waypoint
            else
               WaypointDrawBeam (p->origin, paths[p->index[i]]->origin, 10, 250, 250, 250);
         }
      }

      // now look for one-way incoming connections
      for (i = 0; i < g_iNumWaypoints; i++)
         if (ConnectedToWaypoint (paths[i]->iPathNumber, p->iPathNumber)
             && !ConnectedToWaypoint (p->iPathNumber, paths[i]->iPathNumber))
            WaypointDrawBeam (p->origin, paths[i]->origin, 10, 96, 48, 0);

      v_direction = g_vecZero;

      for (fRadCircle = 0.0; fRadCircle <= 180.0; fRadCircle += 22.5)
      {
         MAKE_VECTORS (v_direction);
         vRadiusStart = p->origin - (gpGlobals->v_forward * p->Radius);
         vRadiusEnd = p->origin + (gpGlobals->v_forward * p->Radius);
         WaypointDrawBeam (vRadiusStart, vRadiusEnd, 30, 0, 0, 255);

         v_direction.y = fRadCircle;
      }

      if (!g_bWaypointsChanged)
      {
         // draw a red line to this index's danger point
         if (UTIL_GetTeam (pHostEdict) == TEAM_CS_TERRORIST)
         {
            if ((pBotExperienceData + (index * g_iNumWaypoints) + index)->iTeam0_danger_index != -1)
               WaypointDrawBeam (paths[index]->origin,
                                 paths[(pBotExperienceData + (index * g_iNumWaypoints) + index)->iTeam0_danger_index]->origin,
                                 75, 127, 0, 0);
         }
         else
         {
            if ((pBotExperienceData + (index * g_iNumWaypoints) + index)->iTeam1_danger_index != -1)
               WaypointDrawBeam (paths[index]->origin,
                                 paths[(pBotExperienceData + (index * g_iNumWaypoints) + index)->iTeam1_danger_index]->origin,
                                 75, 127, 0, 0);
         }
      }
   }

   if (g_bLearnJumpWaypoint)
   {
      if (!g_bEndJumpPoint)
      {
         if (pHostEdict->v.button & IN_JUMP)
         {
            WaypointAdd (WAYPOINT_ADD_JUMP_START);
            g_fTimeJumpStarted = gpGlobals->time;
            g_bEndJumpPoint = TRUE;
         }
         else
         {
            vecLearnVelocity = pHostEdict->v.velocity;
            vecLearnPos = pHostEdict->v.origin;
         }
      }

      else if (((pHostEdict->v.flags & FL_ONGROUND) || (pHostEdict->v.movetype == MOVETYPE_FLY))
               && (g_fTimeJumpStarted + 0.1 < gpGlobals->time) && g_bEndJumpPoint)
      {
         WaypointAdd (WAYPOINT_ADD_JUMP_END);
         g_bLearnJumpWaypoint = FALSE;
         g_bEndJumpPoint = FALSE;
         UTIL_HostPrint ("Observation Check off\n");
         if (g_bUseSpeech)
            SERVER_COMMAND ("speak \"movement check over\"\n");
      }
   }

   if (g_fWPDisplayTime < gpGlobals->time)
      g_fWPDisplayTime = gpGlobals->time + 0.1;

   return;
}


void DeleteSearchNodes (bot_t *pBot)
{
   PATHNODE *NextNode;

   while (pBot->pWayNodesStart != NULL)
   {
      NextNode = pBot->pWayNodesStart->NextNode;
      delete (pBot->pWayNodesStart);
      pBot->pWayNodesStart = NextNode;
   }
   pBot->pWayNodesStart = NULL;
   pBot->pWaypointNodes = NULL;
}


bool WaypointIsConnected (int iNum)
{
   int i, n;

   for (i = 0; i < g_iNumWaypoints; i++)
      if (i != iNum)
         for (n = 0; n < MAX_PATH_INDEX; n++)
            if (paths[i]->index[n] == iNum)
               return (TRUE);

   return (FALSE);
}


bool WaypointNodesValid (void)
{
   TraceResult tr;
   PATHNODE *pStartNode, *pDelNode;
   bool bPathValid;
   int iTPoints = 0;
   int iCTPoints = 0;
   int iGoalPoints = 0;
   int iRescuePoints = 0;
   int iConnections;
   int i, n, x;

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      iConnections = 0;

      for (n = 0; n < MAX_PATH_INDEX; n++)
      {
         if (paths[i]->index[n] != -1)
         {
            iConnections++;
            break;
         }
      }

      if (iConnections == 0)
      {
         if (!WaypointIsConnected (i))
         {
            UTIL_HostPrint ("Node %d not connected to any Waypoint!\n", i);
            EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
            TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                        paths[i]->origin + Vector (0, 0, -32),
                        ignore_monsters, human_hull, pHostEdict, &tr);
            SET_ORIGIN (pHostEdict, tr.vecEndPos);
            return (FALSE);
         }
      }

      if (paths[i]->iPathNumber != i)
      {
         UTIL_HostPrint ("Node %d Pathnumber differs from Index!\n", i);
         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
         TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                     paths[i]->origin + Vector (0, 0, -32),
                     ignore_monsters, human_hull, pHostEdict, &tr);
         SET_ORIGIN (pHostEdict, tr.vecEndPos);
         return (FALSE);
      }

      if ((paths[i]->next == NULL) && (i != g_iNumWaypoints - 1))
      {
         UTIL_HostPrint ("Node %d not connected!\n", i);
         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
         TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                     paths[i]->origin + Vector (0, 0, -32),
                     ignore_monsters, human_hull, pHostEdict, &tr);
         SET_ORIGIN (pHostEdict, tr.vecEndPos);
         return (FALSE);
      }

      if (paths[i]->flags & W_FL_CAMP)
      {
         if ((paths[i]->fcampstartx == 0.0) && (paths[i]->fcampstarty == 0.0))
         {
            UTIL_HostPrint ("Node %d Camp Start Position not set!\n", i);
            EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
            TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                        paths[i]->origin + Vector (0, 0, -32),
                        ignore_monsters, human_hull, pHostEdict, &tr);
            SET_ORIGIN (pHostEdict, tr.vecEndPos);
            return (FALSE);
         }

         else if ((paths[i]->fcampendx == 0.0) && (paths[i]->fcampendy == 0.0))
         {
            UTIL_HostPrint ("Node %d Camp End Position not set !\n", i);
            EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
            TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                        paths[i]->origin + Vector (0, 0, -32),
                        ignore_monsters, human_hull, pHostEdict, &tr);
            SET_ORIGIN (pHostEdict, tr.vecEndPos);
            return (FALSE);
         }
      }

      else if (paths[i]->flags & W_FL_TERRORIST)
         iTPoints++;
      else if (paths[i]->flags & W_FL_COUNTER)
         iCTPoints++;
      else if (paths[i]->flags & W_FL_GOAL)
         iGoalPoints++;
      else if (paths[i]->flags & W_FL_RESCUE)
         iRescuePoints++;

      for (x = 0; x < MAX_PATH_INDEX; x++)
      {
         if (paths[i]->index[x] != -1)
         {
            if ((paths[i]->index[x] >= g_iNumWaypoints) || (paths[i]->index[x] < -1))
            {
               UTIL_HostPrint ("Node %d - Path Index %d out of Range!\n", i, x);
               EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
               TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                           paths[i]->origin + Vector (0, 0, -32),
                           ignore_monsters, human_hull, pHostEdict, &tr);
               SET_ORIGIN (pHostEdict, tr.vecEndPos);
               return (FALSE);
            }

            else if (paths[i]->index[x] == paths[i]->iPathNumber)
            {
               UTIL_HostPrint ("Node %d - Path Index %d points to itself!\n", i, x);
               EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
               TRACE_HULL (paths[i]->origin + Vector (0, 0, 32),
                           paths[i]->origin + Vector (0, 0, -32),
                           ignore_monsters, human_hull, pHostEdict, &tr);
               SET_ORIGIN (pHostEdict, tr.vecEndPos);
               return (FALSE);
            }
         }
      }
   }

   if (g_iMapType & MAP_CS)
   {
      if (iRescuePoints == 0)
      {
         UTIL_HostPrint ("You didn't set a Rescue Point!\n");
         EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
         return (FALSE);
      }
   }

   if (iTPoints == 0)
   {
      UTIL_HostPrint ("You didn't set any Terrorist Point!\n");
      EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
      return (FALSE);
   }

   else if (iCTPoints == 0)
   {
      UTIL_HostPrint ("You didn't set any Counter Point!\n");
      EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
      return (FALSE);
   }

   else if (iGoalPoints == 0)
   {
      UTIL_HostPrint ("You didn't set any Goal Points!\n");
      EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
      return (FALSE);
   }

   // Init Floyd Matrix to use Floyd Pathfinder
   InitPathMatrix ();

   // Now check if each and every Path is valid
   for (i = 0; i < g_iNumWaypoints; i++)
   {
      for (n = 0; n < g_iNumWaypoints; n++)
      {
         if (i == n)
            continue;

         pStartNode = FindShortestPath (i, n, &bPathValid);

         while (pStartNode != NULL)
         {
            pDelNode = pStartNode->NextNode;
            delete pStartNode;
            pStartNode = pDelNode;
         }

         pStartNode = NULL;
         pDelNode = NULL;

         // No path from A to B ?
         if (!bPathValid)
         {
            UTIL_HostPrint ("No Path from %d to %d! One or both are unconnected!\n", i, n);
            EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "debris/bustglass1.wav", 1.0, ATTN_NORM, 0, 100);
            TRACE_HULL (paths[n]->origin + Vector (0, 0, 32),
                        paths[n]->origin + Vector (0, 0, -32),
                        ignore_monsters, human_hull, pHostEdict, &tr);
            SET_ORIGIN (pHostEdict, tr.vecEndPos);
            return (FALSE);
         }
      }
   }

   EMIT_SOUND_DYN2 (pHostEdict, CHAN_WEAPON, "weapons/he_bounce-1.wav", 1.0, ATTN_NORM, 0, 100);
   return (TRUE);
}


void InitPathMatrix (void)
{
   int i, j, k;
   PATH *p;

   g_pFloydDistanceMatrix = new int[g_iNumWaypoints * g_iNumWaypoints];
   g_pFloydPathMatrix = new int[g_iNumWaypoints * g_iNumWaypoints];

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      for (j = 0; j < g_iNumWaypoints; j++)
      {
         *(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + j) = 999999;
         *(g_pFloydPathMatrix + (i * g_iNumWaypoints) + j) = -1;
      }
   }

   for (i = 0; i < g_iNumWaypoints; i++)
   {
      if (paths[i]->index[0] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[0])) = paths[i]->distance[0];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[0])) = paths[i]->index[0];
      }

      if (paths[i]->index[1] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[1])) = paths[i]->distance[1];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[1])) = paths[i]->index[1];
      }

      if (paths[i]->index[2] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[2])) = paths[i]->distance[2];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[2])) = paths[i]->index[2];
      }

      if (paths[i]->index[3] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[3])) = paths[i]->distance[3];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[3])) = paths[i]->index[3];
      }

      if (paths[i]->index[4] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[4])) = paths[i]->distance[4];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[4])) = paths[i]->index[4];
      }

      if (paths[i]->index[5] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[5])) = paths[i]->distance[5];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[5])) = paths[i]->index[5];
      }

      if (paths[i]->index[6] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[6])) = paths[i]->distance[6];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[6])) = paths[i]->index[6];
      }

      if (paths[i]->index[7] != -1)
      {
         *(g_pFloydDistanceMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[7])) = paths[i]->distance[7];
         *(g_pFloydPathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[7])) = paths[i]->index[7];
      }
   }

   for (i = 0; i < g_iNumWaypoints; i++)
      *(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + i) = 0;

   for (k = 0; k < g_iNumWaypoints; k++)
   {
      for (i = 0; i < g_iNumWaypoints; i++)
      {
         for (j = 0; j < g_iNumWaypoints; j++)
         {
            if (*(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + k) + *(g_pFloydDistanceMatrix + (k * g_iNumWaypoints) + j)
                < (*(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + j)))
            {
               *(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + j) = *(g_pFloydDistanceMatrix + (i * g_iNumWaypoints) + k) + *(g_pFloydDistanceMatrix + (k * g_iNumWaypoints) + j);
               *(g_pFloydPathMatrix + (i * g_iNumWaypoints) + j) = *(g_pFloydPathMatrix + (i * g_iNumWaypoints) + k);
            }
         }
      }
   }

   if (g_iMapType & MAP_CS)
   {
      g_pWithHostageDistMatrix = new int[g_iNumWaypoints * g_iNumWaypoints];
      g_pWithHostagePathMatrix = new int[g_iNumWaypoints * g_iNumWaypoints];

      for (i = 0; i < g_iNumWaypoints; i++)
      {
         for (j = 0; j < g_iNumWaypoints; j++)
         {
            *(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + j) = 999999;
            *(g_pWithHostagePathMatrix + (i * g_iNumWaypoints) + j) = -1;
         }
      }

      for (i = 0; i < g_iNumWaypoints; i++)
      {
         if (paths[i]->index[0] != -1)
         {
            p = paths[paths[i]->index[0]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[0])) = paths[i]->distance[0];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[0])) = paths[i]->index[0];
            }
         }

         if (paths[i]->index[1] != -1)
         {
            p = paths[paths[i]->index[1]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[1])) = paths[i]->distance[1];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[1])) = paths[i]->index[1];
            }
         }

         if (paths[i]->index[2] != -1)
         {
            p = paths[paths[i]->index[2]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[2])) = paths[i]->distance[2];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[2])) = paths[i]->index[2];
            }
         }

         if (paths[i]->index[3] != -1)
         {
            p = paths[paths[i]->index[3]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[3])) = paths[i]->distance[3];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[3])) = paths[i]->index[3];
            }
         }

         if (paths[i]->index[4] != -1)
         {
            p = paths[paths[i]->index[4]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[4])) = paths[i]->distance[4];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[4])) = paths[i]->index[4];
            }
         }

         if (paths[i]->index[5] != -1)
         {
            p = paths[paths[i]->index[5]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[5])) = paths[i]->distance[5];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[5])) = paths[i]->index[5];
            }
         }

         if (paths[i]->index[6] != -1)
         {
            p = paths[paths[i]->index[6]];
            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[6])) = paths[i]->distance[6];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[6])) = paths[i]->index[6];
            }
         }

         if (paths[i]->index[7] != -1)
         {
            p = paths[paths[i]->index[7]];

            if ((p->flags & W_FL_NOHOSTAGE) == 0)
            {
               *(g_pWithHostageDistMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[7])) = paths[i]->distance[7];
               *(g_pWithHostagePathMatrix + (paths[i]->iPathNumber * g_iNumWaypoints) + (paths[i]->index[7])) = paths[i]->index[7];
            }
         }
      }

      for (i = 0; i < g_iNumWaypoints; i++)
         *(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + i) = 0;

      for (k = 0; k < g_iNumWaypoints; k++)
      {
         for (i = 0; i < g_iNumWaypoints; i++)
         {
            for (j = 0; j < g_iNumWaypoints; j++)
            {
               if (*(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + k) + *(g_pWithHostageDistMatrix + (k * g_iNumWaypoints) + j)
                   < (*(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + j)))
               {
                  *(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + j) = *(g_pWithHostageDistMatrix + (i * g_iNumWaypoints) + k) + *(g_pWithHostageDistMatrix + (k * g_iNumWaypoints) + j);
                  *(g_pWithHostagePathMatrix + (i * g_iNumWaypoints) + j) = *(g_pWithHostagePathMatrix + (i * g_iNumWaypoints) + k);
               }
            }
         }
      }
   }

   // Free up the hostage distance matrix
   if (g_pWithHostageDistMatrix != NULL)
      delete [](g_pWithHostageDistMatrix);
   g_pWithHostageDistMatrix = NULL;

   g_cKillHistory = 0;

   return;
}


int GetPathDistance (int iSourceWaypoint, int iDestWaypoint)
{
   return (*(g_pFloydDistanceMatrix + (iSourceWaypoint * g_iNumWaypoints) + iDestWaypoint));
}


// Return the most distant waypoint which is seen from the Bot to
// the Target and is within iCount
int GetAimingWaypoint (bot_t *pBot, Vector vecTargetPos, int iCount)
{
   if (pBot->curr_wpt_index == -1)
      pBot->curr_wpt_index = WaypointFindNearestToMove (pBot->pEdict->v.origin);

   int iSourceIndex = pBot->curr_wpt_index;
   int iDestIndex = WaypointFindNearestToMove (vecTargetPos);
   int iCurrCount = 0;
   int iBestIndex = iSourceIndex;
   PATHNODE *pStartNode, *pNode;

   pNode = new PATHNODE;
   pNode->iIndex = iDestIndex;
   pNode->NextNode = NULL;
   pStartNode = pNode;

   while (iDestIndex != iSourceIndex)
   {
      iDestIndex = *(g_pFloydPathMatrix + (iDestIndex * g_iNumWaypoints) + iSourceIndex);

      if (iDestIndex < 0)
         break;

      pNode->NextNode = new PATHNODE;
      pNode = pNode->NextNode;
      pNode->iIndex = iDestIndex;
      pNode->NextNode = NULL;

      if (WaypointIsVisible (pBot->curr_wpt_index, iDestIndex))
      {
         iBestIndex = iDestIndex;
         break;
      }
   }

   while (pStartNode != NULL)
   {
      pNode = pStartNode->NextNode;
      delete pStartNode;
      pStartNode = pNode;
   }

   return (iBestIndex);
}


PATHNODE *FindShortestPath (int iSourceIndex, int iDestIndex, bool *bValid)
{
   PATHNODE *StartNode, *Node;
   Node = new PATHNODE;
   Node->iIndex = iSourceIndex;
   Node->NextNode = NULL;
   StartNode = Node;
   *bValid = FALSE;

   while (iSourceIndex != iDestIndex)
   {
      iSourceIndex = *(g_pFloydPathMatrix + (iSourceIndex * g_iNumWaypoints) + iDestIndex);

      if (iSourceIndex < 0)
         return (StartNode);

      Node->NextNode = new PATHNODE;
      Node = Node->NextNode;
      Node->iIndex = iSourceIndex;
      Node->NextNode = NULL;
   }

   *bValid = TRUE;

   return (StartNode);
}


// Test function to view the calculated A* Path
void TestAPath (bot_t *pBot, int iSourceIndex, int iDestIndex, unsigned char byPathType)
{
   PATHNODE *root;
   PATHNODE *path, *p;

   g_iSearchGoalIndex = iDestIndex;

   // allocate and setup the root node
   root = new PATHNODE;

   root->iIndex = iSourceIndex;
   root->parent = NULL;
   root->NextNode = NULL;
   root->prev = NULL;
   root->g = 0;
   root->h = hfunctionSquareDist (root);
   root->f = root->g + root->h;
   root->id = 0;
   root->depth = 0;
   root->state = OPEN;

   if (byPathType == 1)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
         path = AStarSearch (root, gfunctionKillsDistT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else if (BotHasHostage (pBot))
         path = AStarSearch (root, gfunctionKillsDistCTWithHostage, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else
         path = AStarSearch (root, gfunctionKillsDistCT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
   }
   else
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
         path = AStarSearch (root, gfunctionKillsT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else if (BotHasHostage (pBot))
         path = AStarSearch (root, gfunctionKillsCTWithHostage, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else
         path = AStarSearch (root, gfunctionKillsCT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
   }

   // A* returned failure
   if (path == NULL)
      UTIL_HostPrint ("NO PATH FOUND!\n");

   // otherwise, we had a successful search
   p = path;

   Vector vecSource;
   Vector vecDest;

   while (p != NULL)
   {
      vecSource = paths[p->iIndex]->origin;
      p = (PATHNODE *) p->NextNode;

      if ((p != NULL) && !FNullEnt (pBot->pEdict))
      {
         vecDest = paths[p->iIndex]->origin;
         MESSAGE_BEGIN (MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, NULL, pBot->pEdict);
         WRITE_BYTE (TE_SHOWLINE);
         WRITE_COORD (vecSource.x);
         WRITE_COORD (vecSource.y);
         WRITE_COORD (vecSource.z);
         WRITE_COORD (vecDest.x);
         WRITE_COORD (vecDest.y);
         WRITE_COORD (vecDest.z);
         MESSAGE_END ();
      }
   }

   // delete the nodes on the path (which should delete root as well)
   while (path != NULL)
   {
      p = (PATHNODE *) path->NextNode;
      delete (path);
      path = p;
   }

   return;
}


PATHNODE *FindLeastCostPath (bot_t *pBot, int iSourceIndex, int iDestIndex)
{
   PATHNODE *root;
   PATHNODE *path;

   if ((iDestIndex > g_iNumWaypoints - 1) || (iDestIndex < 0))
      return (NULL);
   else if ((iSourceIndex > g_iNumWaypoints - 1) || (iSourceIndex < 0))
      return (NULL);

   g_iSearchGoalIndex = iDestIndex;

   // allocate and setup the root node
   root = new PATHNODE;

   root->iIndex = iSourceIndex;
   root->parent = NULL;
   root->NextNode = NULL;
   root->prev = NULL;
   root->g = 0;
   root->h = hfunctionSquareDist (root);
   root->f = root->g + root->h;
   root->id = 0;
   root->depth = 0;
   root->state = OPEN;

   if (pBot->byPathType == 1)
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
         path = AStarSearch (root, gfunctionKillsDistT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else if (BotHasHostage (pBot))
         path = AStarSearch (root, gfunctionKillsDistCTWithHostage, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else
         path = AStarSearch (root, gfunctionKillsDistCT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
   }
   else
   {
      if (pBot->bot_team == TEAM_CS_TERRORIST)
         path = AStarSearch (root, gfunctionKillsT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else if (BotHasHostage (pBot))
         path = AStarSearch (root, gfunctionKillsCTWithHostage, hfunctionSquareDist, goal, makeChildren, nodeEqual);
      else
         path = AStarSearch (root, gfunctionKillsCT, hfunctionSquareDist, goal, makeChildren, nodeEqual);
   }

   // A* returned failure
   if (path == NULL)
      UTIL_HostPrint ("Waypoint Problem! No path found!\n");

   // otherwise, we had a successful search
   return (path);
}


// This is a general A* function, so the user defines all of the
// necessary function calls for calculating path costs and generating
// the children of a particular node.
//
// root: Node*, root node from which to begin the search.
//
// gcalc: Takes a Node* as argument and returns a double indicating
// the g value (cost from initial state).
//
// hcalc: Takes a Node* as argument and returns a double indicating
// the h value (estimated cost to the goal).
//
// goalNode: Takes a Node* as argument and returns 1 if the node is
// the goal node, 0 otherwise.
//
// children: Takes a Node* as argument and returns a linked list of
// the children of that node, or NULL if there are none.
//
// nodeEqual: Takes two Node* as arguments and returns a 1 if the
// nodes are equivalent states, 0 otherwise.
//
// The function returns a Node*, which is the root node of a linked
// list (follow the "next" fields) that specifies the path from the
// root node to the goal node.

PATHNODE *AStarSearch (PATHNODE *root, int (*gcalc) (PATHNODE *), int (*hcalc) (PATHNODE *),
                       int (*goalNode) (PATHNODE *), PATHNODE * (*children) (PATHNODE *),
                       int (*nodeEqual) (PATHNODE *, PATHNODE *))
{
   PATHNODE *openList;
   PATHNODE *closedList;
   PATHNODE *current;
   PATHNODE *childList;
   PATHNODE *curChild;
   PATHNODE *p, *q;
   PATHNODE *path;
   static int gblID = 1;
   static int gblExpand = 0;

   // generate the open list
   openList = NULL;

   // generate the closed list
   closedList = NULL;

   // put the root node on the open list
   root->NextNode = NULL;
   root->prev = NULL;
   openList = root;

   while (openList != NULL)
   {
      // remove the first node from the open list, as it will always be sorted

      current = openList;
      openList = (PATHNODE *) openList->NextNode;

      if (openList != NULL)
         openList->prev = NULL;

      gblExpand++;

      // is the current node the goal node?
      if (goalNode (current))
      {
         // build the complete path to return
         current->NextNode = NULL;
         path = current;
         p = (PATHNODE *) current->parent;

         //printf ("Goal state reached with %d nodes created and %d nodes expanded\n", gblID, gblExpand);

         while (p != NULL)
         {
            // remove the parent node from the closed list (where it has to be)
            if (p->prev != NULL)
               ((PATHNODE *) p->prev)->NextNode = p->NextNode;

            if (p->NextNode != NULL)
               ((PATHNODE *) p->NextNode)->prev = p->prev;

            // check if we're romoving the top of the list
            if (p == closedList)
               closedList = (PATHNODE *)p->NextNode;

            // set it up in the path
            p->NextNode = path;
            path = p;

            p = (PATHNODE *) p->parent;
         }

         // now delete all nodes on OPEN
         while (openList != NULL)
         {
            p = (PATHNODE *) openList->NextNode;
            delete (openList);
            openList = p;
         }

         // now delete all nodes on CLOSED
         while (closedList != NULL)
         {
            p = (PATHNODE *) closedList->NextNode;
            delete (closedList);
            closedList = p;
         }

         // now return the path
         return (path);
      }

      // now expand the current node
      childList = children (current);

      // insert the children into the OPEN list according to their f values
      while (childList != NULL)
      {
         curChild = childList;
         childList = (PATHNODE *) childList->NextNode;

         // set up the rest of the child node
         curChild->parent = current;
         curChild->state = OPEN;
         curChild->depth = current->depth + 1;
         curChild->id = gblID++;
         curChild->NextNode = NULL;
         curChild->prev = NULL;

         // calculate the f value as f = g + h
         curChild->g = gcalc (curChild);
         curChild->h = hcalc (curChild);
         curChild->f = curChild->g + curChild->h;

         // forbidden value for g ?
         if (curChild->g == -1)
         {
            curChild->g = 9e+99;
            curChild->h = 9e+99;
            curChild->f = 9e+99; // max out all the costs for this child
         }

         // test whether the child is in the closed list (already been there)
         if (closedList != NULL)
         {
            p = closedList;

            while (p != NULL)
            {
               if (nodeEqual (p, curChild))
               {
                  // if so, check if the f value is lower
                  if (p->f <= curChild->f)
                  {
                     // if the f value of the older node is lower, delete the new child
                     delete (curChild);
                     curChild = NULL;
                     break;
                  }
                  else
                  {
                     // the child is a shorter path to this point, delete p from the closed list
                     // This works so long as the new child is put in the OPEN list.
                     // Another solution is to just update all of the descendents of this node
                     // with the new f values.
                     if (p->prev != NULL)
                        ((PATHNODE *) p->prev)->NextNode = p->NextNode;

                     if (p->NextNode != NULL)
                        ((PATHNODE *) p->NextNode)->prev = p->prev;

                     if (p == closedList)
                        closedList = (PATHNODE *) p->NextNode;

                     delete (p);
                     break;
                  }
               }

               p = (PATHNODE *) p->NextNode;
            }
         }

         if (curChild != NULL)
         {
            // check if the child is already on the open list
            p = openList;

            while (p != NULL)
            {
               if (nodeEqual (p, curChild))
               {
                  // child is on the OPEN list
                  if (p->f <= curChild->f)
                  {
                     // child is a longer path to the same place so delete it
                     delete (curChild);
                     curChild = NULL;
                     break;
                  }
                  else
                  {
                     // child is a shorter path to the same place, remove the duplicate node
                     if (p->prev != NULL)
                        ((PATHNODE *) p->prev)->NextNode = p->NextNode;

                     if (p->NextNode != NULL)
                        ((PATHNODE *) p->NextNode)->prev = p->prev;

                     if (p == openList)
                        openList = (PATHNODE *) p->NextNode;

                     break;
                  }
               }

               p = (PATHNODE *)p->NextNode;
            }

            if (curChild != NULL)
            {
               // now insert the child into the list according to the f values
               p = openList;
               q = p;

               while (p != NULL)
               {
                  if (p->f >= curChild->f)
                  {
                     // insert before p
                     // test head case

                     if (p == openList)
                        openList = curChild;

                     // insert the node
                     curChild->NextNode = p;
                     curChild->prev = p->prev;
                     p->prev = curChild;

                     if (curChild->prev != NULL)
                        ((PATHNODE *) curChild->prev)->NextNode = curChild;
                     break;
                  }

                  q = p;
                  p = (PATHNODE *)p->NextNode;
               }

               if (p == NULL)
               {
                  // insert at the end
                  if (q != NULL)
                  {
                     q->NextNode = curChild;
                     curChild->prev = q;
                  }
                  else
                     openList = curChild; // insert at the beginning
               }
            } // end if child is not NULL (better duplicate on OPEN list)
         } // end if child is not NULL (better duplicate on CLOSED list)
      } // end of child list loop

      // put the current node onto the closed list
      current->NextNode = closedList;
      if (closedList != NULL)
         closedList->prev = current;
      closedList = current;

      current->prev = NULL;
      current->state = CLOSED;
   }

   // if we got here, then there is no path to the goal

   // delete all nodes on CLOSED since OPEN is now empty
   while (closedList != NULL)
   {
      p = (PATHNODE *) closedList->NextNode;
      delete (closedList);
      closedList = p;
   }

   return (NULL);
}



// Least Kills and Number of Nodes to Goal for a Team
int gfunctionKillsDistT (PATHNODE* p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;
   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam0Damage + g_cKillHistory;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam0Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * (g_iDangerFactor * 2 / 3));
}


int gfunctionKillsDistCT (PATHNODE *p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;
   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam1Damage + g_cKillHistory;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam1Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * (g_iDangerFactor * 2 / 3));
}


int gfunctionKillsDistCTWithHostage (PATHNODE *p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;

   if (paths[iThisIndex]->flags & W_FL_NOHOSTAGE)
      return (-1);

   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam1Damage + g_cKillHistory;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam1Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * g_iDangerFactor);
}


// Least Kills to Goal for a Team
int gfunctionKillsT (PATHNODE* p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;
   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam0Damage;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam0Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * (g_iDangerFactor * 2 / 3));
}


int gfunctionKillsCT (PATHNODE *p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;
   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam1Damage;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam1Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * (g_iDangerFactor * 2 / 3));
}


int gfunctionKillsCTWithHostage (PATHNODE *p)
{
   int i;

   if (p == NULL)
      return (-1);

   int iThisIndex = p->iIndex;

   if (paths[iThisIndex]->flags & W_FL_NOHOSTAGE)
      return (-1);

   int iCost = (pBotExperienceData + (iThisIndex * g_iNumWaypoints) + iThisIndex)->uTeam1Damage;
   int iNeighbour;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      iNeighbour = paths[iThisIndex]->index[i];

      if (iNeighbour != -1)
         iCost += (float) (pBotExperienceData + (iNeighbour * g_iNumWaypoints) + iNeighbour)->uTeam1Damage * 0.3;
   }

   if (paths[iThisIndex]->flags & W_FL_CROUCH)
      iCost *= 1.5;

   return (iCost * g_iDangerFactor);
}


// No heurist (greedy) !!
int hfunctionNone (PATHNODE *p)
{
   if (p == NULL)
      return (-1);

   return (0);
}


// Square Distance Heuristic
int hfunctionSquareDist (PATHNODE *p)
{
   int deltaX = abs ((int) paths[g_iSearchGoalIndex]->origin.x - (int) paths[p->iIndex]->origin.x);
   int deltaY = abs ((int) paths[g_iSearchGoalIndex]->origin.y - (int) paths[p->iIndex]->origin.y);
   int deltaZ = abs ((int) paths[g_iSearchGoalIndex]->origin.z - (int) paths[p->iIndex]->origin.z);

   return (deltaX + deltaY + deltaZ);
}


// define the goalNode function
int goal (PATHNODE *p)
{
   if (p->iIndex == g_iSearchGoalIndex)
      return (1);

   return (0);
}


// define the children function
PATHNODE *makeChildren (PATHNODE *parent)
{
   int i;
   PATHNODE *p, *q;

   // initialize the return list
   q = NULL;
   int iParentIndex = parent->iIndex;

   for (i = 0; i < MAX_PATH_INDEX; i++)
   {
      if (paths[iParentIndex]->index[i] != -1)
      {
         p = new PATHNODE;
         p->iIndex = paths[iParentIndex]->index[i];
         p->parent = parent;
         p->NextNode = q;
         q = p;
      }
   }

   return (q);
}


// Test for node equality
int nodeEqual (PATHNODE *a, PATHNODE *b)
{
   if ((a == NULL) && (b == NULL))
      return (1);
   else if (a == NULL)
      return (0);
   else if (b == NULL)
      return (0);

   return (a->iIndex == b->iIndex);
}
