
/* AMX Mod script. 
* 
* (c) Copyright 2002-2003, Shromilder 
* Made by Shromilder 
* http://shromy.free.fr 
* 
* Edited by Redmist 
* smithredmist@hotmail.com 
* 
* This file is provided as is (no warranties). 
* 
* -=[ AMX swapteams ]=- 
* 
* cya, Shromilder 
* 
* Changelog: 
   - 2.01: added standard hlds log message
*  - 2.00: fixed swap to work with clients using either vgui or old style menus 
*  -     : allows players to choose skin after swap (skins auto selected for bots) 
*  -     : bugfixes - should work 100% now.. Redmist 
*  - 1.01: added back cvars mp_limitteams 2 mp_autoteambalance 1 after restart. sy5tem 
*  - 1.00: first release 
* 
*/ 

#include <amxmodx> 
#include <amxmisc> 

new team_select_state 

public restart_round(time[]) 
{ 
   server_cmd("sv_restartround %s",time) 
   return PLUGIN_CONTINUE 
} 

public swap() 
{ 
   new playersCT[32] 
   new playersT[32] 
   new nbrCT,nbrT 
   get_players(playersCT,nbrCT,"e","CT") 
   get_players(playersT,nbrT,"e","TERRORIST") 
   for(new i = 0; i < nbrCT; i++) { 
         team_select_state = 1 
         engclient_cmd(playersCT[i], "chooseteam") 
         if (is_user_bot(playersCT[i])) { 
            engclient_cmd(playersCT[i], "menuselect", "1") 
            engclient_cmd(playersCT[i], "menuselect", "5") 
         } 
         else { 
            if(team_select_state == 1) client_cmd(playersCT[i],"slot1") 
            team_select_state = 0 
         } 
   } 
   for(new i = 0; i < nbrT; i++) { 
         team_select_state = 2 
         engclient_cmd(playersT[i], "chooseteam") 
         if (is_user_bot(playersT[i])) { 
            engclient_cmd(playersT[i], "menuselect", "2") 
            engclient_cmd(playersT[i], "menuselect", "5") 
         } 
         else { 
            if(team_select_state == 2) client_cmd(playersT[i],"slot2") 
            team_select_state = 0 
         } 
   } 
   return PLUGIN_CONTINUE 
} 

public swap_teams() 
{ 
   log_message("[AMXX] SwapTeams - Swapping teams!") 
   client_print(0,print_chat,"[AMXX] SwapTeams - Swapping teams!") 
   set_cvar_string("mp_limitteams","0") 
   set_cvar_string("mp_autoteambalance","0") 
   restart_round("1") 
   set_task(3.5,"swap") 

   set_cvar_string("mp_limitteams","0") 
   set_cvar_string("mp_autoteambalance","0") 
   return PLUGIN_CONTINUE 
} 

public vgui_auto_join(id) 
{ 
   if(team_select_state == 1) client_cmd(id,"slot2") 
   if(team_select_state == 2) client_cmd(id,"slot3") 
   team_select_state = 0 
   return PLUGIN_CONTINUE 
} 

public plugin_init() 
{ 
   register_plugin("AMX SwapTeams","2.01","Redmist") 
   register_event("VGUIMenu","vgui_auto_join","b","1=2") 
   register_concmd("amx_swapteams","swap_teams",ADMIN_LEVEL_A," - Swap teams, ct's go to terros and terros to ct") 
   return PLUGIN_CONTINUE 
} 

