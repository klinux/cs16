

/* 
   Vote Access v0.3.2 
   Copyleft 2003 by Johnny got his gun 
   http://amxmod.net/forums/viewtopic.php?t=16984 

   Requires AMX Mod v0.9.5. 

   VOTE ACCESS 
   =========== 
   This plugin lets you add ability for your users to start votes on activation/deactivation of 
   otherwise vote-systemless plugins (like my Weapon Arena plugin, example below). 
   Actually, it doesn't have to be an AMX Mod plugin command, it can be any command/cvar 
   accessible through server console. So you can makes votes to start/stop/change 
   plugins/commands/cvars/whatever with this baby. 

   This leads to two things: 
   - Server admins can add voting ability to any cvar/plugin/server command like stated above, 
   without crying to the plugin author for an update with a vote feature. 
   - Plugin authors don't need to do a voting system for their plugins ever more. 
   They can just tell admins to use this plugin for their voting needs. 


   USAGE 
   ===== 
    
   * amx_voteaccess <trigger> <question> <Option 1> <Command 1> <Option 2> <Command 2> 
   * amx_voteaccessbreak 
   * amx_voteaccessmenu 

   Put the command amx_voteaccess in your amx.cfg (not server.cfg, it won't load after map change!) like this (example): 
   amx_voteaccess "weaponarena" "Weapon Arena?" "Yes please" "amx_weaponarena random" "No thank you" "amx_weaponarena off" 
   This will add the ability for your users of saying "vote weaponarena", and a vote menu will show to all 
   players (not bots), like this in this case: 
    
   Time to choose! 

   Weapon Arena? 

   1. Yes please 
   2. No thank you 

   And after VOTETIME (normally 15 seconds) the results of the voting will be summed up, and 
   if either side won, that command will get executed on server console. If 1. wins, it will execute 
   in this case "amx_weaponarena random". If 2 wins, "amx_weaponarena off" will get executed. 
   If no one votes within time, no command will be executed, this is also true if the results are exactly equal. 

   The command amx_voteaccessbreak breaks an ongoing voting. It can be used by server console, or by a client 
   with ADMIN_VOTE access. 

   This plugin uses the following cvars that are by default already set with AMX: 
   amx_vote_time - time in seconds until votes are counted and winning command executed. 
   amx_vote_answers - set this to 1 to display who votes for what. 
   amx_vote_delay - time in seconds that must pass between two votings. Note that admin 
   can use the amx_voteaccessmenu to call new votes as often has he want. :-) 

More examples: 

amx_voteaccess "ff" "Friendly fire?" "Turn it on!" "mp_friendlyfire 1" "Turn it off!" "mp_friendlyfire 0" 
Then you can start this vote by saying: vote ff 
amx_voteaccess "lowgravity" "Low gravity?" "Let's play astronauts!" "sv_gravity 100" "No please, I had enough of space trips, put things to normal." "sv_gravity 800" 
Then you can start this vote by saying: vote lowgravity 
Easy, huh?


   Releases: 
   2003-06-23   version 0.1: 
            First version 

   2003-06-24   version 0.2: 
            New command is amx_voteaccessmenu - any client with ADMIN_VOTE 
            access can access the menu, which contains all the votings stored 
            with amx_voteaccess command. 

            amx_voteaccessbreak 
            Changed this command's access level to ADMIN_VOTE. 

   2003-06-27   version 0.3: 
            If you have one of my other plugins, Chat Responder, 
            the trigger will automatically be added to Chat Responder's 
            list of words it will hear. If someone type that trigger 
            without using the "vote" part before it, Chat Responder will 
            respond with that you can initiate a vote on that by typing 
            "vote <trigger>". 

            Now uses the following cvars for controlling different things: 
            amx_vote_time - The time in seconds until votes are counted and command 
            executed. 
            amx_vote_answers - Set this to 1 to display what each client 
            votes for. 
            amx_vote_delay - Time in seconds that must pass between votes. 
            Admin can still call up new votes whenever he wants with 
            amx_voteaccessmenu. 
            Note that these cvars are default with AMX, so you have them 
            probably already set. 

   2003-07-29   version 0.3.1: 
            Minor tweak. Will now count votes as soon as everyone voted. 
            You will also get a message of voting to late if you do. 
   2003-07-29   version 0.3.2: 
            "Time to choose" sound of gman is added. 


   TO DO 
   ===== 
   Make it possible to have more than two options. 

*/ 

#include <amxmodx> 
#include <amxmisc> 

// Globals below 
#define MAXVOTES 32 
#define TRIGGERLENGTH 32 
#define QUESTIONLENGTH 64 
#define OPTIONTEXTLENGTH 32 
#define OPTIONLENGTH 32 
#define VOTETASKID 135 

new g_votesCount 
new triggers[MAXVOTES][TRIGGERLENGTH] 
new questions[MAXVOTES][QUESTIONLENGTH] 
new optiontext1[MAXVOTES][OPTIONTEXTLENGTH] 
new option1[MAXVOTES][OPTIONLENGTH] 
new optiontext2[MAXVOTES][OPTIONTEXTLENGTH] 
new option2[MAXVOTES][OPTIONLENGTH] 
new option1result, option2result 
new bool:voteInProgress = false 
new idpage[33] 
new bool:delay = false 
new g_votingPlayers 
new g_currentVote 
// Globals above 

public addvoteaccess() { 
   if (read_argc() != 7) { 
      server_print("[AMXX] Vote Access - Error, usage: amx_voteaccess ^"Trigger^" ^"Question^" ^"Option text 1^" ^"Option command 1^" ^"Option text 2^" ^"Option command 2^"") 
      log_message("[AMXX] Vote Access - Error, usage: amx_voteaccess ^"Trigger^" ^"Question^" ^"Option text 1^" ^"Option command 1^" ^"Option text 2^" ^"Option command 2^"") 
      return PLUGIN_CONTINUE 
   } 

   new argLine[256] 
   read_args(argLine,255) 

   if (g_votesCount >= MAXVOTES) { 
      server_print("[AMXX] Vote Access - Error: You have too many votes already stored. Will not add another. (%s)",argLine) 
      log_message("[AMXX] Vote Access - Error: You have too many votes already stored. Will not add another. (%s)",argLine) 
      return PLUGIN_HANDLED 
   } 
    
   // Trigger must be unique. 
   new trigger[TRIGGERLENGTH] 
   parse(argLine,trigger,TRIGGERLENGTH - 1) 
   for (new i = 0;i < g_votesCount;i++) { 
      if (equali(triggers[i],trigger)) { 
         server_print("[AMXX] Vote Access - Error: Trigger ^"%s^" already exists.",triggers[i]) 
         log_message("[AMXX] Vote Access - Error: Trigger ^"%s^" already exists.",triggers[i]) 
         return PLUGIN_HANDLED 
      } 
   } 

   parse(argLine,triggers[g_votesCount],TRIGGERLENGTH - 1,questions[g_votesCount],QUESTIONLENGTH - 1,optiontext1[g_votesCount],OPTIONTEXTLENGTH - 1,option1[g_votesCount],OPTIONLENGTH,optiontext2[g_votesCount],OPTIONTEXTLENGTH - 2,option2[g_votesCount],OPTIONLENGTH) 

   for (new i = 0, pluginName[30], pluginsCount = get_pluginsnum(), result, bool:foundCR = false;i < pluginsCount && !foundCR;++i) { 
      result = get_plugin(i,"",0,pluginName,29,"",0,"",0,"",0) 
      //server_print("Plugin: %s",pluginName) 
      if (equal("Chat Responder",pluginName)) { 
         foundCR = true 
         //server_print("Found Chat Responder on i = %d! Adding trigger to responder...",i) 
         server_cmd("amx_chatrespond ^"%s^" ^"Did you know you can say 'vote %s' to init a vote for: %s^"",triggers[g_votesCount],triggers[g_votesCount],questions[g_votesCount]) 
      } 
   } 

   //server_print("Successfully added this to Vote Access: Trigger: %s Question: %s Option text 1: %s Option command 1: %s Option text 2: %s Option command 2: %s",triggers[g_votesCount],questions[g_votesCount],optiontext1[g_votesCount],option1[g_votesCount],optiontext2[g_votesCount],option2[g_votesCount]) 

   g_votesCount++ 

   return PLUGIN_HANDLED 
} 

public check_say(id) { 
   const SAYLINELEN = 100 
   new sayline[SAYLINELEN] 
   read_argv(1,sayline,SAYLINELEN - 1) 

   new saylineLen = strlen(sayline) 

   // Too short? Quit. 
   if (saylineLen < 6) { 
      //debugprint("Too short",0) 
      return PLUGIN_CONTINUE 
   } 

   new firstFive[6] 
   copy(firstFive,5,sayline) 

   // Quit if not starting with "vote " 
   if (!equali(firstFive,"vote ")) { 
      //debugprint("Doesn't begin with ^"vote ^"",0) 
      return PLUGIN_CONTINUE 
   } 

   if (voteInProgress) { 
      debugprint("[AMXX] Vote Access - A vote is already in progress.",0) 
      return PLUGIN_CONTINUE 
   } 

   if (delay) { 
      debugprint("[AMXX] Vote Access - Voting not allowed yet. Too close to previous voting.",0) 
      return PLUGIN_CONTINUE 
   } 

   // Get 2nd parameter 
   new zndParam[32] 
   parse(sayline,firstFive,4,zndParam,31) 

   // Match 2nd parameter against triggers, case ignoring 
   for (new i = 0;i < g_votesCount;i++) { 
      if (equali(triggers[i],zndParam)) { 
         //debugprint("%d matches!",i) 
         voteInProgress = true 
         g_currentVote = i 
         startVote() 
         break 
      } 
   } 

   return PLUGIN_CONTINUE 
} 

public startVote() { 
   client_cmd(0,"spk Gman/Gman_Choose2") 
   new i = g_currentVote 
   option1result = 0 
   option2result = 0 
   new menuBody[512] 
   new len = format(menuBody,511,"\yTime to choose!\R^n^n%s^n^n\w",questions[i]) 
   len += format(menuBody[len],511-len,"1. %s^n2. %s",optiontext1[i],optiontext2[i]) 
   new players[32], playersNum 
   // Don't show to bots 
   get_players(players,playersNum,"c") 

   for (new j = 0;j < playersNum;j++) 
      show_menu(players[j],((1<<0)|(1<<1)),menuBody) 

   g_votingPlayers = playersNum 
   new bool:param[1] 
   param[0] = true 
   set_task(get_cvar_float("amx_vote_time"),"checkvotes",VOTETASKID,param,1) 
} 

public checkvotes(bool:timesUp[]) { 
   if (timesUp[0]) { 
      client_print(0,print_chat,"[AMXX] Vote Access - Time is up! Not everyone voted, but here is the result:") 
      server_print("[AMXX] Vote Access - Time is up! Not everyone voted, but here is the result:") 
      log_message("[AMXX] Vote Access - Time is up! Not everyone voted, but here is the result:") 
   } 

   voteInProgress = false 
   delay = true 
   set_task(get_cvar_float("amx_vote_delay"),"delayOff") 

   new totalVotes = option1result + option2result 
   if (totalVotes == 0) { 
      debugprint("[AMXX] Vote Access - No one voted, will not do anything.",0) 
      return 
   } 

   new i = g_currentVote 
    
   client_print(0,print_chat,"[AMXX] Vote Access - Voting result: Option 1 (%s) got %d votes, option 2 (%s) got %d votes.",optiontext1[i],option1result,optiontext2[i],option2result) 
   server_print("[AMXX] Vote Access - Voting result: Option 1 (%s) got %d votes, option 2 (%s) got %d votes.",optiontext1[i],option1result,optiontext2[i],option2result) 
   log_message("[AMXX] Vote Access - Voting result: Option 1 (%s) got %d votes, option 2 (%s) got %d votes.",optiontext1[i],option1result,optiontext2[i],option2result) 

   if (option1result == option2result) { 
      client_print(0,print_chat,"[AMXX] Vote Access - Even score! Will not touch anything.") 
      server_print("[AMXX] Vote Access - Even score! Will not touch anything.") 
      log_message("[AMXX] Vote Access - Even score! Will not touch anything.") 
   } 
   else if (option1result > option2result) { 
      client_print(0,print_chat,"[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext1[i]) 
      server_print("[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext1[i]) 
      log_message("[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext1[i]) 
      server_cmd("%s",option1[i]) 
   } 
   else { 
      client_print(0,print_chat,"[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext2[i]) 
      server_print("[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext2[i]) 
      log_message("[AMXX] Vote Access - Executing %s: %s.",questions[i],optiontext2[i]) 
      server_cmd("%s",option2[i]) 
   } 
} 

public handlemenu(id,key) { 
   if (!voteInProgress) { 
      client_print(id,print_chat,"[AMXX] Vote Access - Your vote is too late.") 
      return 
   } 

   switch(key) { 
      case 0: { 
         option1result++ 
      } 
      case 1: { 
         option2result++ 
      } 
   } 
   new name[32] 
   get_user_name(id,name,31) 
   if (get_cvar_num("amx_vote_answers") == 1) { 
      client_print(0,print_chat,"[AMXX] Vote Access - %s voted for option %d.",name,key + 1) 
   } 

   server_print("[AMXX] Vote Access - %s voted for option %d.",name,key + 1) 
   log_message("[AMXX] Vote Access - %s voted for option %d.",name,key + 1) 

   if (option1result + option2result == g_votingPlayers) { 
      if (task_exists(VOTETASKID)) 
         remove_task(VOTETASKID) 

      client_print(0,print_chat,"[AMXX] Vote Access - Everyone voted. Counting votes...") 
      server_print("[AMXX] Vote Access - Everyone voted. Counting votes...") 
      log_message("[AMXX] Vote Access - Everyone voted. Counting votes...") 
      new bool:param[1] 
      param[0] = false 
      set_task(3.0,"checkvotes",0,param,1) 
   } 
} 

public breakvote(id,level,cid) { 
   if (!cmd_access(id,level,cid,1)) { 
      return PLUGIN_HANDLED 
   } 
   new name[32] 
   get_user_name(id,name,31) 

   remove_task(VOTETASKID) 
   voteInProgress = false 
   client_print(0,print_chat,"[AMXX] Vote Access - Admin %s cancelled voting.",name) 
   server_print("[AMXX] Vote Access - Admin %s cancelled voting.",name) 
   log_message("[AMXX] Vote Access - Admin %s cancelled voting.",name) 

   delay = true 
   set_task(get_cvar_float("amx_vote_delay"),"delayOff") 

   return PLUGIN_HANDLED 
} 

public delayOff() { 
   delay = false 
} 

public debugprint(message[],value) { 
   server_print(message,value) 
   client_print(0,print_chat,message,value) 
   log_message(message,value) 

} 

public votemenu(id,level,cid) { 
   if (!cmd_access(id,level,cid,1)) { 
      return PLUGIN_HANDLED 
   } 

   showvotemenu(id,0) 
    
   return PLUGIN_HANDLED 
} 

showvotemenu(id,page) { 
   idpage[id] = page 

   new menuBody[512] 
   new len = format(menuBody,511,"\yVote Access votes:\R^n^n\w") 

   // Back/quit flag 
   new flags = (1<<9) 

   new i 
   for (i = 0;i < 8 && i < g_votesCount - (page * 8);i++) { 
      len += format(menuBody[len],511 - len,"%d. %s^n",i + 1,questions[i + page * 8]) 
      flags += (1<<i) 
   } 
   if (g_votesCount > (page + 1) * 8) { 
      len += format(menuBody[len],511 - len,"^n9. Next page") 
      flags += (1<<8) 
   } 
   if (page == 0) 
      len += format(menuBody[len],511 - len,"^n0. Quit^n") 
   else 
      len += format(menuBody[len],511 - len,"^n0. Previous page^n") 

   show_menu(id,flags,menuBody) 
} 

public handleadminmenu(id,key) { 
   switch (key) { 
      case 8: { 
         // Next page 
         showvotemenu(id,++idpage[id]) 
      } 
      case 9: { 
         // Exit/back page 
         if (idpage[id] != 0) 
            showvotemenu(id,--idpage[id]) 
      } 
      default: { 
         if (voteInProgress) { 
            debugprint("[AMXX] Vote Access - A vote is already in progress.",0) 
            return PLUGIN_CONTINUE 
         } 

         voteInProgress = true 
         g_currentVote = key + (idpage[id] * 8) 
         startVote() 
      } 
   } 

   return PLUGIN_CONTINUE 
} 

public plugin_init() { 
   register_plugin("Vote Access","0.3.2","jghg") 
   register_clcmd("say","check_say") 
   register_clcmd("say_team","check_say") 
   register_srvcmd("amx_voteaccess","addvoteaccess",0,": add ability to vote for stuff :-)") 
   register_menucmd(register_menuid("Time to choose!"),1023,"handlemenu") 
   register_menucmd(register_menuid("Vote Access votes"),1023,"handleadminmenu") 
   register_concmd("amx_voteaccessbreak","breakvote",ADMIN_VOTE,": breaks an ongoing Vote Access vote") 
   register_clcmd("amx_voteaccessmenu","votemenu",ADMIN_VOTE,": displays a menu of possible votes to start") 

   if (!cvar_exists("amx_vote_time")) 
      register_cvar("amx_vote_time","20") 
   if (!cvar_exists("amx_vote_answers")) 
      register_cvar("amx_vote_answers","1") 
   if (!cvar_exists("amx_vote_delay")) 
      register_cvar("amx_vote_delay","60") 

}

