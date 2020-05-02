/* 
* 
* AMX_FF 
*  by JustinHoMi 
* 
*/ 

#include <amxmodx> 

public admin_ff(id,level){ 
   if (!(get_user_flags(id)&level)){ 
      console_print(id,"[AMXX] You have no access to that command.") 
      return PLUGIN_HANDLED 
   } 
   if (read_argc() < 2){ 
         new ff_cvar = get_cvar_num("mp_friendlyfire") 
         console_print(id,"[AMXX] ^"mp_friendlyfire^" is ^"%i^"",ff_cvar) 
         return PLUGIN_HANDLED 
   } 

   new ff_s[2] 
   read_argv(1,ff_s,2) 
   new ff = str_to_num(ff_s) 

   if(ff == 1) { 
      server_cmd("mp_friendlyfire 1") 
      console_print(id,"[AMXX] Friendly fire is now on") 
   } 
   else if(ff == 0) { 
      server_cmd("mp_friendlyfire 0") 
      console_print(id,"[AMXX] Friendly fire is now off") 
   } 

   return PLUGIN_HANDLED 
} 

public check_ff(id) { 
   new ff = get_cvar_num("mp_friendlyfire") 
   if(ff == 1) 
      client_print(id,print_chat,"[AMXX] Friendly fire is on") 
   else if(ff == 0) 
      client_print(id,print_chat,"[AMXX] Friendly fire is off") 
   return PLUGIN_HANDLED 
} 

public plugin_init(){ 
   register_plugin("Admin FF","0.21","JustinHoMi") 
   register_concmd("amx_ff","admin_ff",ADMIN_CVAR,"< 0/1 >") 
   register_clcmd("say /ff","check_ff") 
   register_clcmd("say_team /ff","check_ff") 
   return PLUGIN_CONTINUE 
}

