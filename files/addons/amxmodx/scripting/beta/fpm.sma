/* AMXMOD script. 
* 
* (c) Copyright 2000-2002, Rich - This file is provided as is (no warranties). 
* 
* Alive FPM 1.0 
* 
* - Shows your Frags Per Minute 
* 
* - Only Counts time your alive and playing 
* 
* - Shows top 3 rankings every 60 seconds 
*/ 

#include <amxmodx> 

new topid[4], showfpm[33], alivetime[33], Float:topfpm[4] 

public plugin_init() 
{ 
  register_plugin("FPM", "1.0", "Rich") 
  register_cvar("amx_fpm", "1") 
  register_clcmd("say /fpmon","fpm_on") 
  register_clcmd("say_team /fpmon","fpm_on") 
  register_clcmd("say /fpmoff","fpm_off") 
  register_clcmd("say_team /fpmoff","fpm_off")   
  set_task(1.0,"find_fpm",0,"",0,"b") 
  set_task(60.0,"show_top",0,"",0,"b") 
} 

public find_fpm() 
{ 
//  if (!(get_cvar_num("amx_fpm"))) 
//  { 
//    return PLUGIN_CONTINUE 
//  } 

  set_hudmessage(50, 0, 150, -1.0, 0.04, 0, 1.0, 5.0, 0.1, 0.0, 11) 

  topid[1] = 0 
  topid[2] = 0 
  topid[3] = 0 
  topfpm[1] = 0.0 
  topfpm[2] = 0.0 
  topfpm[3] = 0.0 

  new playernum, players[32] 
  get_players(players,playernum) 

  for(new a = 0; a < playernum; ++a) 
  { 
    if (is_user_alive(players[a]) == 1) 
    { 
      ++alivetime[players[a]] 
    } 

    new Float:fpm = get_user_frags(players[a]) * 60 / float(alivetime[players[a]]) 

    if (showfpm[players[a]] && (!(get_cvar_num("amx_fpm")))) 
    { 
      set_hudmessage(50, 0, 150, -1.0, 0.04, 0, 1.0, 5.0, 0.1, 0.0, 11) 
      show_hudmessage(players[a],"KILLS: %i - SECONDS: %i - FPM: %.2f", get_user_frags(players[a]), alivetime[players[a]], fpm) 
    } 

    if (fpm > topfpm[1]) 
    { 
      topid[3] = topid[2] 
      topid[2] = topid[1] 
      topid[1] = players[a] 
      topfpm[3] = topfpm[2] 
      topfpm[2] = topfpm[1] 
      topfpm[1] = fpm 
    } 
    else if (fpm >= topfpm[2] && players[a] != topid[1]) 
    { 
      topid[3] = topid[2] 
      topid[2] = players[a] 
      topfpm[3] = topfpm[2] 
      topfpm[2] = fpm 
    } 
    else if (fpm >= topfpm[3] && players[a] != topid[1] && players[a] != topid[2]) 
    { 
      topid[3] = players[a] 
      topfpm[3] = fpm 
    } 
  } 
  return PLUGIN_CONTINUE 
} 

public show_top(id) 
{ 
  if (!(get_cvar_num("amx_fpm"))) 
  { 
    return PLUGIN_CONTINUE 
  } 
  new namea[33], nameb[33], namec[33] 
  get_user_name(topid[1], namea, 32) 
  get_user_name(topid[2], nameb, 32) 
  get_user_name(topid[3], namec, 32) 
  client_print(0, print_chat, "FPM RANKING: 1. %s (%.2f) - 2. %s (%.2f) - 3. %s (%.2f)", namea,  topfpm[1], nameb, topfpm[2], namec, topfpm[3]) 
  return PLUGIN_CONTINUE 
} 

public fpm_on(id) 
{ 
  showfpm[id] = true 
  return PLUGIN_CONTINUE 
} 

public fpm_off(id) 
{ 
  showfpm[id] = false 
  return PLUGIN_CONTINUE 
} 

public client_disconnect(id) 
{ 
  showfpm[id] = false 
  return PLUGIN_CONTINUE 
} 
