/* 
* AMX Mod script. 
* This file is provided as is (no warranties). 
* 
* Automatic Map-Restart after xx Seconds 
*  by ToT|V!PER (viper@totclan.de) 
* 
* Homepage: http://www.totclan.de 
* IRC-Chan: #totclan @ irc.de.quakenet.org 
* 
* ------------------------------------------------ 
* 
* Changelog: (Last-Update 16.02.2003) 
* 
* V0.92: Complete Rewrite + added admin functions 
*        - option to use hud + client-says 
* V0.5 : First Public Release 
* 
* ------------------------------------------------ 
* 
* Put in server.cfg or admin.cfg: 
* 
* amx_auto_rr_time < float > (default: 25 seconds) 
* amx_auto_rr_time 45.0 = Restart after 45 Seconds 
* 
*/    
#include <amxmodx>  

new onoff[8] 
new bool:AutoRR = true      /* Plugin is enabled default - Set to false to disable */ 
new bool:AutoHud = true      /* Plugin uses Hud-Messages  - Set to false to use client_say */ 
new username[32] 
 
public amx_auto_rr(id){  
	if (!(get_user_flags(id)&ADMIN_CFG)){  
		client_print(id,print_console,"[AMXX] You have no access to that command!")  
		return PLUGIN_HANDLED  
	}  
	if (read_argc() < 2){ 
		checkmode() 
		client_print(id,print_console,"[AMXX] Usage: amx_auto_rr < 0 | 1 >  | Currently: * %s *", onoff)  
		return PLUGIN_HANDLED  
	}  
	read_argv(1,onoff,2)  

	if (equal(onoff,"1", 1)){ 
		AutoRR = true  
		client_print(id,print_console,"[AMXX] Auto-Restart is now enabled!") 
		if (AutoHud == true){ 
			hudstyle() 
		} 
		else { 
			clientstyle() 
		} 		
		log_amx("amx_auto_rr: ^"%s^" enabled Auto-Restart.",get_user_name(id,username,31)) 
	} 
	else {  
		AutoRR = false 
		client_print(id,print_console,"[AMXX] Auto-Restart is now disabled")  
		if (AutoHud == true){ 
			hudstyle() 
		} 
		else { 
			clientstyle() 
		} 
		log_amx("amx_auto_rr: ^"%s^" disabled Auto-Restart.",get_user_name(id,username,31)) 
	}  
	return PLUGIN_HANDLED  
}  

public checkmode() { 
	if(AutoRR == true){  
		copy(onoff, 8, "enabled")  
	} 
	else {  
		copy(onoff, 8, "disabled")  
	}  
	return PLUGIN_CONTINUE 
} 

public hudstyle() { 
	new message[128] 
	checkmode() 
	format(message,127,"[AMXX]: Admin has %s Auto-Restart!",onoff) 
	set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 6.0, 0.01, 0.1, 3)    
	show_hudmessage(0,message) 
	return PLUGIN_CONTINUE 
} 

public clientstyle() { 
	new message[128] 
	checkmode() 
	format(message,127,"[AMXX]: Admin %s Auto-Restart",onoff) 
	client_print(0,print_chat,message) 
	return PLUGIN_CONTINUE 
} 

public restart_time(){
	if (get_cvar_num("amx_auto_rr_time")==0){	
		AutoRR=false
		checkmode()
//		return PLUGIN_HANDLED
	}
	if (AutoRR==true){
		client_print(0,print_chat,"[AMXX] The game will restart after %d s.",get_cvar_num("amx_auto_rr_time"))
		set_task (float(get_cvar_num("amx_auto_rr_time")),"restart_map",0)
//		return PLUGIN_CONTINUE
	}
}

public restart_map() {    
	if (AutoRR==true  && (get_cvar_num("amx_auto_rr_time")>0)){  
		set_hudmessage(0, 100, 200, 0.05, 0.65, 2, 0.02, 6.0, 0.01, 0.1, 3)    
		show_hudmessage(0,"[AMXX] Automatic Round-Restart!")    
		set_cvar_float("sv_restart",2.0)  
//		return PLUGIN_HANDLED
	}  
	else {  
		client_print(0,print_chat,"[AMXX] Autorestart plugin is disabled. No restart will be done!")      
//		return PLUGIN_HANDLED
	}  
}  

public plugin_init() {  
	register_plugin("Auto-Restart","0.9.2","ToT | V!PER")  
	register_event("TextMsg","restart_time","a","2&#Game_C")  
	register_cvar("amx_auto_rr_time","45") 
	register_clcmd("amx_auto_rr","amx_auto_rr",ADMIN_CFG,"amx_auto_rr :  < 0 | 1>   Turns ability to Auto-Restart (Game Commencing) on and off")  
} 
