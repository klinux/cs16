
/* AMXMOD script. 
* 
* (c) Copyright 2000-2002, RAV 
* This file is provided as is (no warranties). 
* 
* Takes screenshot of kill if damage is over set level. 
* 
* Changelog 
* 
* Version 1.1 - Initial Build 
* Version 1.2 - Added higher damage Sound based event. 
* Version 1.3 - Commands "say screenoff" & "/screen" to enable/disable screenshot 
* Version 1.4 - Stats added to show Weapon, Damage, Distance, Victim (all show on screenshot) 
* Version 1.5 - 3 Different random wait times producing shots various stages. 
* Version 1.6 - Updated with screeninfo (MOTD Window) 
* Version 1.7 - Added hitplace to displayed stats, sound event on Damage over 400hp!! 
* Version 1.8 - Changed number of random times to take snapshot to 6 
* Version 1.9 - Players can now set their own damage level with command "screenon < level >" Min level is 30. 
* Version 2.0 - Added Hud Message for victim 
* Version 2.0a - Added default damage if alias called without value
* Credits 
* 
* XAD - Help with showing Distance 
* EJ - Various help 
*/ 

#include <amxmodx> 

#define DMG_DEFAULT 30
new body_part[8][] = {"Whole Body","Head","Chest","Stomach","Left Arm","Right Arm","Left Leg","Right Leg"} 
new damagelevel[32] 

/* Screenshot on/off marker */ 
new hds[33] 

public screen_info(id){ 
   show_motd(id,"If enabled a screenshot will be taken when one shot causes over the chosen damage.The screenshot will also show:^n^n[DAMAGE]^n[DISTANCE]^n[BODY PART]^n[WEAPON]^n[VICTIM]^n^nTo enable this plugin type screenon (your level) eg/ screenon 80^nTo disable it type screenoff^n^nWritten by Rav","High Damage ScreenShot v2.0") 
   return PLUGIN_HANDLED 
} 

public screen_controloff(id) 
{ 
    hds[id]=0 
    client_print(id,print_chat,"High Damage Screenshot has been disabled! Type say screeninfo to see more.") 
    return PLUGIN_HANDLED 
} 

public screen_controlon(id) 
{ 
    new arg1[32] 
    read_argv(1,arg1,32) 
    hds[id]=1 
    new dmglvl = str_to_num(arg1) 
    if(dmglvl) damagelevel[id] = dmglvl
    else damagelevel[id] = DMG_DEFAULT
    client_print(id,print_chat,"High Damage Screenshot is now enabled at Level %d. Type say screeninfo to see more.", damagelevel[id]) 
    return PLUGIN_HANDLED 
} 
    
public high_damage(id)  
{ 
   new victim = read_data(0) 
   new damage = read_data(2) 
   new weapon 
   new hitplace 
   new name[33] 
   new attacker = get_user_attacker(victim,weapon,hitplace) 
   if(hds[attacker] == 0){ 
      get_user_name(victim,name,32) 
      return PLUGIN_HANDLED 
   } 
   new start[3], end[3] 
   get_user_origin(victim,start,0) 
   get_user_origin(attacker,end,0) 
   new ammo, clip, myweapon = get_user_weapon(attacker,ammo,clip) 
   new wpn[32] 
   get_weaponname(myweapon,wpn,32) 
   replace(wpn,32,"weapon_",""); 
   new distance = get_distance(start,end) 
   get_user_name(victim,name,32) 
   if(hds[attacker] == 1){ 
      if (damage > damagelevel[attacker]){ 
      new param[1] 
      param[0] = attacker 
      new snapwait = random_num(0,3)    
      set_task(snapwait * 0.05,"snap_me",0,param,2)    
      set_hudmessage(220,80,0, 0.05, 0.50, 2, 0.1, 3.0, 0.02, 0.02, 10)          
      client_print(attacker,print_chat,"[AMXX] Nice Shot! - [WEAPON] %s [DAMAGE] %ihp [PLACE] %s [DISTANCE] %0.2f m [VICTIM] %s",wpn[7], damage, body_part[hitplace], float(distance) * 0.0254, name)    
      if (damage > 400){ 
         client_cmd(0,"spk misc/perfect") 
         return PLUGIN_HANDLED 
      } 
      return PLUGIN_HANDLED 
   }  
      get_user_name(victim,name,32) 
      return PLUGIN_HANDLED    
      } 
   return PLUGIN_CONTINUE 
} 
   public snap_me(param[]){ 
   client_cmd(param[0],"snapshot") 
   return PLUGIN_HANDLED 
} 

public client_connect(id){ 
   hds[id]=0 
   return PLUGIN_CONTINUE  
} 

public client_disconnect(id){  
   hds[id]=0 
   return PLUGIN_CONTINUE  
} 

public plugin_init() 
{ 
   register_plugin("ScreenShot","2.0","Rav") 
   register_event("Damage", "high_damage", "b", "2>DMG_DEFAULT") 
   register_clcmd("screenoff","screen_controloff") 
   register_clcmd("screenon","screen_controlon")  
   register_clcmd("say screeninfo","screen_info")  
   register_clcmd("say_team screeninfo","screen_info")  
   return PLUGIN_CONTINUE 
} 
