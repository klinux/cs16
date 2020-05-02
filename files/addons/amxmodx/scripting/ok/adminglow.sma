
/* AMX Mod script. 
* 
* (c) Copyright 2002-2003, f117bomb 
* This file is provided as is (no warranties). 
*/  

#include <amxmodx> 
#include <amxmisc>
#include <fun> 

/* 
* Usage: amx_glow <authid, nick, @team or #userid> <red> <green> <blue> <alpha> 
* Examples: 
* amx_glow @CT 100 100 100 20 
* amx_glow @TERRORIST 255 0 0 30 
* amx_glow #213 255 255 255 0 
* amx_glow Tom 0 0 0 255 - removes glowing 
* 
*/ 

public admin_glow(id,level,cid) { 
   if (!cmd_access(id,level,cid,6)) 
      return PLUGIN_HANDLED 
   new arg[32], sred[8], sgreen[8], sblue[8], salpha[8], name2[32] 
   get_user_name(id,name2,31) 
   read_argv(1,arg,31) 
   read_argv(2,sred,7) 
   read_argv(3,sgreen,7)    
   read_argv(4,sblue,7)    
   read_argv(5,salpha,7)    
   new ired = str_to_num(sred) 
   new igreen = str_to_num(sgreen) 
   new iblue = str_to_num(sblue) 
   new ialpha = str_to_num(salpha)    
   if (arg[0]=='@'){ 
      new players[32], inum 
      get_players(players,inum,"ae",arg[1]) 
      if (inum==0){ 
         console_print(id,"No clients in such team") 
         return PLUGIN_HANDLED 
      } 
      for(new a=0;a<inum;++a) 
         set_user_rendering(players[a],kRenderFxGlowShell, 
            ired,igreen,iblue,kRenderTransAlpha,ialpha) 
      switch(get_cvar_num("amx_show_activity"))   { 
   case 2:   client_print(0,print_chat,"ADMIN %s: set glowing on all %s",name2,arg[1]) 
   case 1:   client_print(0,print_chat,"ADMIN: set glowing on all %s",arg[1]) 
      } 
      console_print(id,"All clients have set glowing") 
   } 
   else { 
      new player = cmd_target(id,arg,7) 
      if (!player) return PLUGIN_HANDLED 
      set_user_rendering(player,kRenderFxGlowShell, 
         ired,igreen,iblue,kRenderTransAlpha,ialpha) 
      new name[32] 
      get_user_name(player,name,31) 
      switch(get_cvar_num("amx_show_activity"))   { 
   case 2:   client_print(0,print_chat,"ADMIN %s: set glowing on %s",name2,name) 
   case 1:   client_print(0,print_chat,"ADMIN: set glowing on %s",name) 
      } 
      console_print(id,"Client ^"%s^" has set glowing",name) 
   } 
   return PLUGIN_HANDLED  
} 

public plugin_init() {  
   register_plugin("Admin Glow","0.9.9","f117bomb")  
   register_concmd("amx_glow","admin_glow",ADMIN_LEVEL_A,"<authid, nick, @team or #userid> <red> <green> <blue> <alpha>")  
   return PLUGIN_CONTINUE  
} 


