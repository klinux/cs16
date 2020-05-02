/* 
* 
* AMX_SLAYALL 
*  by JustinHoMi 
* 
*/ 

#include <amxmodx> 

public admin_slayall(id,level){ 
   if (!(get_user_flags(id)&level)){ 
      console_print(id,"[AMXX] You have no access to that command.") 
      return PLUGIN_HANDLED 
   } 

   new plist[32],pnum 
   get_players(plist, pnum ,"a") 

   for(new i=0; i<pnum; i++) 
      user_kill(plist[i]) 

   console_print(id,"[AMXX] All players have been slayed") 
   return PLUGIN_HANDLED 
} 

public plugin_init(){ 
   register_plugin("SlayAll","0.8","JustinHoMi") 
   register_concmd("amx_slayall","admin_slayall",ADMIN_SLAY,"- kills everyone, even immune players.") 
   return PLUGIN_CONTINUE 
}


