/*
 * csdm_protection.sma
 * CSDM plugin that lets you have spawn protection
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
#include <fakemeta>
#include <engine_const>
#include <csdm>

new g_ProtColors[4][3] = {{0,0,0},{255,0,0},{0,0,255},{0,255,0}}
new g_GlowAlpha[4] = {200,200,200,200}

new g_Protected[33]
new bool:g_Enabled = false
new bool:g_Glowing = false
new Float:g_ProtTime = 2.0

new const g_iProtectionOffFlags = IN_ATTACK | IN_ATTACK2 | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT

new bool:g_MainPlugin = true

// page info for settings in CSDM Setting Menu
new g_SettingsMenu = 0
new g_ProtSettMenu = 0
new g_ItemsInMenuNr = 0
new g_PageSettMenu = 0

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Protection"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "BAILOPAN"
new ACCESS    = ADMIN_MAP

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
	csdm_reg_cfg("protection", "read_cfg")
}

stock set_rendering(index, fx=kRenderFxNone, r=255, g=255, b=255, render=kRenderNormal, amount=16)
{
	set_pev(index, pev_renderfx, fx)
	new Float:RenderColor[3]
	RenderColor[0] = float(r)
	RenderColor[1] = float(g)
	RenderColor[2] = float(b)
	set_pev(index, pev_rendercolor, RenderColor)
	set_pev(index, pev_rendermode, render)
	set_pev(index, pev_renderamt, float(amount))

	return 1
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS)
	register_forward(FM_PlayerPreThink, "On_ClientPreThink", 1)
	register_clcmd("csdm_prot_sett_menu", "csdm_prot_sett_menu", ACCESS, "CSDM Protection Settings Menu")

	g_MainPlugin = module_exists("csdm_main") ? true : false	
	if (g_MainPlugin)
	{
		g_SettingsMenu = csdm_settings_menu()
		g_ItemsInMenuNr = menu_items(g_SettingsMenu)
		g_PageSettMenu = g_ItemsInMenuNr / 7
		g_ProtSettMenu = menu_create("CSDM Protection Settings Menu", "use_csdm_prot_menu")

		menu_additem(g_SettingsMenu, "CSDM Protection Settings", "csdm_prot_sett_menu", ACCESS)

		if (g_ProtSettMenu)
		{
			new cb_protect = menu_makecallback("hook_prot_sett_display")
			menu_additem(g_ProtSettMenu, "Spawn Protection Enabled/Disabled", "1", ACCESS, cb_protect)
			menu_additem(g_ProtSettMenu, "Glowing on Spawn Enabled/Disabled", "2", ACCESS, cb_protect)
			menu_additem(g_ProtSettMenu, "Back", "3", 0, -1)
		}
	}
}

public client_connect(id)
{
	g_Protected[id] = 0
}

public client_disconnect(id)
{
	if (g_Protected[id])
	{
		remove_task(g_Protected[id])
		g_Protected[id] = 0
	}
}

SetProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	if (!is_user_connected(id))
		return
		
	new team = get_user_team(id)
	
	if (!IsValidTeam(team))
	{
		return
	}

	if (!pev(id, pev_takedamage) && !g_Protected[id]) // against other plugins controlling the protection
	{
		//log_amx("can't set protection on player[%d]", id)
//		g_Protected[id] = 0
		return
	}

	set_task(g_ProtTime, "ProtectionOver", id)
	g_Protected[id] = id

	if (g_Glowing)
	{
		if (!csdm_get_ffa())
			set_rendering(id, kRenderFxGlowShell, g_ProtColors[team][0], g_ProtColors[team][1], g_ProtColors[team][2], 
				kRenderNormal, g_GlowAlpha[team])
		else
			set_rendering(id, kRenderFxGlowShell, g_ProtColors[3][0], g_ProtColors[3][1], g_ProtColors[3][2], 
				kRenderNormal, g_GlowAlpha[3])
	}
	set_pev(id, pev_takedamage, 0.0)
}

RemoveProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	ProtectionOver(id)
}

public ProtectionOver(id)
{
	g_Protected[id] = 0
	
	if (!is_user_connected(id))
		return
	
	set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	set_pev(id, pev_takedamage, 2.0)
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled || !csdm_active())
		return
		
	RemoveProtection(victim)
}

public csdm_PostSpawn(player, bool:fake)
{
	if ((g_Enabled) && csdm_active())
		SetProtection(player)
}

public On_ClientPreThink(id)
{
	if (!g_Enabled || !g_Protected[id] || !is_user_connected(id) || !csdm_active())
		return
	
	new buttons = pev(id,pev_button);

	if ( buttons & g_iProtectionOffFlags )
	{
		RemoveProtection(id)
	}
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "colorst"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)
			
			g_ProtColors[_TEAM_T][0] = str_to_num(red)
			g_ProtColors[_TEAM_T][1] = str_to_num(green)
			g_ProtColors[_TEAM_T][2] = str_to_num(blue)
			g_GlowAlpha[_TEAM_T] = str_to_num(alpha)
		}
		else if (equali(setting, "colorsct"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)
			
			g_ProtColors[_TEAM_CT][0] = str_to_num(red)
			g_ProtColors[_TEAM_CT][1] = str_to_num(green)
			g_ProtColors[_TEAM_CT][2] = str_to_num(blue)
			g_GlowAlpha[_TEAM_CT] = str_to_num(alpha)
		}
		else if (equali(setting, "colorsffa"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)

			g_ProtColors[3][0] = str_to_num(red)
			g_ProtColors[3][1] = str_to_num(green)
			g_ProtColors[3][2] = str_to_num(blue)
			g_GlowAlpha[3] = str_to_num(alpha)
		}
		else if (equali(setting, "enabled"))
		{
			g_Enabled = str_to_num(value) ? true : false
		}
		else if (equali(setting, "glowing")) 
		{
			g_Glowing = str_to_num(value) ? true : false
		}
		else if (equali(setting, "time")) 
		{
			g_ProtTime = str_to_float(value)
		}
	}
}

// stuff for settings menu - START
public csdm_prot_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_ProtSettMenu, 0)

	return PLUGIN_HANDLED
}

public use_csdm_prot_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE

	new command[6], paccess, call
	if (!menu_item_getinfo(g_ProtSettMenu, item, paccess, command, 5, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_ProtSettMenu, 0, item)
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
			g_Enabled = (g_Enabled ? false : true)

			client_print(id, print_chat, "[CSDM] CSDM Spawn Protection setting changed to %s.", g_Enabled ? "enabled" : "disabled")

			csdm_write_cfg(id, "protection", "enabled", g_Enabled ? "1" : "0")
			menu_display(id, g_ProtSettMenu, 0)
			return PLUGIN_HANDLED
		}
		case 2:
		{
			g_Glowing = (g_Glowing ? false : true)

			client_print(id, print_chat, "[CSDM] CSDM Spawn Glowing setting changed to %s.", g_Glowing ? "enabled" : "disabled")

			csdm_write_cfg(id, "protection", "glowing", g_Glowing ? "1" : "0")
			menu_display(id, g_ProtSettMenu, 0)
			return PLUGIN_HANDLED
		}
		case 3:
		{
			menu_display(id, g_SettingsMenu, g_PageSettMenu)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}

public hook_prot_sett_display(player, menu, item)
{
	new paccess, command[6], call
	
	menu_item_getinfo(menu, item, paccess, command, 5, _, 0, call)
	
	if (equali(command, "1"))
	{	
		if (!g_Enabled)
		{
			menu_item_setname(menu, item, "Spawn Protection Disabled")
		} else {
			menu_item_setname(menu, item, "Spawn Protection Enabled")
		}
	}
	else if (equali(command, "2"))
	{
		if (!g_Glowing)
		{
			menu_item_setname(menu, item, "Spawn Glowing Disabled")
		} else {
			menu_item_setname(menu, item, "Spawn Glowing Enabled")
		}
	}
}
// stuff for settings menu - END
