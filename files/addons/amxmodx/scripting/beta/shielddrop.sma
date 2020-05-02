
/* AMX Mod script. 
* 
* (c) Copyright 2002, _KaszpiR_ 
* This file is provided as is (no warranties). 
* Simple Shield restriction for CS by _KaszpiR_
 based on awpdrop.sma and on Turtle Shield by SuicideDog 

 Use cvar setting sv_noshield 1 to enable and sv_noshield 0 to disable plugin
 notice this plugin should work with the rest(riction) weapon (like restmenu) and you should
 enable restriction of shield

 this plugin just forces player to drop shield when then try to use it
*/ 

#include <amxmodx> 

public check_shield(id) { 
	if (get_cvar_num("sv_noshield")!=1) 
	return PLUGIN_CONTINUE 
	
	new llama = read_data(0)    
	client_print(llama,print_chat,"Shield is not allowed!") 
        client_cmd(llama,"drop weapon_shield") 
	engclient_cmd(llama, "drop","weapon_shield")
	return PLUGIN_CONTINUE 
} 

public plugin_init(){ 
	register_plugin("Drop Shield","0.3","_KaszpiR_") 
	register_event("HideWeapon","check_shield","b","1=0","1=64") 
	register_cvar("sv_noshield","1") 
	return PLUGIN_CONTINUE 
} 

