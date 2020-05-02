/**
 * csdm_misc.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Miscellanious Settings
 *
 * By Freecode and BAILOPAN
 * (C)2003-2006 David "BAILOPAN" Anderson
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

#define MAPSTRIP_VIP		(1<<0)
#define MAPSTRIP_BUY		(1<<1)
#define MAPSTRIP_HOSTAGE	(1<<2)
#define MAPSTRIP_BOMB		(1<<3)

#define HIDE_HUD_TIMER (1<<4)
#define HIDE_HUD_MONEY (1<<5)

new bool:g_BlockBuy = true
new bool:g_AmmoRefill = true
new bool:g_RadioMsg = false
new bool:g_HideMoney = false
new bool:g_HideTimer = false
new bool:g_PluginInitiated = false

#define MAXMENUPOS 34

new const g_sBuyMsg[] = "#Hint_press_buy_" // full: #Hint_press_buy_to_purchase
new g_msgMoney, g_msgHideWeapon, g_msgRoundTime
// new g_msgItemPickup, g_msgAmmoPickup


new g_Aliases[MAXMENUPOS][] = {"usp","glock","deagle","p228","elites","fn57","m3","xm1014","mp5","tmp","p90","mac10","ump45","ak47","galil","famas","sg552","m4a1","aug","scout","awp","g3sg1","sg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"} 
new g_Aliases2[MAXMENUPOS][] = {"km45","9x19mm","nighthawk","228compact","elites","fiveseven","12gauge","autoshotgun","smg","mp","c90","mac10","ump45","cv47","defender","clarion","krieg552","m4a1","bullpup","scout","magnum","d3au1","krieg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"}

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Misc"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "CSDM Team"

new g_MapStripFlags = 0

// page info for settings in CSDM Setting Menu
new g_SettingsMenu = 0
new g_MiscSettMenu = 0
new g_ItemsInMenuNr = 0
new g_PageSettMenu = 0

public plugin_precache()
{
	precache_sound("radio/locknload.wav")
	precache_sound("radio/letsgo.wav")
	
	register_forward(FM_Spawn, "OnEntSpawn")
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
	csdm_reg_cfg("misc", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS)

	g_msgMoney = get_user_msgid("Money")
	g_msgRoundTime = get_user_msgid("RoundTime")
//	g_msgItemPickup = get_user_msgid("ItemPickup")
//	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	g_msgHideWeapon = get_user_msgid("HideWeapon")

	register_message(get_user_msgid("HudTextArgs"), "msgHudTextArgs")
	register_message(g_msgHideWeapon, "msgHideWeapon")

	register_event("CurWeapon", "hook_CurWeapon", "be", "1=1")
	register_event("StatusIcon", "hook_buyzone", "be", "1=1", "1=2", "2=buyzone")
	register_event("ResetHUD", "onResetHUD", "b")

	register_clcmd("buy", "generic_block")
	register_clcmd("buyammo1", "generic_block")
	register_clcmd("buyammo2", "generic_block")
	register_clcmd("buyequip", "generic_block")
	register_clcmd("cl_autobuy", "generic_block")
	register_clcmd("cl_rebuy", "generic_block")
	register_clcmd("cl_setautobuy", "generic_block")
	register_clcmd("cl_setrebuy", "generic_block")
	register_clcmd("csdm_misc_sett_menu", "csdm_misc_sett_menu", ADMIN_MAP, "CSDM Misc Settings Menu")

	register_concmd("csdm_pvlist", "pvlist")

	register_forward(FM_ServerDeactivate, "forward_server_deactivate")

	new main_plugin = module_exists("csdm_main") ? true : false
	if (main_plugin)
	{
		g_SettingsMenu = csdm_settings_menu()
		g_ItemsInMenuNr = menu_items(g_SettingsMenu)
		g_PageSettMenu = g_ItemsInMenuNr / 7

		g_MiscSettMenu = menu_create("CSDM Misc Settings Menu", "use_csdm_misc_menu")

		menu_additem(g_SettingsMenu, "CSDM Misc Settings", "csdm_misc_sett_menu", ADMIN_MAP)

		if (g_MiscSettMenu)
		{
			new callback = menu_makecallback("hook_misc_sett_display")
			menu_additem(g_MiscSettMenu, "Strip Objectives for as_ maps Enabled/Disabled", "1", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Strip Buyzones from maps Enabled/Disabled", "2", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Strip Objectives for cs_ maps Enabled/Disabled", "3", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Strip Objectives for de_ maps Enabled/Disabled", "4", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Block Buy Enabled/Disabled", "5", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Ammo Refill Enabled/Disabled", "6", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Radio Message at Respawn Enabled/Disabled", "7", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Hide Money Enabled/Disabled", "8", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Hide Timer Enabled/Disabled", "9", ADMIN_MAP, callback)
			menu_additem(g_MiscSettMenu, "Back", "10", 0, -1)
		}
	}
	set_task(2.0, "DoMapStrips")

	g_PluginInitiated = true
}

public plugin_cfg()
{
	if (csdm_active() && g_HideMoney && g_BlockBuy && get_msg_block(g_msgMoney) != BLOCK_SET)
		set_msg_block(g_msgMoney, BLOCK_SET)
			
	new bool:bRemoveAllObjectives = (g_MapStripFlags & MAPSTRIP_VIP) 
		&& (g_MapStripFlags & MAPSTRIP_HOSTAGE) && (g_MapStripFlags & MAPSTRIP_BOMB)

	if(csdm_active() && bRemoveAllObjectives && g_HideTimer && get_msg_block(g_msgRoundTime) != BLOCK_SET)
		set_msg_block(g_msgRoundTime, BLOCK_SET)
}

public csdm_StateChange(csdm_state)
{
	if ((csdm_state == CSDM_ENABLE) && g_PluginInitiated)
	{
	   set_task(2.0, "DoMapStrips")
	}
	else if (csdm_state == CSDM_DISABLE)
	{
		if (!g_msgMoney)
			g_msgMoney = get_user_msgid("Money")
		if (g_msgMoney)
		{
			if(get_msg_block(g_msgMoney) == BLOCK_SET)
				set_msg_block(g_msgMoney, BLOCK_NOT)
		}
		if (!g_msgRoundTime)
			g_msgRoundTime = get_user_msgid("RoundTime")
		if (g_msgRoundTime)
		{
			if(get_msg_block(g_msgRoundTime) == BLOCK_SET)
				set_msg_block(g_msgRoundTime, BLOCK_NOT)
		}
	}
}

public forward_server_deactivate()
{
	g_PluginInitiated = false
	return FMRES_IGNORED
}

public hook_buyzone(id)
{
	if (!csdm_active()) return PLUGIN_CONTINUE

	if (g_MapStripFlags & MAPSTRIP_BUY)
	{	
		message_begin(MSG_ONE,get_user_msgid("StatusIcon"),{0,0,0},id)
		write_byte(0) // status (0=hide, 1=show, 2=flash)
		write_string("buyzone") // sprite name
		write_byte(0) // red
		write_byte(0) // green
		write_byte(0) // blue
		message_end()		
	}
	return PLUGIN_CONTINUE
}

public msgHudTextArgs(msg_id, msg_dest, msg_entity)
{
	if (!csdm_active()) return PLUGIN_CONTINUE

	if ((g_MapStripFlags & MAPSTRIP_BUY) || g_BlockBuy)
	{
		static sTemp[sizeof(g_sBuyMsg)]
		get_msg_arg_string(1, sTemp, sizeof(sTemp)-1)
		if(equal(sTemp, g_sBuyMsg))
			return PLUGIN_HANDLED
	} 
	return PLUGIN_CONTINUE
}

public onResetHUD(id)
{
	if(!csdm_active())
		return

	if (!id)
		return
	if (is_user_bot(id))
		return

	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
	{
		message_begin(MSG_ONE, g_msgHideWeapon, _, id)
		write_byte(iHideFlags)
		message_end()
	}
}

public msgHideWeapon()
{
	if(!csdm_active())
		return

	new iHideFlags = GetHudHideFlags()
	if(iHideFlags)
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags)
}

stock GetHudHideFlags()
{
	new iFlags
	if(g_BlockBuy && g_HideMoney)
		iFlags |= HIDE_HUD_MONEY

	new bool:bRemoveAllObjectives = (g_MapStripFlags & MAPSTRIP_VIP) 
		&& (g_MapStripFlags & MAPSTRIP_HOSTAGE) && (g_MapStripFlags & MAPSTRIP_BOMB)

	if (bRemoveAllObjectives && g_HideTimer)
		iFlags |= HIDE_HUD_TIMER

	return iFlags
}

public OnEntSpawn(ent)
{
	if ((g_MapStripFlags & MAPSTRIP_HOSTAGE) && csdm_active())
	{
		new classname[32]
		if (pev_valid(ent))
		{		
			pev(ent, pev_classname, classname, 31)

			if (equal(classname, "hostage_entity"))
			{
				engfunc(EngFunc_RemoveEntity, ent)
				return FMRES_SUPERCEDE
			}
		}
	}

	return FMRES_IGNORED
}

public pvlist(id, level, cid)
{
	new players[32], num, pv, name[32]
	get_players(players, num)
	
	for (new i=0; i<num; i++)
	{
		pv = players[i]
		get_user_name(pv, name, 31)
		console_print(id, "[CSDM] Player %s flags: %d deadflags: %d", name, pev(pv, pev_flags), pev(pv, pev_deadflag))
	}
	
	return PLUGIN_HANDLED
}

public generic_block(id, level, cid)
{
	if (csdm_active() && g_BlockBuy)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public csdm_PostSpawn(player, bool:fake)
{
	if (g_RadioMsg && !is_user_bot(player) && csdm_active())
	{
		if (get_user_team(player) == _TEAM_T)
		{
			client_cmd(player, "spk radio/letsgo")
		} else {
			client_cmd(player, "spk radio/locknload")
		}
	}
}

public client_command(id)
{
	if (csdm_active() && g_BlockBuy)
	{
		new arg[13]
		if (read_argv(0, arg, 12) > 11)
		{
			return PLUGIN_CONTINUE 
		}
		new a = 0 
		do {
			if (equali(g_Aliases[a], arg) || equali(g_Aliases2[a], arg))
			{ 
				return PLUGIN_HANDLED 
			}
		} while(++a < MAXMENUPOS)
	}
	
	return PLUGIN_CONTINUE 
} 

public hook_CurWeapon(id)
{
	if (!g_AmmoRefill || !csdm_active())
	{
		return
	}
	
	new wp = read_data(2)
	
	if (g_WeaponSlots[wp] == SLOT_PRIMARY || g_WeaponSlots[wp] == SLOT_SECONDARY)
	{
		new ammo = cs_get_user_bpammo(id, wp)
		
		if (ammo < g_MaxBPAmmo[wp])
		{
			cs_set_user_bpammo(id, wp, g_MaxBPAmmo[wp])
		}
	}
}

public DoMapStrips()
{
	if (!csdm_active())
		return

	new mapname[24]
	get_mapname(mapname, 23)
	if ((g_MapStripFlags & MAPSTRIP_BOMB) /* && (containi(mapname, "de_") != -1) */)
	{
		RemoveEntityAll("func_bomb_target")
		RemoveEntityAll("info_bomb_target")
	}

	if ((g_MapStripFlags & MAPSTRIP_VIP) /* && (containi(mapname, "as_") != -1) */)
	{
		RemoveEntityAll("func_vip_safetyzone")
		RemoveEntityAll("info_vip_start")
	}
	if ((g_MapStripFlags & MAPSTRIP_HOSTAGE) /* && (containi(mapname, "cs_") != -1) */)
	{
		RemoveEntityAll("func_hostage_rescue")
		RemoveEntityAll("info_hostage_rescue")
	}

	if (g_MapStripFlags & MAPSTRIP_BUY)
	{
		RemoveEntityAll("func_buyzone")
	}
}

public read_cfg(readAction, line[], section[])
{		
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "remove_objectives"))
		{
			new mapname[24]
			get_mapname(mapname, 23)
			
			if (containi(value, "d") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_BOMB
			}
			if (containi(value, "a") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_VIP
			}
			if (containi(value, "c") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_HOSTAGE
			}
			if (containi(value, "b") != -1)
			{
				g_MapStripFlags |= MAPSTRIP_BUY
			}
		} else if (equali(setting, "block_buy")) {
			g_BlockBuy = str_to_num(value) ? true : false
		} else if (equali(setting, "ammo_refill")) {
			g_AmmoRefill = str_to_num(value) ? true : false
		} else if (equali(setting, "spawn_radio_msg")) {
			g_RadioMsg = str_to_num(value) ? true : false
		} else if (equali(setting, "hide_money")) {
			g_HideMoney = str_to_num(value) ? true : false
		} else if (equali(setting, "hide_timer")) {
			g_HideTimer = str_to_num(value) ? true : false
		}
	} else if (readAction == CFG_RELOAD) {
		g_MapStripFlags = 0
		g_BlockBuy = true
		g_AmmoRefill = true
		g_RadioMsg = false
	}
}

stock RemoveEntityAll(name[])
{
	new ent = engfunc(EngFunc_FindEntityByString, 0, "classname", name)
	new temp
	while (ent)
	{
		temp = engfunc(EngFunc_FindEntityByString, ent, "classname", name)
		engfunc(EngFunc_RemoveEntity, ent)
		ent = temp
	}
}

// stuff for settings menu - START
public csdm_misc_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_MiscSettMenu, 0)

	return PLUGIN_HANDLED
}

public use_csdm_misc_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE

	new command[6], paccess, call
	if (!menu_item_getinfo(g_MiscSettMenu, item, paccess, command, 5, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_MiscSettMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}

	new iChoice = str_to_num(command)
	
	switch(iChoice)
	{
		case 1:
		{
			new strip_as = g_MapStripFlags & MAPSTRIP_VIP
			if (strip_as)
				g_MapStripFlags &= ~MAPSTRIP_VIP
			else
				g_MapStripFlags |= MAPSTRIP_VIP

			client_print(id, print_chat, "CSDM removig objectives for as_ maps %s.", (g_MapStripFlags & MAPSTRIP_VIP) ? "enabled" : "disabled")
			log_amx("CSDM removig objectives for as_ maps %s.", (g_MapStripFlags & MAPSTRIP_VIP) ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)

			new flags[5] = ""
			get_flags(g_MapStripFlags, flags, 4)
			csdm_write_cfg(id, "misc", "remove_objectives", flags)
			client_print(id,print_chat,"CSDM - changing this setting will affect the game after changelevel command")

			return PLUGIN_HANDLED
		}
		case 2:
		{
			new strip_buy = g_MapStripFlags & MAPSTRIP_BUY
			if (strip_buy)
				g_MapStripFlags &= ~MAPSTRIP_BUY
			else
				g_MapStripFlags |= MAPSTRIP_BUY

			client_print(id, print_chat, "CSDM removig buyzones from maps %s.", (g_MapStripFlags & MAPSTRIP_BUY) ? "enabled" : "disabled")
			log_amx("CSDM removig buyzones for maps %s.", (g_MapStripFlags & MAPSTRIP_BUY) ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)

			new flags[5] = ""
			get_flags(g_MapStripFlags, flags, 4)
			csdm_write_cfg(id, "misc", "remove_objectives", flags)
			client_print(id,print_chat,"CSDM - changing this setting will affect the game after changelevel command")

			return PLUGIN_HANDLED
		}
		case 3:
		{
			new strip_cs = g_MapStripFlags & MAPSTRIP_HOSTAGE
			if (strip_cs)
				g_MapStripFlags &= ~MAPSTRIP_HOSTAGE
			else
				g_MapStripFlags |= MAPSTRIP_HOSTAGE

			client_print(id, print_chat, "CSDM removig objectives for cs_ maps %s.", (g_MapStripFlags & MAPSTRIP_HOSTAGE) ? "enabled" : "disabled")
			log_amx("CSDM removig objectives for cs_ maps %s.", (g_MapStripFlags & MAPSTRIP_HOSTAGE) ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)

			new flags[5] = ""
			get_flags(g_MapStripFlags, flags, 4)
			csdm_write_cfg(id, "misc", "remove_objectives", flags)
			client_print(id,print_chat,"CSDM - changing this setting will affect the game after changelevel command")

			return PLUGIN_HANDLED
		}
		case 4:
		{
			new strip_de = g_MapStripFlags & MAPSTRIP_BOMB
			if (strip_de)
				g_MapStripFlags &= ~MAPSTRIP_BOMB
			else
				g_MapStripFlags |= MAPSTRIP_BOMB

			client_print(id, print_chat, "CSDM removig objectives for de_ maps %s.", (g_MapStripFlags & MAPSTRIP_BOMB) ? "enabled" : "disabled")
			log_amx("CSDM removig objectives for de_ maps %s.", (g_MapStripFlags & MAPSTRIP_BOMB) ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)

			new flags[5] = ""
			get_flags(g_MapStripFlags, flags, 4)
			csdm_write_cfg(id, "misc", "remove_objectives", flags)
			client_print(id,print_chat,"CSDM - changing this setting will affect the game after changelevel command")

			return PLUGIN_HANDLED
		}
		case 5:
		{
			g_BlockBuy = g_BlockBuy? false : true

			client_print(id, print_chat, "CSDM block buy %s.", g_BlockBuy ? "enabled" : "disabled")
			log_amx("CSDM block buy %s.", g_BlockBuy ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)
			csdm_write_cfg(id, "misc", "block_buy", g_BlockBuy ? "1" : "0")

			if (g_HideMoney && g_BlockBuy && (get_msg_block(g_msgMoney) != BLOCK_SET) && csdm_active())
				set_msg_block(g_msgMoney, BLOCK_SET)
			else if(get_msg_block(g_msgMoney) == BLOCK_SET)
				set_msg_block(g_msgMoney, BLOCK_NOT)

			return PLUGIN_HANDLED
		}
		case 6:
		{
			g_AmmoRefill = g_AmmoRefill? false : true

			client_print(id, print_chat, "CSDM ammo refill %s.", g_AmmoRefill ? "enabled" : "disabled")
			log_amx("CSDM ammo refill %s.", g_AmmoRefill ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)
			csdm_write_cfg(id, "misc", "ammo_refill", g_AmmoRefill ? "1" : "0")
			return PLUGIN_HANDLED
		}
		case 7:
		{
			g_RadioMsg = g_RadioMsg? false : true

			client_print(id, print_chat, "CSDM radio message %s.", g_RadioMsg ? "enabled" : "disabled")
			log_amx("CSDM radio message %s.", g_RadioMsg ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 0)
			csdm_write_cfg(id, "misc", "spawn_radio_msg", g_RadioMsg ? "1" : "0")
			return PLUGIN_HANDLED
		}
		case 8:
		{
			g_HideMoney = g_HideMoney? false : true

			client_print(id, print_chat, "CSDM hide money %s.", g_HideMoney ? "enabled" : "disabled")
			log_amx("CSDM hide money %s.", g_HideMoney ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 1)
			csdm_write_cfg(id, "misc", "hide_money", g_HideMoney ? "1" : "0")

			if (g_HideMoney && g_BlockBuy && (get_msg_block(g_msgMoney) != BLOCK_SET) && csdm_active())
				set_msg_block(g_msgMoney, BLOCK_SET)
			else if(get_msg_block(g_msgMoney) == BLOCK_SET)
				set_msg_block(g_msgMoney, BLOCK_NOT)

			return PLUGIN_HANDLED
		}
		case 9:
		{
			g_HideTimer = g_HideTimer? false : true

			client_print(id, print_chat, "CSDM hide timer %s.", g_HideTimer ? "enabled" : "disabled")
			log_amx("CSDM hide timer %s.", g_HideTimer ? "enabled" : "disabled")

			menu_display(id, g_MiscSettMenu, 1)
			csdm_write_cfg(id, "misc", "hide_timer", g_HideTimer ? "1" : "0")

			new bool:bRemoveAllObjectives = (g_MapStripFlags & MAPSTRIP_VIP) 
				&& (g_MapStripFlags & MAPSTRIP_HOSTAGE) && (g_MapStripFlags & MAPSTRIP_BOMB)

			if(bRemoveAllObjectives && g_HideTimer && (get_msg_block(g_msgRoundTime) != BLOCK_SET) && csdm_active())
				set_msg_block(g_msgRoundTime, BLOCK_SET)
			else if(get_msg_block(g_msgRoundTime) == BLOCK_SET)
				set_msg_block(g_msgRoundTime, BLOCK_NOT)

			return PLUGIN_HANDLED
		}
		case 10:
		{
			menu_display(id, g_SettingsMenu, g_PageSettMenu)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}

public hook_misc_sett_display(player, menu, item)
{
	new paccess, command[6], call
	
	menu_item_getinfo(menu, item, paccess, command, 5, _, 0, call)
	
	if (equali(command, "1"))
	{
		if (g_MapStripFlags & MAPSTRIP_VIP)
		{
			menu_item_setname(menu, item, "Strip Objectives for as_ maps Enabled")
		} else {
			menu_item_setname(menu, item, "Strip Objectives for as_ maps Disabled")
		}
	}
	else if (equali(command, "2"))
	{
		if (g_MapStripFlags & MAPSTRIP_BUY)
		{
			menu_item_setname(menu, item, "Strip Buyzones from maps Enabled")
		} else {
			menu_item_setname(menu, item, "Strip Buyzones from maps Disabled")
		}
	}
	else if (equali(command, "3"))
	{
		if (g_MapStripFlags & MAPSTRIP_HOSTAGE)
		{
			menu_item_setname(menu, item, "Strip Objectives for cs_ maps Enabled")
		} else {
			menu_item_setname(menu, item, "Strip Objectives for cs_ maps Disabled")
		}
	}
	else if (equali(command, "4"))
	{
		if (g_MapStripFlags & MAPSTRIP_BOMB)
		{
			menu_item_setname(menu, item, "Strip Objectives for de_ maps Enabled")
		} else {
			menu_item_setname(menu, item, "Strip Objectives for de_ maps Disabled")
		}
	}
	else if (equali(command, "5"))
	{
		if (g_BlockBuy)
		{
			menu_item_setname(menu, item, "Block Buy Enabled")
		} else {
			menu_item_setname(menu, item, "Block Buy Disabled")
		}
	}
	else if (equali(command, "6"))
	{
		if (g_AmmoRefill)
		{
			menu_item_setname(menu, item, "Ammo Refill Enabled")
		} else {
			menu_item_setname(menu, item, "Ammo Refill Disabled")
		}
	}
	else if (equali(command, "7"))
	{
		if (g_RadioMsg)
		{
			menu_item_setname(menu, item, "Radio Message at Respawn Enabled")
		} else {
			menu_item_setname(menu, item, "Radio Message at Respawn Disabled")
		}
	}
	else if (equali(command, "8"))
	{
		if (g_HideMoney)
		{
			menu_item_setname(menu, item, "Hide Money Enabled")
		} else {
			menu_item_setname(menu, item, "Hide Money Disabled")
		}
	}
	else if (equali(command, "9"))
	{
		if (g_HideTimer)
		{
			menu_item_setname(menu, item, "Hide Timer Enabled")
		} else {
			menu_item_setname(menu, item, "Hide Timer Disabled")
		}
	}
}

// stuff for settings menu - END
