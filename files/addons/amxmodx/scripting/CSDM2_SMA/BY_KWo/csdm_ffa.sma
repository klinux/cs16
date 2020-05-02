/**
 * csdm_ffa.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM FFA - Sets free-for-all mode on other plugins.
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <csdm>
#pragma library csdm_main

new PLUGIN[]	= "CSDM FFA"
new VERSION[]	= CSDM_VERSION
new AUTHOR[]	= "CSDM Team"
new ACCESS		= ADMIN_MAP

new bool:g_MainPlugin = true
new pv_mp_friendlyfire
new bool:g_PluginInited = false
new bool:g_Enabled = false
new bool:g_hideradar = false

// page info for settings in CSDM Setting Menu
new g_SettingsMenu = 0
new g_FfaSettMenu = 0
new g_ItemsInMenuNr = 0
new g_PageSettMenu = 0

new const g_sFireInTheHole[] = "#Fire_in_the_hole"
new const g_sFireInTheHoleSound[] = "%!MRAD_FIREINHOLE"

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[])
{
	if (equali(module, "csdm_main"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public csdm_CfgInit()
{	
	csdm_reg_cfg("ffa", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("csdm_ffa_enable", "csdm_ffa_enable", ACCESS, "Enables FFA Mode")
	register_concmd("csdm_ffa_disable", "csdm_ffa_disable", ACCESS, "Disables FFA Mode")
	register_concmd("csdm_ffa_ctrl", "csdm_ffa_ctrl", ACCESS, "FFA Toggling")
	register_concmd("csdm_radar_ctrl", "csdm_radar_ctrl", ACCESS, "Radar Toggling")
	register_clcmd("csdm_ffa_sett_menu", "csdm_ffa_sett_menu", ACCESS, "CSDM FFA Settings Menu")
	register_event("ResetHUD", "eventResetHud", "be")
	register_message(get_user_msgid("TextMsg"), "msgTextMsg")
	register_message(get_user_msgid("SendAudio"), "msgSendAudio")

	g_MainPlugin = module_exists("csdm_main") ? true : false
	
	if (g_MainPlugin)
	{
		g_SettingsMenu = csdm_settings_menu()
		g_ItemsInMenuNr = menu_items(g_SettingsMenu)
		g_PageSettMenu = g_ItemsInMenuNr / 7

		g_FfaSettMenu = menu_create("CSDM FFA Settings Menu", "use_csdm_ffa_menu")

		menu_additem(g_SettingsMenu, "CSDM FFA Settings", "csdm_ffa_sett_menu", ACCESS)

		if (g_FfaSettMenu)
		{
			new cb_ffa = menu_makecallback("hook_ffa_menu")
			menu_additem(g_FfaSettMenu, "FFA Enabled/Disabled", "csdm_ffa_ctrl", ADMIN_MAP, cb_ffa)

			new cb_radar = menu_makecallback("hook_radar_menu")
			menu_additem(g_FfaSettMenu, "Radar Scrambled/Disabled", "csdm_radar_ctrl", ADMIN_MAP, cb_radar)
			menu_additem(g_FfaSettMenu, "Back", "csdm_sett_back", 0, -1)
		}
	}
	pv_mp_friendlyfire = get_cvar_pointer("mp_friendlyfire")
	set_task(4.0, "enforce_ffa")
	register_message(get_user_msgid("Radar"), "Radar_Hook")
	g_PluginInited = true
}
public plugin_cfg()
{
	if (!pv_mp_friendlyfire)
		pv_mp_friendlyfire = get_cvar_pointer("mp_friendlyfire")
}

public csdm_StateChange(csdm_state)
{
	new value = csdm_active() ? 1:0

	if ((value) && g_Enabled)
	{
		csdm_set_ffa(1)
		if (g_hideradar)
			client_cmd(0, "hideradar")
		if (pv_mp_friendlyfire)
			set_pcvar_num(pv_mp_friendlyfire, 1)
	}
	else if (g_PluginInited)
	{
		csdm_set_ffa(0)
		client_cmd(0, "drawradar")
	}
}

public msgTextMsg(msg_id, msg_dest, msg_entity) // block "fire in the hole" msg
{
	new sTemp[sizeof(g_sFireInTheHole)]
	
	if (csdm_active() && csdm_get_ffa() && get_msg_args() == 5 && get_msg_argtype(5) == ARG_STRING)
	{
		get_msg_arg_string(5, sTemp, sizeof(sTemp)-1)
		if(equal(sTemp, g_sFireInTheHole))
			return PLUGIN_HANDLED
	}
		
	return PLUGIN_CONTINUE
}

public msgSendAudio() // block "fire in the hole" radio
{
	new sTemp[sizeof(g_sFireInTheHoleSound)]

	if(csdm_active() && csdm_get_ffa()) 
	{
		get_msg_arg_string(2, sTemp, sizeof(sTemp)-1)
		if(equali(sTemp, g_sFireInTheHoleSound)) 
			return PLUGIN_HANDLED
	} 

	return PLUGIN_CONTINUE
}

public eventResetHud(id)
{
	if (csdm_active() && g_Enabled && g_hideradar)
	{
		client_cmd(id, "hideradar")
	}
	return PLUGIN_CONTINUE
}


public Radar_Hook(msg_id, msg_dest, msg_entity)
{
	if (csdm_active() && csdm_get_ffa())
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}


public enforce_ffa()
{
	//enforce this
	if (csdm_active() && csdm_get_ffa())
	{
		if (g_hideradar)
			client_cmd(0, "hideradar")
		if (pv_mp_friendlyfire)
			set_pcvar_num(pv_mp_friendlyfire, 1)
	}
	else if (g_hideradar)
	{
		client_cmd(0, "drawradar")
	}
}

public csdm_ffa_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_FfaSettMenu, 0)

	return PLUGIN_HANDLED
}

public use_csdm_ffa_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE

	new command[24], paccess, call
	if (!menu_item_getinfo(g_FfaSettMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_FfaSettMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}

	if ((equali(command,"csdm_ffa_ctrl")) || (equali(command,"csdm_radar_ctrl")))
	{
		client_cmd(id, command)
		menu_display(id, g_FfaSettMenu, 0)
		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_sett_back"))
	{
		menu_display(id, g_SettingsMenu, g_PageSettMenu)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public csdm_ffa_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	g_Enabled = (g_Enabled ? false : true)
	csdm_set_ffa( g_Enabled ? 1 : 0 )

	client_print(id, print_chat, "[CSDM] CSDM FFA mode changed to %s.", g_Enabled ? "on" : "off")
	if (csdm_active() && csdm_get_ffa())
	{
		if (g_hideradar)
			client_cmd(0, "hideradar")
		if (pv_mp_friendlyfire)
			set_pcvar_num(pv_mp_friendlyfire, 1)
	}
	else if (g_hideradar)
	{
		client_cmd(0, "drawradar")
	}

	csdm_write_cfg(id, "ffa", "enabled", g_Enabled ? "1" : "0")

	menu_display(id, g_FfaSettMenu, 0)
	return PLUGIN_HANDLED
}

public csdm_radar_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	g_hideradar = (g_hideradar ? false : true)

	client_print(id, print_chat, "[CSDM] CSDM radar for FFA changed to %s.", g_hideradar ? "disabled" : "scrambled")
	if (csdm_active() && csdm_get_ffa())
	{
		if (g_hideradar)
			client_cmd(0, "hideradar")
		else
			client_cmd(0, "drawradar")
	}

	csdm_write_cfg(id, "ffa", "radar_disable", g_hideradar ? "1" : "0")

	menu_display(id, g_FfaSettMenu, 0)
	return PLUGIN_HANDLED
}

public hook_ffa_menu(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ffa_ctrl"))
	{
		if (!g_Enabled)
		{
			menu_item_setname(menu, item, "FFA Disabled")
		} else {
			menu_item_setname(menu, item, "FFA Enabled")
		}
	}
}

public hook_radar_menu(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_radar_ctrl"))
	{
		if (!g_hideradar)
		{
			menu_item_setname(menu, item, "Radar Scrambled")
		} else {
			menu_item_setname(menu, item, "Radar Disabled")
		}
	}
}


public csdm_ffa_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_ffa(1)
	g_Enabled = true
	client_print(id, print_chat, "CSDM FFA enabled.")
	if (g_hideradar)
		client_cmd(0, "hideradar")
	if (pv_mp_friendlyfire)
		set_pcvar_num(pv_mp_friendlyfire, 1)

	return PLUGIN_HANDLED	
}

public csdm_ffa_disable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	csdm_set_ffa(0)
	g_Enabled = false
	client_print(id, print_chat, "CSDM FFA disabled.")
	if (g_hideradar)
		client_cmd(0, "drawradar")

	return PLUGIN_HANDLED	
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
	
		if (equali(setting, "enabled"))
		{
			csdm_set_ffa(str_to_num(value))
			g_Enabled = (str_to_num(value) ? true : false)
		}
		if (equali(setting, "radar_disable"))
		{
			g_hideradar = (str_to_num(value) ? true : false)
		}
	}
}
