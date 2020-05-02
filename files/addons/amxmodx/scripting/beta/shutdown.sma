/* 
* AMX_QUIT 
*  by JustinHoMi 


*/ 

#include <amxmodx> 
#include <amxmisc> 

public adminQuit(id,level, cid){ 
   if (!cmd_access(id,level,cid,2)) 
      return PLUGIN_HANDLED 
   new timer[5] 
   read_argv(1,timer,4) 
   new Float:ftime = floatstr(timer) 
   set_task(ftime,"shutDown") 
   set_hudmessage(255, 255, 0, -1.0, 0.30, 0, 6.0, 12.0, 0.5, 0.15, 1) 
   show_hudmessage(0,"Server shutting down in %g seconds",ftime) 
   console_print(id,"Shutting down server in %g seconds",ftime) 
   return PLUGIN_HANDLED 
} 

public shutDown() 
   server_cmd("quit") 

public plugin_init(){ 
   register_plugin("Admin Quit","0.9.3","JustinHoMi") 
   register_concmd("amx_shutdown","adminQuit",ADMIN_RCON,"<time in sec.> - Shuts Down a server afer xx seconds. Shows a message.") 
   return PLUGIN_CONTINUE 
}


