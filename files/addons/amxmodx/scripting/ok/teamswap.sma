/* Version 1.0.0 By Grygrx
Name: Smart Team Swap

File: amx_teamswap.sma

Commands added:
	amx_t <authid or partial nick> [now]
	amx_ct <authid or partial nick> [now]
Purpose:
	Desire for teamchanger with a little more flexibilty.
	Defaults to swapping a person at the end of the current round if they are still alive,
	but can force a player to move instantly using the "now" flag. Players that are moved have
	one frag subtracted during the current round, but it is corrected at the begining of the
	next (see: user_kill(player, 1) ).  Should ignore limitteams and make all swaps.

Tested:
	AMX 0.9.7
	STEAM - 11/9/2003

Credits:Code theft, rearrangement, and tweakage by Grygrx
	Based on Admin Teams, Copyright 2002, PsychoGuard.
	and Bugblatter Team Change Extension - V3.4
	Some code lifted from Olo and JustinHoMi
	Thx: BMJ, FreeCode, XAD, WrG|IceMouse
*/



#include <amxmodx>
#include <amxmisc>

new changecount = 0
new movetarget[32]
new movetype[32]
new cvar_team = 0

public admin_chteam(id, level, cid)
{
   if (!cmd_access(id, level, cid, 2)) return PLUGIN_HANDLED
   new cmd[32], arg[32], arg2[32]

   read_argv(0,cmd,31)
   read_argv(1,arg,31)
   read_argv(2,arg2,31)
   new player = cmd_target(id,arg,1)
   if (!player) return PLUGIN_HANDLED
   if ( (containi(arg2, "now") >= 0) || (!is_user_alive(player)) )
   {
	   new svgui[2]
   	   new param[3]
	   cvar_team = get_cvar_num("mp_limitteams")
   	   set_cvar_num("mp_limitteams",0)
	   user_kill(player, 1)
	   get_user_info(player, "_vgui_menus", svgui, 1)
	   new bool:vgui = (equal(svgui, "1")) ? true : false
	   set_user_info(player, "_vgui_menus", "0")
	   param[0] = player
	   param[1] = (cmd[4]=='t') ? 1 : 2
	   param[2] = (vgui) ? 1 : 0
	   set_task(0.2, "teamswap", 0, param, 3)
	   client_print(player, print_notify, "Admin has transfered you to the other team")
	   set_cvar_num("mp_limitteams",cvar_team)
	   return PLUGIN_HANDLED
   }
   else //player is alive, soft move
   {
	  for (new i=0; i<changecount; i++)
	  {
	  	//Someone has already tried to move the player
	  	if ( movetarget[i] == player )
	  	{
	  		console_print(id,"A move has already been requested on that player")
	  		return PLUGIN_HANDLED
	  	}
	  }
	  movetarget[changecount] = player
	  movetype[changecount] = (cmd[4]=='t') ? 1 : 2
	  changecount++
	  console_print(id,"Player will be switched at the end of the round")
	  return PLUGIN_HANDLED
   }
   return PLUGIN_HANDLED
}


public teamswap( param[] ) {
   engclient_cmd(param[0], "chooseteam")
   engclient_cmd(param[0], "menuselect", (param[1]==1) ? "1" : "2" )
   engclient_cmd(param[0], "menuselect", "5")
   client_cmd(param[0], "slot0");
   set_user_info(param[0], "_vgui_menus", (param[3]==1) ? "1" : "0" )
}

public event_RoundEnd()
{
   if (changecount)
   {
   	cvar_team = get_cvar_num("mp_limitteams")
   	set_cvar_num("mp_limitteams",0)
   	new svgui[2]
   	new param[3]
        for (new i=0; i<changecount; i++)
        {
		get_user_info(movetarget[i], "_vgui_menus", svgui, 1)
		new bool:vgui = (equal(svgui, "1")) ? true : false
	        set_user_info(movetarget[i], "_vgui_menus", "0")
		user_kill(movetarget[i], 1)
		param[0] = movetarget[i]
		param[1] = movetype[i]
		param[2] = (vgui) ? 1 : 0
	   	set_task(0.2, "teamswap", 0, param, 3 )
		client_print(movetarget[i], print_notify, "Admin has transfered you to the other team")

        }
   	set_cvar_num("mp_limitteams",cvar_team)
   	changecount = 0
   }
}

public plugin_init()
{
   register_plugin("Smart Team Swap", "1.0.0", "Grygrx")
   register_concmd("amx_t", "admin_chteam", ADMIN_SLAY, "<authid or partial nick> [now]")
   register_concmd("amx_ct", "admin_chteam", ADMIN_SLAY, "<authid or partial nick> [now]")
   register_logevent("event_RoundEnd",2,"0=World triggered","1=Round_End")
   return PLUGIN_CONTINUE
}