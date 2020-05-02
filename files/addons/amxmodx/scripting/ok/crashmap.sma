/* AMX Mod script. 
* 
* (c) 2003, Zious 
* This file is provided as is (no warranties). 
* 
*ABOUT: 
*  This plugin will save the name of the current map to a file 
*  in the base mod directory called currentmap.cfg.  In your server 
*  command line add exec currentmap.cfg or autoexec.cfg file.  After 
*  that if your server crashes it will go back to the last map that 
*  was being played. 
* 
*IMPORTANT: leave "map mapname" in you command line or other cfg 
*  file untill currentmap.cfg has been created or your server may 
*  not load. 
* 
*UPDATE: v1.1 
*  Writing the cfg will only be trigger if Game_Commencing. This 
*  means that it will only write the mapfile if people have joined 
*  the server and the game has commenced. 
*/ 

#include <amxmodx> 
#include <amxmisc> 

public plugin_init(){ 
  register_plugin("Map Crash Saver","1.1","Zious") 
  register_logevent("event_writemapcfg",2,"0=World triggered","1=Game_Commencing") 
} 

public event_writemapcfg(){ 
  new currentmap[32],mapwrite[32] 
  get_mapname(currentmap,31) 
  format(mapwrite, 31, "map %s",currentmap) 
  write_file("crashmap.cfg",mapwrite,0) 
  log_message("[AMXX] Crashmap - CrashMap set to '%s'.", currentmap) 
  return PLUGIN_HANDLED 
} 



