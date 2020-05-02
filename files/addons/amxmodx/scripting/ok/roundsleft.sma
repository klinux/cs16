
new PLUGINNAME[] = "Roundsleft" 
new VERSION[] = "0.1" 
new AUTHOR[] = "jghg" 
/* 
Copyleft 2003 
http://amxmod.net/forums/viewtopic.php?p=130419 

ROUNDSLEFT 
========== 
Allows the users to "say roundsleft" and remaining rounds will be displayed. 
This is useful if you are using default hlds cvar mp_maxrounds set to some value. 
Will respond with same answer if users "say timeleft" also. 
There is also a command "amx_roundsleft" to view remaining rounds in console. 

/jghg 

HOW TO INSTALL 
============== 
1. Name this file roundsleft.sma. 
2. Compile it into roundsleft.amx. 
3. Put roundsleft.amx into amx/plugins directory. 
4. Open up amx/plugins/plugins.ini and add a line to the end saying: roundsleft.amx 
5. Done. Type reload in your server. 

HOW TO USE 
========== 
say roundsleft, say timeleft, say /roundsleft, say /timeleft 
- all these will respond with remaining rounds if mp_maxrounds is set to anything higher than 0. 

amx_roundsleft 
- displays remaining rounds in console. Works also from server console. 

VERSIONS 
======== 
0.1         First version 

*/ 

#include <amxmodx> 
#include <amxmisc> 

// Globals below 
new g_teamScore[2] 
// Globals above 

public sayRoundsLeft(id) { 
   new maxRounds = get_cvar_num("mp_maxrounds") 
   if (maxRounds) { 
      if (id) client_print(0,print_chat,"Remaining rounds: %d",maxRounds - (g_teamScore[0] + g_teamScore[1])) 
   } 
   else 
      console_print(id,"Notice: mp_maxrounds is not set") 

   return PLUGIN_CONTINUE 
} 

public conRoundsLeft(id) { 
   new maxRounds = get_cvar_num("mp_maxrounds") 
   if (maxRounds) { 
      if (id)   console_print(id,"Remaining rounds: %d",maxRounds - (g_teamScore[0] + g_teamScore[1])) 
      else server_print("Remaining rounds: %d",maxRounds - (g_teamScore[0] + g_teamScore[1])) 
   } 
   else 
      console_print(id,"Notice: mp_maxrounds is not set") 

   return PLUGIN_HANDLED 
} 

public teamScore() { 
   new team[2] 
   read_data(1,team,1) 
   g_teamScore[(team[0]=='C')? 0 : 1] = read_data(2) 
} 

public plugin_init() { 
   register_plugin(PLUGINNAME,VERSION,AUTHOR) 
   register_clcmd("say timeleft","sayRoundsLeft") 
   register_clcmd("say_team timeleft","sayRoundsLeft") 
   register_clcmd("say roundsleft","sayRoundsLeft",0,"- displays remaining rounds") 
   register_clcmd("say_team roundsleft","sayRoundsLeft",0,"- displays remaining rounds") 
   register_concmd("amx_roundsleft","conRoundsLeft",0,"- displays remaining rounds") 
   register_event("TeamScore","teamScore","a") 
} 
