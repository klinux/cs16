#include <amxmodx>
#include <amxconst>
#include <amxmisc> 

new client_demoname[128]
new rec_pl[33]
new bool:g_cstrikeRunning

new D_PLUGIN[]	= "AMX X Record Demo"

new const PLUGINNAME[] = "AMX X Record Demo"
new const VERSION[] = "v2.5"
new const AUTHOR[] = "KWo & KaszpiR"

// Menu

// ============================================================================
// ================================= INIT =====================================
// ============================================================================

public plugin_init() 
{
	register_plugin(PLUGINNAME,VERSION,AUTHOR)
	register_dictionary("recorddemo.txt") 
	register_clcmd("say recdemo","rec_demo",0)
	register_clcmd("say_team recdemo","rec_demo",0)
	register_clcmd("say scr","rec_ss",0)
	register_clcmd("say_team scr","rec_ss",0)

	register_clcmd("amx_recorddemo","rec_demo",ADMIN_MENU,"- displays record demo ask")
	register_clcmd("amx_screenshot","rec_ss",ADMIN_MENU,"- displays screenshot ask")

	// Menu
	register_menucmd(register_menuid("Screenshot"),1023,"rec_ss_action")
	register_menucmd(register_menuid("Record Demo"),1023,"rec_demo_action")
	register_menucmd(register_menuid("Stop Recording"),1023,"rec_demo_off_action")
	register_event("TextMsg","eRestart","a","2&#Game_C","2&#Game_w")
	g_cstrikeRunning = ( is_running("cstrike") || is_running("czero") )
	AddMenuItem("Record Demo", "amx_recorddemo", ADMIN_MENU, D_PLUGIN)
	AddMenuItem("Screenshot", "amx_screenshot", ADMIN_MENU, D_PLUGIN)
}

	
public rec_demo(id) 
{
	if ( rec_pl[id] == 1 ) 
	{
		rec_demo_off(id) 
		return PLUGIN_HANDLED
	}
	else 
	{
		new menu_body[512],curmap[32]
		new pl_name[32]
		get_user_name(id,pl_name,31)
		new keys = (1<<0)|(1<<1)
		get_mapname(curmap,31)
		new demoname[256]
		new dem_num = 1
  
		new stime[64]	
		get_time("%m-%d-%Y %H_%M",stime,63)
		
		format(demoname,255,"%s %s",pl_name,curmap)
		replace_all(demoname,64,"/","-")
		replace_all(demoname,64,"\","-")
		replace_all(demoname,64,":","-")
		replace_all(demoname,64,"*","-")
		replace_all(demoname,64,"?","-")
		replace_all(demoname,64,">","-")
		replace_all(demoname,64,"<","-")
		replace_all(demoname,64,"|","-")

		if (!is_dedicated_server())
		{
			format(client_demoname,255,"%s %d.dem",demoname,dem_num)
			while ( file_exists(client_demoname) )
			{
				dem_num++
				format(client_demoname,255,"%s %d.dem",demoname,dem_num)
			}
		}
		else
		{
			format(client_demoname,255,"%s %s.dem",demoname,stime)
		}
		if (g_cstrikeRunning) 
		{
			format(menu_body,511,"%L",id,"CS_REC_DEMO",client_demoname)
		}
		else
		{
			format(menu_body,511,"%L",id,"NOCS_REC_DEMO",client_demoname)
		}
		show_menu(id,keys,menu_body,-1,"Record Demo") //ask if client wants to record a demo		
	}
	return PLUGIN_HANDLED	
}

public rec_demo_action(id,key) 
{
	if(key == 0) 
	{
		client_cmd(id,"amx_chat %L",id,"REC_DEMO_START",client_demoname)
		client_cmd(id,"stop;record ^"%s^"",client_demoname)
		set_task(3.0, "show_status_cmd", id)

		rec_pl[id] = 1
		rec_demo_off(id)
	}
	return PLUGIN_HANDLED
}

public show_status_cmd(id)
{
	client_cmd(id,"status")
}
	
public rec_demo_off(id) 
{
	new menu_body[512]
	new keys = (1<<0)
	if (g_cstrikeRunning) 
	{
		format(menu_body,511, "%L",id,"CS_STOP_REC")
	}
	else 
	{
		format(menu_body,511, "%L",id,"NOCS_STOP_REC")
	}
	show_menu(id,keys,menu_body,-1,"Stop Recording") //ask to stop recording	
	return PLUGIN_HANDLED
}

public rec_demo_off_action(id,key) 
{
	switch(key) 
	{
		case 0: 
		{
			client_cmd(id,"amx_chat %L",id,"REC_DEMO_END",client_demoname)
			client_cmd(id,"stop")
			rec_pl[id] = 0
		}
	}
	return PLUGIN_HANDLED
}

// takes scoreboard screenshot on clients
public rec_ss2(id[]) client_cmd(id[0],"snapshot")
public rec_ss3(id[]) client_cmd(id[0],"-showscores")

public rec_ss(id) 
{
	new menu_body[512]
	new keys = (1<<0)|(1<<1)
	if (g_cstrikeRunning)
	{
		format(menu_body,511, "%L",id,"CS_SS")
	}
	else
	{
		format(menu_body,511,"%L",id,"NOCS_SS")
	}
	show_menu(id,keys,menu_body,-1,"Screenshot")	
	return PLUGIN_HANDLED
}

public rec_ss_action(id,key) 
{
	new params[1]
	params[0] = id
	switch(key) 
	{
		case 0: 
		{
			client_cmd(id,"+showscores")
			set_task(0.3,"rec_ss2",0,params,1)
			set_task(0.6,"rec_ss3",0,params,1)
		}
	}
	return PLUGIN_HANDLED
}

public eRestart()
{
	for (new i = 0; i < 32; ++i)
	{
		if ( rec_pl[i] != 0 )
		{
			rec_pl[i] = 0
			client_cmd(i,"stop")
		}
 	}
}
