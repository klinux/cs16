
/***************************************************************************/ 
/*                          Echo Commands v1.1                             */ 
/*                                             by Downtown1                */ 
/***************************************************************************/ 
/* This plugin will read a file for console commands, and  each time       */ 
/* someone uses a command it will echo it to the people and/or admins.     */ 

/*   Come to 208.254.35.18 if you wish to see it in action first.          */ 
/*                                                                         */ 
/* To use this plugin, simply make an echocmd.txt in your addons/amxmodx/  */ 
/* folder and put the cmds there, separating them with a line break.       */ 
/* I advise to put it all the way in the top of plugins.ini as it has to   */ 
/* intercept all the commands before they are stopped.                     */ 
/* 
========================= Version History =================================== 
*** 1.1  - when a command is used on a player it gives you the players full 
        name, not just a part of it 
*** 1.0  - first version of plugin: features command echoing 
         - returns person who uses command, the command, and whatever client 
           typed in after the command 
*/ 

/* 
== In-game example == 
Let's say you use "amx_vote_kick downtown" (or any command listed in echocmd.txt) 

In-game (if you have access to admin_chat) it would echo on your screen the following: 
YourName has used the command: amx_vote_kick Downtown1 

If you were to use "amx_slap downtown 50" it would show 
YourName has used the command: amx_slap Downtown1 50 
*/ 

#include <amxmodx> 

new cmdlist[128][64] 
new cmdcount = 0 

public readfile () 
{ 
   new txtlength, txtline 
   new txt[64] 

   if (file_exists("addons/amxmodx/echocmd.txt")) 
   { 
      while ((txtline = read_file("addons/amxmodx/echocmd.txt", txtline, txt, 63, txtlength))) 
      { 
         copy (cmdlist[txtline], 63, txt) 
         cmdcount++ 
      } 
   } 

   return PLUGIN_CONTINUE 
} 

public echocmd(id) 
{ 
   new cmd[32] 
   new param1[32] 
   new comments[64], comments2[64] 
   new echo[128] 
   new get_ename[32] 
   new get_vname[32] 
   new get_eplayers[32] 
   new get_numplayers, playerid 

   get_user_name (id, get_ename, 31) 
   get_players(get_eplayers, get_numplayers, "c") 

   read_argv(0, cmd,31) 
   read_args(comments, 63) 
   parse(comments, param1, 31) 


   new bool:firstcomment = false 
   new num2 = 0 
   for (new num = 0; num<strlen(comments); num++) 
   { 
       if(firstcomment == true) 
      { 
         comments2[num2] = comments[num] 
         num2++ 
         continue 
      } 
       if(comments[num]==' ') 
         firstcomment = true 
   } 

   if(param1[1]) 
   { 
      playerid = find_player("bl",param1) 
      get_user_name(playerid, get_vname, 31) 
   } 

   format (echo, 127, "%s has used command: %s %s %s %s", get_ename, cmd, playerid ? get_vname : param1, comments2) 
   for (new i=0; i < get_numplayers; i++) 
   { 
      if (get_user_flags(get_eplayers[i])&ADMIN_CHAT) 
      { 
         client_print(get_eplayers[i], print_chat, echo) 
      } 
   } 

   return PLUGIN_CONTINUE 
} 

public plugin_init() 
{ 
   register_plugin("Echo Commands","1.1","Downtown1") 
   readfile() 
   for (new i=0; i<cmdcount; i++) 
   { 
      register_clcmd(cmdlist[i], "echocmd") 
   } 
   return PLUGIN_CONTINUE 
} 


