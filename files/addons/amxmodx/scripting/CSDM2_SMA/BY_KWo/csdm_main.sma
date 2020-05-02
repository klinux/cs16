/**
 * csdm_main.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Main - Main plugin to communicate with module
 *
 * (C)2003-2013 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <csdm>

new D_PLUGIN[]	= "CSDM Main"
new D_ACCESS	= ADMIN_MAP

#define CSDM_OPTIONS_TOTAL		2

new bool:g_StripWeapons = true
new bool:g_RemoveBomb = true
new g_StayTime
new g_drop_fwd
new g_options[CSDM_OPTIONS_TOTAL]

new g_MainMenu = -1
new g_SettingsMenu = -1
new g_MainSettMenu = -1

// part taken from VEN's noweapondrop plugin
new g_max_clients
new const g_wbox_model[] = "models/w_weaponbox.mdl"
new const g_shield_model[] = "models/w_shield.mdl"


public plugin_natives()
{
	register_native("csdm_main_menu", "native_main_menu")
	register_native("csdm_settings_menu", "native_settings_menu")
	register_native("csdm_set_mainoption", "__csdm_allow_option")
	register_native("csdm_fwd_drop", "__csdm_fwd_drop")
	register_native("csdm_write_cfg", "native_write_cfg")
	register_library("csdm_main")
}

public native_main_menu(id, num)
{
	return g_MainMenu
}

public native_settings_menu(id, num)
{
	return g_SettingsMenu
}

public __csdm_allow_option(id, num)
{
	new option = get_param(1)

	if (option <= 0 || option >= CSDM_OPTIONS_TOTAL)
	{
		log_error(AMX_ERR_NATIVE, "Invalid option number: %d", option)
		return 0
	}
	
	g_options[option] = get_param(2)
	
	return 1
}

public native_write_cfg(id,num)
{
	new section[32], parameter[32], value[16]
	new filename[128]
	new cfgdir[128]
	new id
	get_configsdir(cfgdir, 127)
	format(filename, 127, "%s/csdm.cfg", cfgdir)
	id = get_param(1)
	get_string(2,section,31)
	get_string(3,parameter,31)
	get_string(4,value,15)

	new sect_length = strlen(section) + 1
	new param_length = strlen(parameter) - 1
	new sect[32]
	format(sect,31, "[%s]", section)

	if (file_exists(filename)) 
	{
		new Data[124], len
		new line = 0
		new bool:bFoundSec = false
		new bool:bFoundPar = false
		new bool:bErrorFindSect = true
		new bool:bErrorFindParam = false

		while((line = read_file(filename, line, Data, 123, len) ) != 0 )
		{
			if (strlen(Data) < 2 || Data[0] == ';')
				continue;

			if (Data[0] == '[') // new section found
			{
				if (bFoundSec)
				{
					bErrorFindParam = true
					break
				}
				else if (equali(Data, sect, sect_length))
				{
					bFoundSec = true
					bErrorFindSect = false
				}
			}
			else if (bFoundSec && equali(Data, parameter, param_length))
			{
				bFoundPar = true
				break
			}
		}

		if ((bFoundPar) && (line > 0))
		{
			new text[32]
			format(text, 31, "%s = %s", parameter, value)
			if (write_file(filename, text, line-1))
				client_print(id, print_chat, "CSDM - configuration saved successfully")
		}
		else if ((!bFoundSec) || (bErrorFindSect))
			client_print(id, print_chat, "CSDM - can't save the configuration - wrong section name")
		else if ((!bFoundPar) || (bErrorFindParam))
			client_print(id, print_chat, "CSDM - can't save the configuration - wrong parameter name")
	}
}


public __csdm_fwd_drop(id, num)
{
/*
	new id = get_param(1)
	new wp = get_param(2)
	new name[32]
	
	get_string(3, name, 31)
	
	return run_drop(id, wp, name)	
*/
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
	csdm_reg_cfg("settings", "read_cfg")
}


public plugin_init()
{
	register_plugin(D_PLUGIN, CSDM_VERSION, "CSDM Team")
	
	register_clcmd("say respawn", "say_respawn")
	register_clcmd("say /respawn", "say_respawn")
	register_concmd("csdm_enable", "csdm_enable", D_ACCESS, "Enables CSDM")
	register_concmd("csdm_disable", "csdm_disable", D_ACCESS, "Disables CSDM")
	register_concmd("csdm_ctrl", "csdm_ctrl", D_ACCESS, "")
	register_concmd("csdm_reload", "csdm_reload", D_ACCESS, "Reloads CSDM Config")
	register_clcmd("csdm_menu", "csdm_menu", ADMIN_MENU, "CSDM Menu")
	register_clcmd("csdm_sett_menu", "csdm_sett_menu", ADMIN_MENU, "CSDM Settings Menu")
	register_clcmd("csdm_main_sett_menu", "csdm_main_sett_menu", ADMIN_MENU, "CSDM Main Settings Menu")

	register_forward(FM_SetModel, "forward_set_model")
	register_concmd("csdm_cache", "cacheInfo", ADMIN_MAP, "Shows cache information")
	
	AddMenuItem("CSDM Menu", "csdm_menu", D_ACCESS, D_PLUGIN)
	g_MainMenu = menu_create("CSDM Menu", "use_csdm_menu")
	new callback = menu_makecallback("hook_item_display")

	g_SettingsMenu = menu_create("CSDM Settings Menu", "use_csdm_sett_menu")

	menu_additem(g_MainMenu, "CSDM Enabled/Disabled", "csdm_ctrl", D_ACCESS, callback)
	menu_additem(g_MainMenu, "CSDM Settings", "csdm_sett_menu", D_ACCESS)
	menu_additem(g_MainMenu, "Reload Config", "csdm_reload", D_ACCESS)

	g_MainSettMenu = menu_create("CSDM Main Settings Menu", "use_csdm_mainsett_menu")
	menu_additem(g_SettingsMenu, "CSDM Main Settings", "csdm_main_sett_menu", D_ACCESS)

	new str_callback = menu_makecallback("hook_settings_display")

	if (g_MainSettMenu)
	{
		menu_additem(g_MainSettMenu, "Strip Weapons Enabled/Disabled", "strip_weap_ctrl", D_ACCESS, str_callback)
		menu_additem(g_MainSettMenu, "Removing Bombs Enabled/Disabled", "bomb_rem_ctrl", D_ACCESS, str_callback)
		menu_additem(g_MainSettMenu, "Preset Spawn Mode Enabled/Disabled", "spawn_mode_ctrl", D_ACCESS, str_callback)
		menu_additem(g_MainSettMenu, "Back", "csdm_sett_back", D_ACCESS)
	}
	g_drop_fwd = CreateMultiForward("csdm_HandleDrop", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_options[CSDM_OPTION_SAYRESPAWN] = CSDM_SET_ENABLED

	g_max_clients = global_get(glb_maxClients)
}

public cacheInfo(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	new ar[6]
	csdm_cache(ar)
	
	console_print(id, "[CSDM] Free tasks: respawn=%d, findweapon=%d", ar[0], ar[5])
	console_print(id, "[CSDM] Weapon removal cache: %d total, %d live", ar[4], ar[3])
	console_print(id, "[CSDM] Live tasks: %d (%d free)", ar[2], ar[1])
	
	return PLUGIN_HANDLED
}

public forward_set_model(ent, const model[]) 
{
	if (!csdm_active())
		return FMRES_IGNORED

	if (!pev_valid(ent) || !equali(model, g_wbox_model) && !equali(model, g_shield_model))
		return FMRES_IGNORED

	new id = pev(ent, pev_owner)

	if (!(1 <= id <= g_max_clients))
		return FMRES_IGNORED

	new args[2]
	args[0] = ent
	args[1] = id
	set_task(0.2, "delay_find_weapon", ent, args, 2)

	return FMRES_IGNORED
}

public delay_find_weapon(args[])
{
	new ent = args[0]
	new id = args[1]

	new class[32]

	if (!pev_valid(ent))
		return

	if (!is_user_connected(id))
		return

	pev(ent, pev_classname, class, sizeof class - 1)

	if (equali(class, "weaponbox"))
		run_drop_wbox(id, ent, 0)
	else if (equali(class, "weapon_shield"))
		run_drop_wbox(id, ent, 1)

}

run_drop_wbox(id, ent, shield)
{
	new ret
	new model[32]
	ExecuteForward(g_drop_fwd, ret, id, ent, 0)
	
	if (ret == CSDM_DROP_REMOVE)
	{
		if (shield)
			csdm_remove_weaponbox(id, ent, 0, 1, 1)
		else
			csdm_remove_weaponbox(id, ent, 0, 1, 0)
		return 1
	} 
	else if (ret == CSDM_DROP_IGNORE) 
	{
		return 0
	}

	if (g_StayTime > 20 || g_StayTime < 0)
	{
		return 0
	}

	if (ent)
	{
		pev(ent, pev_model, model, 31)
		if (((equali(model,"models/w_usp.mdl")) || (equali(model,"models/w_glock18.mdl")))
				&& (g_StripWeapons))
			csdm_remove_weaponbox(id, ent, 0, 0, 0)
		else if ((equali(model,"models/w_backpack.mdl")) && (g_RemoveBomb))
			csdm_remove_weaponbox(id, ent, 0, 0, 0)
		else if (shield)
			csdm_remove_weaponbox(id, ent, g_StayTime, 1, 1)
		else
			csdm_remove_weaponbox(id, ent, g_StayTime, 1, 0)
		return 1
	}
	
	return 0
}

public csdm_PreSpawn(player, bool:fake)
{
	if (!csdm_active())
	{
		return
	}

	//we'll just have to back out for now
	if (cs_get_user_shield(player))
	{
		return
	}
	new team = get_user_team(player)
	if (g_StripWeapons)
	{
		if (team == _TEAM_T)
		{
			if (cs_get_user_shield(player))
			{
				drop_with_shield(player, CSW_GLOCK18)
			} else {
				csdm_force_drop(player, "weapon_glock18")
			}
		} else if (team == _TEAM_CT) {
			if (cs_get_user_shield(player))
			{
				drop_with_shield(player, CSW_USP)
			} else {
				csdm_force_drop(player, "weapon_usp")
			}
		}
	}
	if (team == _TEAM_T)
	{
		if (g_RemoveBomb)
		{
			new weapons[MAX_WEAPONS], num
			get_user_weapons(player, weapons, num)
			for (new i=0; i<num; i++)
			{
				if (weapons[i] == CSW_C4)
				{
					if (cs_get_user_shield(player))
					{
						drop_with_shield(player, CSW_C4)
					} else {
						csdm_force_drop(player, "weapon_c4")
					}
					break
				}
			}
		}
	}
}


public csdm_main_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_MainSettMenu, 0)

	return PLUGIN_HANDLED
}


public hook_item_display(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ctrl"))
	{
		if (!csdm_active())
		{
			menu_item_setname(menu, item, "CSDM Disabled")
		} else {
			menu_item_setname(menu, item, "CSDM Enabled")
		}
	}
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "strip_weapons"))
		{
			g_StripWeapons = str_to_num(value) ? true : false
		} else if (equali(setting, "weapons_stay")) {
			g_StayTime = str_to_num(value)
		} else if (equali(setting, "spawnmode")) {
			new var = csdm_setstyle(value)
			if (var)
			{
				log_amx("CSDM spawn mode set to %s", value)
			} else {
				log_amx("CSDM spawn mode %s not found", value)
			}
		} else if (equali(setting, "remove_bomb")) {
			g_RemoveBomb = str_to_num(value) ? true : false
		} else if (equali(setting, "enabled")) {
			csdm_set_active(str_to_num(value))
		} else if (equali(setting, "spawn_wait_time")) {
			csdm_set_spawnwait(str_to_float(value))
		}
	}
}

public csdm_reload(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	new file[128] = ""
	if (read_argc() >= 2)
	{
		read_argv(1, file, 127)
	}
		
	if (csdm_reload_cfg(file))
	{
		client_print(id, print_chat, "[CSDM] Config file reloaded.")
	} else {
		client_print(id, print_chat, "[CSDM] Unable to find config file.")
	}
		
	return PLUGIN_HANDLED
}

public csdm_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_MainMenu, 0)
	
	return PLUGIN_HANDLED
}

public csdm_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_SettingsMenu, 0)

	return PLUGIN_HANDLED
}

public csdm_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	csdm_set_active( csdm_active() ? 0 : 1 )

	client_print(id, print_chat, "CSDM %s.", csdm_active()? "enabled" : "disabled")

	csdm_write_cfg(id, "settings", "enabled", csdm_active() ? "1" : "0")

	client_print(id, print_chat, "CSDM - the map will be reloaded to affect the change of this setting.")
	set_task(3.0, "do_changelevel")
	return PLUGIN_HANDLED
}

public use_csdm_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_MainMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_MainMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}
	
	client_cmd(id, command)
	
	return PLUGIN_HANDLED
}

public use_csdm_sett_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_SettingsMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_SettingsMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}

	client_cmd(id, command)

	return PLUGIN_HANDLED
}

public use_csdm_mainsett_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_MainSettMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_MainSettMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}

	if (equali(command,"strip_weap_ctrl"))
	{
		g_StripWeapons = (g_StripWeapons ? false:true)
		menu_display(id, g_MainSettMenu, 0)
		client_print(id, print_chat, "Strip Weapons %s", g_StripWeapons ? "enabled" : "disabled")
		log_amx("CSDM strip weapons %s", g_StripWeapons ? "enabled" : "disabled")

		csdm_write_cfg(id, "settings", "strip_weapons", g_StripWeapons ? "1" : "0")

		return PLUGIN_HANDLED
	}
	else if (equali(command,"bomb_rem_ctrl"))
	{
		g_RemoveBomb = (g_RemoveBomb ? false:true)
		menu_display(id, g_MainSettMenu, 0)
		client_print(id, print_chat, "Removing Bomb %s", g_RemoveBomb ? "enabled" : "disabled")
		log_amx("CSDM removing bomb %s", g_RemoveBomb ? "enabled" : "disabled")

		csdm_write_cfg(id, "settings", "remove_bomb", g_RemoveBomb ? "1" : "0")

		client_print(id,print_chat,"CSDM - changing this setting will affect the game after changelevel command")
		return PLUGIN_HANDLED
	}
	else if (equali(command,"spawn_mode_ctrl"))
	{
		new style = csdm_curstyle()
		new stylename[24]

		if (style == -1)
			csdm_setstyle("preset")
		else
			csdm_setstyle("none")

		style = csdm_curstyle()

		if (style == -1)
			format(stylename,23,"none")
		else
			format(stylename,23,"preset")

		menu_display(id, g_MainSettMenu, 0)
		client_print(id, print_chat, "Spawn style set to %s", stylename)
		log_amx("CSDM spawn mode set to %s", stylename)

		csdm_write_cfg(id, "settings", "spawnmode", (style == -1) ? "none" : "preset")

		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_sett_back"))
	{
		menu_display(id, g_SettingsMenu, 0)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public hook_settings_display(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "strip_weap_ctrl"))
	{
		if (!g_StripWeapons)
		{
			menu_item_setname(menu, item, "Strip Weapons Disabled")
		} else {
			menu_item_setname(menu, item, "Strip Weapons Enabled")
		}
	}
	else if (equali(command, "bomb_rem_ctrl"))
	{
		if (!g_RemoveBomb)
		{
			menu_item_setname(menu, item, "Removing Bomb Disabled")
		} else {
			menu_item_setname(menu, item, "Removing Bomb Enabled")
		}
	}
	else if (equali(command,"spawn_mode_ctrl"))
	{
		new style = csdm_curstyle()
		if (style == -1)
			menu_item_setname(menu, item, "Preset Spawn Mode Disabled")
		else
			menu_item_setname(menu, item, "Preset Spawn Mode Enabled")
	}
}

public csdm_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (!csdm_active())
	{
		csdm_set_active(1)
		client_print(id, print_chat, "CSDM enabled.")
		csdm_write_cfg(id, "settings", "enabled", "1")
		client_print(id, print_chat, "CSDM - the map will be reloaded to affect the change of this setting.")
		set_task(3.0, "do_changelevel")
	}
	return PLUGIN_HANDLED	
}

public csdm_disable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (csdm_active())
	{
		csdm_set_active(0)
		client_print(id, print_chat, "CSDM disabled.")
		csdm_write_cfg(id, "settings", "enabled", "0")
		client_print(id, print_chat, "CSDM - the map will be reloaded to affect the change of this setting.")
		set_task(3.0, "do_changelevel")
	}
	return PLUGIN_HANDLED	
}

public say_respawn(id)
{
	if (g_options[CSDM_OPTION_SAYRESPAWN] == CSDM_SET_DISABLED)
	{
		client_print(id, print_chat, "[CSDM] This command is disabled!")
		return PLUGIN_HANDLED
	}
	
	if (!is_user_alive(id) && csdm_active())
	{
		new team = get_user_team(id)
		if (team == _TEAM_T || team == _TEAM_CT)
		{
			csdm_respawn(id)
		}
	}
	
	return PLUGIN_CONTINUE
}

public do_changelevel()
{
	new current_map[32]
	get_mapname(current_map, 31)
	server_cmd("changelevel %s", current_map)
}
