/*------------------------------------------------------------------------------ 
Admin Godmode II by v!p3r.gTs - sets godmode on players. 
This file is provided as is (no warranties). 
edited by _KaszpiR_ to enable all players godmode, then 2 cvars are useless
Console Commands: 
   amx_gm <authid, nick, @T, @CT, @All or #userid> 
   amx_ungm <authid, nick, @T, @CT, @All or #userid> 

possible abbreviations
@CT = @C, @c
@T = @t
@All = @A, @a

Cvar: 
   amx_godmode_last <0=one round 1=forever> - default value is set to 0. 

Examples: 
   amx_gm @T      - set godmode on all terrorists for one round if amx_godmode_last is set to 0. 
   amx_gm @CT      - set godmode on all CT for one round if amx_godmode_last is set to 0. 
   amx_gm @A      - set godmode on all players for one round if amx_godmode_last is set to 0. 
   amx_gm player  - set godmode on player forever if amx_godmode_last is set to 1. 
   amx_ungm #4    - remove godmode from player whose userid is 4. 
   amx_ungm 12345 - remove godmode from player whose authid is 12345. 
------------------------------------------------------------------------------*/ 

#include <amxmodx> 
#include <amxmisc> 
#include <fun> 

new bool:godmodePlayer[33] 

public plugin_init() 
{ 
   register_plugin("Admin Godmode II","1.0","v!p3.gTs") 
   register_event("ResetHUD", "newRound", "be") 
   register_concmd("amx_gm", "set_godmode", ADMIN_LEVEL_A, "<authid, nick, @T, @CT, @All or #userid>") 
   register_concmd("amx_ungm", "remove_godmode", ADMIN_LEVEL_A, "<authid, nick, @T, @CT, @All or #userid>") 
   register_cvar("amx_godmode_last", "0") 
} 

public set_godmode(id, level, cid) 
{ 
   if (!cmd_access(id, level, cid, 2)) 
      return PLUGIN_HANDLED 
   new arg[32], admin_name[32], admin_authid[32] 
   get_user_name(id, admin_name, 31) 
   get_user_authid(id, admin_authid, 31) 
   read_argv(1, arg, 31) 
   if (arg[0] == '@') {
      new players[32], target_team[32], inum 
      if(arg[1] == 'T' || arg[1] == 't') { 
         get_players(players, inum, "ae", "TERRORIST") 
         target_team = "terrorists" 
      } 
      else if(arg[1] == 'C' || arg[1] == 'c') { 
         get_players(players, inum, "ae", "CT") 
         target_team = "counter-terrorists" 
      } 
      else if(arg[1] == 'A' || arg[1] == 'a') { 
         get_players(players, inum, "ae", "CT") 
         target_team = "players" 

      } 
      else { 
         console_print(id, "* Team with that name cannot be found.Use @T, @CT, @All.") 
         return PLUGIN_CONTINUE 
      } 
      if (inum == 0) { 
         console_print(id, "* No clients in such team.") 
         return PLUGIN_CONTINUE 
      } 
      for(new i = 0; i < inum; ++i) { 
         set_user_godmode(players[i], 1) 
         godmodePlayer[players[i]] = true 
      } 
      log_amx("Cmd: ^"%s<%d><%s><>^" set godmode on all %s", admin_name, get_user_userid(id), admin_authid, target_team) 
      switch(get_cvar_num("amx_show_activity")) { 
         case 2: client_print(0, print_chat, "ADMIN %s: set godmode on all %s.", admin_name, target_team) 
         case 1: client_print(0, print_chat, "ADMIN: set godmode on all %s.", target_team) 
      } 
      console_print(id, "* Set godmode on all %s.", target_team) 
   } 
   else { 
      new player = cmd_target(id, arg, 2) 
      if (!player) 
         return PLUGIN_HANDLED 
      set_user_godmode(player, 1) 
      godmodePlayer[player] = true 
      new target_player[32], target_authid[32] 
      get_user_name(player, target_player, 31) 
      get_user_authid(player, target_authid, 31) 
      log_amx("Cmd: ^"%s<%d><%s><>^" set godmode on ^"%s<%d><%s><>^"", admin_name, get_user_userid(id), admin_authid, target_player, get_user_userid(player), target_authid) 
      switch(get_cvar_num("amx_show_activity")) { 
         case 2: client_print(0, print_chat, "ADMIN %s: set godmode on %s.", admin_name, target_player) 
         case 1: client_print(0, print_chat, "ADMIN: set godmode on %s.", target_player) 
      } 
      console_print(id, "* Set godmode on client %s.", target_player) 
   } 
   return PLUGIN_CONTINUE 
} 

public remove_godmode(id, level, cid) 
{ 
   if (!cmd_access(id, level, cid, 2)) 
      return PLUGIN_HANDLED 
   new arg[32], admin_name[32], admin_authid[32] 
   get_user_name(id, admin_name, 31) 
   get_user_authid(id, admin_authid, 31) 
   read_argv(1, arg, 31) 
   if (arg[0] == '@') { 
      new players[32], target_team[32], inum 
      if(arg[1] == 'T' || arg[1] == 't') { 
         get_players(players, inum, "ae", "TERRORIST") 
         target_team = "terrorists" 
      } 
      else if(arg[1] == 'C' || arg[1] == 'c') { 
         get_players(players, inum, "ae", "CT") 
         target_team = "counter-terrorists" 
      } 
      else if(arg[1] == 'A' || arg[1] == 'a') { 
         get_players(players, inum, "ae", "CT") 
         target_team = "players" 
      } 
      else { 
         console_print(id, "* Team with that name cannot be found.") 
         return PLUGIN_CONTINUE 
      } 
      if (inum == 0) { 
         console_print(id, "* No clients in such team.") 
         return PLUGIN_CONTINUE
      } 
      for(new i = 0; i < inum; ++i) { 
         set_user_godmode(players[i], 0) 
         godmodePlayer[players[i]] = false 
      } 
      log_amx("Cmd: ^"%s<%d><%s><>^" removed godmode from all %s", admin_name, get_user_userid(id), admin_authid, target_team) 
      switch(get_cvar_num("amx_show_activity")) { 
         case 2: client_print(0, print_chat, "ADMIN %s: removed godmode from all %s.", admin_name, target_team) 
         case 1: client_print(0, print_chat, "ADMIN: removed godmode from all %s.", target_team) 
      } 
      console_print(id, "* Removed godmode from all %s.", target_team) 
   } 
   else { 
      new player = cmd_target(id, arg, 2) 
      if (!player) 
         return PLUGIN_HANDLED 
      set_user_godmode(player, 0) 
      godmodePlayer[player] = false 
      new target_player[32], target_authid[32] 
      get_user_name(player, target_player, 31) 
      get_user_authid(player, target_authid, 31) 
      log_amx("Cmd: ^"%s<%d><%s><>^" removed godmode from ^"%s<%d><%s><>^"", admin_name, get_user_userid(id), admin_authid, target_player, get_user_userid(player), target_authid) 
      switch(get_cvar_num("amx_show_activity")) { 
         case 2: client_print(0, print_chat, "ADMIN %s: removed godmode from %s.", admin_name, target_player) 
         case 1: client_print(0, print_chat, "ADMIN: removed godmode from %s.", target_player) 
      } 
      console_print(id, "* Removed godmode from client %s.", target_player) 
   } 
   return PLUGIN_CONTINUE
} 

public newRound(id) 
{
   if (godmodePlayer[id] && (get_cvar_num("amx_godmode_last") == 1))
      set_user_godmode(id, 1)
}
