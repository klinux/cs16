/* AMX Mod script. 
* 
* Command Aliasing 
*  by JustinHoMi 
* 
* This script is intended to mimic clanmod-style aliasing (cm_alias) 
* 
* Usage: amx_alias "alias" "command" flags 
* 

Allows you to set aliases for server commands. It allows you to alias rcon or client commands. This plugin is intended to behave like clanmod-style aliasing. It allows you to ease into using amx from adminmod or clanmod. 

Use: amx_alias "alias" "command" <level and flags> 

The admin level must be specified first, and then the flags. The only currently available flag is "l", which runs the specified command on the admin who calls the alias. 

Place aliases in moddir/addons/amxmodx/configs/aliases.cfg 

Examples: 

amx_alias "admin_map" "amx_map" Fl 
amx_alias "cl" "changelevel" F 
amx_alias "rr" "sv_restart 1" G 

As you can see, client-side commands require the "l" flag, whereas rcon commands do not. F is the flag for ADMIN_MAP and G is the flag for ADMIN_CVAR. More examples are included in the post. 

PS Note that "l" is "L". 

amx_alias "admin_map" "amx_map" Fl 
amx_alias "admin_kick" "amx_kick" Cl 
amx_alias "admin_ban" "amx_ban" Dl 
amx_alias "admin_help" "amx_help" Bl 

amx_alias "clanmodmenu" "amx_menu" Bl 
amx_alias "cl" "changelevel" F 
amx_alias "rr" "sv_restartround 1" G 
amx_alias "rr3" "sv_restart 1;sv_restart 4;sv_restart 7" G 
amx_alias "tl" "mp_timelimit" G 
amx_alias "fcc" "mp_forcechasecam" G 
amx_alias "ftb" "mp_fadetoblack" G 
amx_alias "tkp" "mp_tkpunish" G 
amx_alias "ff" "mp_friendlyfire" G 
amx_alias "atb" "mp_autoteambalance" G 
amx_alias "pw" "sv_password" K 
amx_alias "cm" " " L 
amx_alias "cm_bury" "amx_bury" Il 
amx_alias "cm_unbury" "amx_unbury" Il 

*/ 

#include <amxmodx> 
#include <amxmisc>

#define MAX_ALIASES 128      // max num of aliases to load 

new alias[MAX_ALIASES][32] 
new cmds[MAX_ALIASES][64] 
new cflags[MAX_ALIASES][5]   // cmd flags 
new uflags[MAX_ALIASES]      // user flags 
new anum = 0 
new g_aliasesFile[64]
// load and register the alias 
public admin_alias(){ 
   read_argv(1,alias[anum],31) 
   read_argv(2,cmds[anum],63) 
   read_argv(3,cflags[anum],31) 

   // seperate user flag and cmd flags 
   new user_flags[6] 
   format(user_flags,2,"%c",tolower(cflags[anum][0])) 
   uflags[anum] = read_flags(user_flags) 
   copy(user_flags,5,cflags[anum]) 

   // get the description of the original command 
   new cflag,ccmd[64],cinfo[64],description[64] 
   new cmdn = get_clcmdsnum(-1) 
   for(new i=0;i<cmdn;i++) 
   { 
         get_clcmd(i,ccmd,63,cflag,cinfo,63,-1) 
         if (equal(cmds[anum],ccmd)) 
      { 
         copy(description,63,cinfo) 
         i=500 // break out of the loop 
      } 
   } 

   // replace the name of the original cmd with the name of the alias in the desc 
   new tmp[32] 
   format(tmp,31,"%s ",alias[anum]) 
   replace(description,63,ccmd,tmp); 

   // fix for when registered commands have no description 
   if (contain(ccmd,description)!=-1) 
      copy(description,31,alias[anum]) 

   // if it's a server-side cmd then it won't have a desc, so just show the cmd it aliases 
   new   desc[32] 
   if (description[0]) 
      format(desc,63,"%s",description) 
   else 
      format(desc,31,"%s (%s)",alias[anum],cmds[anum]) 

   // and we register the command with proper flags and description 
   register_clcmd(alias[anum],"alias_run",uflags[anum],desc) 
//   server_print("[AMXX] Alias ^"%s^" added",alias[anum]) 
   log_message("[AMXX] Alias ^"%s^" added",alias[anum])
   anum++ 

   return PLUGIN_CONTINUE 
} 

// run the alias 
public alias_run(id){ 
   new thecmd[64] 
   read_argv(0,thecmd,63)                        // the name of the alias 
   new args[64] 
   read_args(args,64)                            // read the rest of the args 

   for (new i=0; i<anum; i++)                     // cycle through the stored aliases 
   { 
      if (equal(thecmd,alias[i]))                // if called alias == stored alias 
      { 
         if (get_user_flags(id)&uflags[i])         // compare user flags 
         { 
            new command[64] 
            format(command,63,"%s %s",cmds[i],args)   // put the new command and the args together 
            if (contain(cflags[i],"l") != -1)      // client command 
               client_cmd(id,command) 
            else                           // server command 
               server_cmd("%s",command) 
         } 
         else client_print(id,print_console,"[AMXX] You do not have access to this command") 
      } 
   } 

   return PLUGIN_HANDLED 
} 

public plugin_init() 
{ 
   register_plugin("Command Aliases","0.7","JustinHoMi") 
   register_srvcmd("amx_alias","admin_alias")    
   get_configsdir(g_aliasesFile, 63)
   format(g_aliasesFile, 63, "%s/aliases.cfg", g_aliasesFile) 
   server_cmd("exec ^"%s^"", g_aliasesFile)
//   server_cmd("exec addons/amxmodx/configs/aliases.cfg") 
   return PLUGIN_CONTINUE 
}
