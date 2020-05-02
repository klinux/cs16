
/* AMX Mod script. 
* 
* (c) Copyright 2002-2003, OLO 
* This file is provided as is (no warranties). 
* 
* Usage: amx_clexec <authid, nick, @team or #userid> <command line> 
* Examples: 
* amx_clexec @CT disconnect 
* amx_clexec @TERRORIST "say we will lose!!!" 
* amx_clexec #213 "name \'die another day\'" 
* 

modified by _KaszpiR_ 
to support also * as all players
amx_clexec2 - will ignore immunities, requires using this cmd admin to have admin_level ban
*/ 

#include <amxmodx> 
#include <amxmisc> 

public plugin_init() 
{ 
  register_plugin("Admin Clexec","0.9.4k","default") 
  register_concmd("amx_clexec","admin_clexec",ADMIN_LEVEL_A,"<authid, nick, @team, * or #userid> <command line>") 
  register_concmd("amx_clexec2","admin_clexec2",ADMIN_BAN,"<authid, nick, @team, * or #userid> <command line>") 
} 

clexec_player(id,victim,cmdline[]){ 
  new name[32] 
  get_user_name(victim,name,31) 
  if (is_user_bot(victim)){ 
    new cmd[32] 
    parse(cmdline,cmd,31) 
    engclient_cmd(victim,cmd,cmdline[strlen(cmd)+1]) 
  } 
  else 
    client_cmd(victim,cmdline) 
  console_print(id,"Command line ^"%s^" has been executed on ^"%s^"",cmdline,name) 
} 

public admin_clexec(id,level,cid) { 
  if (!cmd_access(id,level,cid,3)) 
    return PLUGIN_HANDLED 
  new arg[32], cmdline[64] 
  read_argv(1,arg,31) 
  read_argv(2,cmdline,63) 
  while ( replace( cmdline ,63,"\'","^"") ) { } 
  if (arg[0]=='*'){ 
    new players[32], inum, name[32]
    get_players(players,inum) 
    if (inum==0){ 
      console_print(id,"No clients online.") 
      return PLUGIN_HANDLED 
    } 
    for(new a=0;a<inum;++a){ 
      if (get_user_flags(players[a])&ADMIN_IMMUNITY){ 
        get_user_name(players[a],name,31) 
        console_print(id,"Skipping ^"%s^" because client has immunity",name) 
        continue 
      } 
      clexec_player(id,players[a],cmdline) 
    } 
  } 
  else
  if (arg[0]=='@'){ 
    new players[32], inum , name[32] 
    get_players(players,inum,"e",arg[1]) 
    if (inum==0){ 
      console_print(id,"No clients in such team") 
      return PLUGIN_HANDLED 
    } 
    for(new a=0;a<inum;++a){ 
      if (get_user_flags(players[a])&ADMIN_IMMUNITY){ 
        get_user_name(players[a],name,31) 
        console_print(id,"Skipping ^"%s^" because client has immunity",name) 
        continue 
      } 
      clexec_player(id,players[a],cmdline) 
    } 
  } 
  else { 
    new player = cmd_target(id,arg,1) 
    if (!player) return PLUGIN_HANDLED 
    clexec_player(id,player,cmdline) 
  } 
  return PLUGIN_HANDLED 
} 
////////////////////////////////////////////////////////////
public admin_clexec2(id,level,cid) { 
  if (!cmd_access(id,level,cid,3)) 
    return PLUGIN_HANDLED 
  new arg[32], cmdline[64] 
  read_argv(1,arg,31) 
  read_argv(2,cmdline,63) 
  while ( replace( cmdline ,63,"\'","^"") ) { } 
  if (arg[0]=='*'){ 
    new players[32], inum
    get_players(players,inum) 
    if (inum==0){ 
      console_print(id,"No clients online.") 
      return PLUGIN_HANDLED 
    } 
    for(new a=0;a<inum;++a) 
      clexec_player(id,players[a],cmdline) 
     
  } 
  else
  if (arg[0]=='@'){ 
    new players[32], inum
    get_players(players,inum,"e",arg[1]) 
    if (inum==0){ 
      console_print(id,"No clients in such team") 
      return PLUGIN_HANDLED 
    } 
    for(new a=0;a<inum;++a) 
      clexec_player(id,players[a],cmdline) 
     
  } 
  else { 
    new player = cmd_target(id,arg,1) 
    if (!player) return PLUGIN_HANDLED 
    clexec_player(id,player,cmdline) 
  } 
  return PLUGIN_HANDLED 
} 
