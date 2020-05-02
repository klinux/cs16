/* AMX Mod script. 
* 
* (c) Copyright	2002-2003, f117bomb 
* This file is provided	as is (no warranties). 
*/  

#include <amxmodx> 
#include <fun> 
#include <amxmisc> 

/* 
* Usage: amx_bury <authid, nick, @team or #userid> 
* Usage: amx_unbury <authid, nick, @team or #userid> 
* Examples: 
* amx_bury @CT 
* amx_unbury @TERRORIST	
* amx_bury #213	
* 
*/ 

bury_player(id,victim){	 
   new name[32], iwpns[32], nwpn[32], iwpn 
   get_user_name(victim,name,31)  
   get_user_weapons(victim,iwpns,iwpn) 
   for(new a=0;a<iwpn;++a) { 
      get_weaponname(iwpns[a],nwpn,31) 
      engclient_cmd(victim,"drop",nwpn)	
   } 
   engclient_cmd(victim,"weapon_knife")	
   new origin[3]  
   get_user_origin(victim, origin)  
   origin[2] -=	30 
   set_user_origin(victim, origin)     
   console_print(id,"Client ^"%s^" has been burried",name) 
} 

public admin_bury(id,level,cid){  
	if (!cmd_access(id,level,cid,2)) 
		return PLUGIN_HANDLED 
	new arg[32], admin_name[32], player_name[32]
	read_argv(1,arg,31) 
	get_user_name(id,admin_name,31)
	if (arg[0]=='@'){ 
		new players[32], inum  
		get_players(players,inum,"ae",arg[1]) 
		if (inum==0){ 
			console_print(id,"No clients in such team") 
			return	PLUGIN_HANDLED 
		}	
		for(new a=0;a<inum;++a){ 
			if (get_user_flags(players[a])&ADMIN_IMMUNITY){ 
				get_user_name(players[a],player_name,31) 
				console_print(id,"Skipping ^"%s^" because client has immunity",player_name) 
				continue 
			} 
			bury_player(id,players[a]) 
		}	
		switch(get_cvar_num("amx_show_activity")) {	
			case 2:	client_print(0,print_chat,"ADMIN %s: has buried	all %s",admin_name,arg[1])	
			case 1:	client_print(0,print_chat,"ADMIN: has buried all %s",arg[1])	   
		}
	} 
	else	{ 
		new player = cmd_target(id,arg,7)	
		if (!player) return PLUGIN_HANDLED 
		bury_player(id,player)	
		get_user_name(player,player_name,31) 	
		switch(get_cvar_num("amx_show_activity"))	{	
			case 2:	client_print(0,print_chat,"ADMIN %s: has buried	%s",admin_name,player_name)	
			case 1:	client_print(0,print_chat,"ADMIN: has buried %s",player_name)	    
		}
	} 
	return PLUGIN_HANDLED  
}  

unbury_player(id,victim){ 
   new name[32], origin[3] 
   get_user_name(victim,name,31)  
   get_user_origin(victim, origin) 
   origin[2] +=	35 
   set_user_origin(victim, origin) 
   console_print(id,"Client ^"%s^" has been unburried",name) 
}  

public admin_unbury(id,level,cid){  
	if (!cmd_access(id,level,cid,2)) 
		return PLUGIN_HANDLED 
	new arg[32],	player_name[32], name2[32]  
	read_argv(1,arg,31) 
	get_user_name(id,name2,31) 
	if (arg[0]=='@'){ 
		new players[32], inum , name[32] 
		get_players(players,inum,"ae",arg[1]) 
		if (inum==0){ 
			console_print(id,"No clients in such team") 
			return	PLUGIN_HANDLED 
		}	
		for(new	a=0;a<inum;++a){ 
			if (get_user_flags(players[a])&ADMIN_IMMUNITY){	
				get_user_name(players[a],name,31) 
				console_print(id,"Skipping ^"%s^" because client has immunity",name) 
				continue 
			} 
			unbury_player(id,players[a]) 
		}
		switch(get_cvar_num("amx_show_activity"))	{
			case 2:	client_print(0,print_chat,"ADMIN %s: has unburied all %s",name2,arg[1])
			case 1:	client_print(0,print_chat,"ADMIN: has unburied all %s",arg[1])	    
		} 
	} 
	else	{ 
		new player = cmd_target(id,arg,7)	
		if (!player) return PLUGIN_HANDLED 
		unbury_player(id,player)
		get_user_name(player,player_name,31)
		switch(get_cvar_num("amx_show_activity"))	{	
			case 2:	client_print(0,print_chat,"ADMIN %s: has unburied %s",name2,player_name)	
			case 1:	client_print(0,print_chat,"ADMIN: has unburied %s",player_name)	      
		}	
	} 
	return PLUGIN_HANDLED  
}  

public plugin_init() { 
   register_plugin("Admin Bury","0.9.3","f117bomb")  
   register_concmd("amx_bury","admin_bury",ADMIN_LEVEL_A,"<authid, nick, @team or #userid>")  
   register_concmd("amx_unbury","admin_unbury",ADMIN_LEVEL_A,"<authid, nick, @team or #userid>")  
   return PLUGIN_CONTINUE 
} 




