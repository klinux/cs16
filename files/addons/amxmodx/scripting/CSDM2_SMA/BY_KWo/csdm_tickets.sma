/**
 * csdm_tickets.sma
 * CSDM plugin that lets you have round ticketing.
 *  Every time a player dies their team loses a ticket.  Once all their tickets are used up,
 *  they cannot respawn.
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

#define MAXTICKETS 500

new bool:g_Enabled = false
new g_show_T_state = 1
new g_TicketsNr
new bool:g_TicketPlayer = false
new g_RespawnsTeam[3]

new g_NrTicketsMenu[] = "CSDM: Number of Tickets Menu"
new g_NrTicketsMenuID = -1
new g_RespawnsPlayer[33]
new g_maxplayers

// page info for settings in CSDM Setting Menu
new g_SettingsMenu = 0
new g_TicketSettMenu = 0
new g_ItemsInMenuNr = 0
new g_PageSettMenu = 0

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Ticketing"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "BAILOPAN"

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
	csdm_reg_cfg("ticketing", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);

	register_concmd("csdm_tickets_nr", "csdm_tickets_nr", ADMIN_MAP, "Setup the number of tickets")
	register_clcmd("csdm_ticket_sett_menu", "csdm_ticket_sett_menu", ADMIN_MAP, "CSDM Tickets Settings Menu")

	new main_plugin = module_exists("csdm_main") ? true : false
	
	if (main_plugin)
	{
		g_SettingsMenu = csdm_settings_menu()
		g_ItemsInMenuNr = menu_items(g_SettingsMenu)
		g_PageSettMenu = g_ItemsInMenuNr / 7

		g_TicketSettMenu = menu_create("CSDM Tickets Settings Menu", "use_csdm_ticket_menu")

		menu_additem(g_SettingsMenu, "CSDM Tickets Settings", "csdm_ticket_sett_menu", ADMIN_MAP)

		if (g_TicketSettMenu)
		{
			g_NrTicketsMenuID = menu_create(g_NrTicketsMenu, "m_NrTicketsHandler",0)

		//	CSDM: Ticketing Menu	
			new cb = menu_makecallback("cb_ticket")
			menu_additem(g_TicketSettMenu, "Team ticketing enable/disable", "1", ADMIN_MAP,cb)
			menu_additem(g_TicketSettMenu, "Show ticketing status enable/disable", "2", ADMIN_MAP,cb)
			menu_additem(g_TicketSettMenu, "Change number of tickets", "3", ADMIN_MAP,-1)
			menu_additem(g_TicketSettMenu, "Ticketing counts for teams/players", "4", ADMIN_MAP,cb)
			menu_additem(g_TicketSettMenu, "Back","5", 0, -1)

		//	CSDM: Number of Tickets Menu
			new cb2 = menu_makecallback("cb_nrtickets")
			menu_additem(g_NrTicketsMenuID, "Increase number of tickets", "1", ADMIN_MAP,cb2)
			menu_additem(g_NrTicketsMenuID, "Decrease number of tickets", "2", ADMIN_MAP,cb2)
			menu_additem(g_NrTicketsMenuID, "Back","3", 0, cb2)
		}
	}
	g_maxplayers = get_maxplayers()
	register_event("SendAudio", "eventEndRound", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw")
}

public plugin_cfg()
{
	if ((g_TicketsNr) && (g_Enabled))
	{
		csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_DISABLED)
	}
}

public client_connect(id)
{
	new bool:bAlreadyTicketing = false
	if (g_TicketPlayer)
	{
		for (new i = 1; i <= g_maxplayers; i++)
		{
			if ((g_RespawnsPlayer[i] > 0) && (i != id))
			{
				bAlreadyTicketing = true
				break
			}
		}
		if (bAlreadyTicketing)
			g_RespawnsPlayer[id] = g_TicketsNr
		else
			g_RespawnsPlayer[id] = 0
	}
}

public client_disconnect(id)
{
	g_RespawnsPlayer[id] = 0
}

public csdm_ticket_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_TicketSettMenu, 0)

	return PLUGIN_HANDLED
}

public csdm_tickets_nr(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new S[4]
	new s
	
	read_argv(1, S, 4)
	s = str_to_num(S)

	if (s>0 && s<=MAXTICKETS) {
		g_TicketsNr = s
		console_print(id, "[CSDM] There is currently setuped %d tickets for a %s/round.", s, g_TicketPlayer ? "player":"team")
		client_print(id, print_chat, "[CSDM] There is currently setuped %d tickets for a %s/round.", s, g_TicketPlayer ? "player":"team")
	}
	csdm_write_cfg(id, "ticketing", "tickets", S)

	return PLUGIN_HANDLED
}

public cb_ticket(player, menu, item)
{
	new paccess, cmd[24], call, iName[64]
	menu_item_getinfo(menu, item, paccess, cmd, 23, iName, 63, call)
	new num = str_to_num(cmd)
	switch(num)
	{
		case	1:
		{
			if (!g_Enabled)
			{
				menu_item_setname(menu, item, "Team ticketing Disabled")
			}
			else 
			{
				menu_item_setname(menu, item, "Team ticketing Enabled")
			}
		}
		case	2:
		{
			if (!g_show_T_state)
			{
				menu_item_setname(menu, item, "Show ticketing status - Disabled")
			} 
			else if (g_show_T_state==1)
			{
				menu_item_setname(menu, item, "Show ticketing status as HUD - Enabled")
			} 
			else if (g_show_T_state==2)
			{
				menu_item_setname(menu, item, "Show ticketing status as chat - Enabled")
			}
		}
		case	4:
		{
			if (!g_TicketPlayer)
			{
				menu_item_setname(menu, item, "Ticketing counts for teams")
			} 
			else 
			{
				menu_item_setname(menu, item, "Ticketing counts for players")
			}
		}
	}
	return PLUGIN_HANDLED
}

public cb_nrtickets(player, menu, item)
{
	new paccess, cmd[24], call, iName[64]
	menu_item_getinfo(menu, item, paccess, cmd, 23, iName, 63, call)
	new num = str_to_num(cmd)
	switch(num)
	{
		case	1:
		{
			if (g_TicketsNr>=MAXTICKETS)
			{
				menu_item_setname(menu, item, "Increase number of tickets - limit reached")
				return ITEM_DISABLED
			}
			else 
			{
				menu_item_setname(menu, item, "Increase number of tickets")
				return ITEM_ENABLED
			}
		}
		case	2:
		{
			if (g_TicketsNr<=0)
			{
				menu_item_setname(menu, item, "Decrease number of tickets - limit reached")
				return ITEM_DISABLED
			} 
			else 
			{
				menu_item_setname(menu, item, "Decrease number of tickets")
				return ITEM_ENABLED
			}
		}
		case	3:
		{
			return ITEM_ENABLED
		}
	}
	return PLUGIN_HANDLED
}

public use_csdm_ticket_menu(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_HANDLED
	}

	new command[6], paccess, call
	if (!menu_item_getinfo(g_TicketSettMenu, item, paccess, command, 5, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_TicketSettMenu, 0, item)
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
			if (g_Enabled)
			{
				g_Enabled=false
				client_print(id, print_chat, "CSDM ticketing disabled.")
				csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_ENABLED)
				csdm_write_cfg(id, "ticketing", "enabled", "0")
			} 
			else
			{
				g_Enabled=true
				client_print(id, print_chat, "CSDM ticketing enabled.")
				client_print(id, print_chat, "Write in console >csdm_tickets_nr nr< to change the current available %d tickets for team /round",
					g_TicketsNr)
				if (g_TicketsNr)
					csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_DISABLED)
				csdm_write_cfg(id, "ticketing", "enabled", "1")
			}
			menu_display(id, g_TicketSettMenu, 0)
		}
		case 2:
		{
			if (g_show_T_state == 0)
			{
				g_show_T_state = 1
				client_print(id, print_chat, "CSDM show ticketing state as HUD enabled.")
				csdm_write_cfg(id, "ticketing", "show_state", "1")
			} 
			else if (g_show_T_state == 1)
			{
				g_show_T_state = 2
				client_print(id, print_chat, "CSDM show ticketing state as chat enabled.")
				csdm_write_cfg(id, "ticketing", "show_state", "2")
			} 
			else if (g_show_T_state == 2)
			{
				g_show_T_state = 0
				client_print(id, print_chat, "CSDM show ticketing state disabled.")
				csdm_write_cfg(id, "ticketing", "show_state", "0")
			}
			menu_display(id, g_TicketSettMenu, 0)
		}
		case 3:
		{
			menu_display(id, g_NrTicketsMenuID, 0)
		}
		case 4:
		{
			if (g_TicketPlayer)
			{
				g_TicketPlayer = false
				client_print(id, print_chat, "CSDM ticketing - teams.")
				csdm_write_cfg(id, "ticketing", "ticketing_player", "0")
				g_RespawnsTeam[1] = 0
				g_RespawnsTeam[2] = 0
			} 
			else
			{
				g_TicketPlayer=true
				client_print(id, print_chat, "CSDM ticketing - players.")
				for (new i = 1; i <= g_maxplayers; i++)
				{
					g_RespawnsPlayer[i] = 0
				}
				csdm_write_cfg(id, "ticketing", "ticketing_player", "1")
			}
			menu_display(id, g_TicketSettMenu, 0)
		}
		case 5:
		{
			menu_display(id, g_SettingsMenu, g_PageSettMenu)
		}
	}
	return PLUGIN_HANDLED
}

public m_NrTicketsHandler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_HANDLED
	}
	
	// Get item info
	new cmd[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	new iChoice = str_to_num(cmd)
	
	switch(iChoice)
	{
		case 1:
		{
			if (!cmd_access(id, access, ADMIN_MAP, 1))
			return PLUGIN_HANDLED

			if (g_TicketsNr >= 100 && g_TicketsNr < MAXTICKETS)
			{
				g_TicketsNr	=	g_TicketsNr + 10
				if (g_TicketsNr > MAXTICKETS)	g_TicketsNr = MAXTICKETS
			}

			if (g_TicketsNr >= 40 && g_TicketsNr < 100)
			{
				g_TicketsNr	=	g_TicketsNr + 5
			}
			if (g_TicketsNr >= 20 && g_TicketsNr < 40)
			{
				g_TicketsNr	=	g_TicketsNr + 2
			}
			if (g_TicketsNr < 20)
			{
				g_TicketsNr	=	g_TicketsNr + 1
			}
			console_cmd(id,"csdm_tickets_nr %d", g_TicketsNr)
			menu_display(id, g_NrTicketsMenuID, 0)
		}
		case 2:
		{
			if (!cmd_access(id, access, ADMIN_MAP, 1))
			return PLUGIN_HANDLED
			if (g_TicketsNr > 0 && g_TicketsNr <= 20)
			{
				g_TicketsNr	=	g_TicketsNr - 1
			}
			if (g_TicketsNr > 20 && g_TicketsNr <= 40)
			{
				g_TicketsNr	=	g_TicketsNr - 2
			}
			if (g_TicketsNr > 40 && g_TicketsNr <= 100)
			{
				g_TicketsNr	=	g_TicketsNr - 5
			}
			if (g_TicketsNr > 100 && g_TicketsNr <= MAXTICKETS)
			{
				g_TicketsNr	=	g_TicketsNr - 10
			}
			console_cmd(id,"csdm_tickets_nr %d", g_TicketsNr)
			menu_display(id, g_NrTicketsMenuID, 0)
		}
		case 3:
		{
			menu_display(id, g_TicketSettMenu, 0)
		}
	}
	if ((g_TicketsNr) && (g_Enabled))
		csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_DISABLED)
	else
		csdm_set_mainoption(CSDM_OPTION_SAYRESPAWN, CSDM_SET_ENABLED)

	return PLUGIN_HANDLED
}


public csdm_RoundRestart()
{
	g_RespawnsTeam[_TEAM_T] = 0
	g_RespawnsTeam[_TEAM_CT] = 0
	for (new i = 1; i <= g_maxplayers; i++)
	{
		g_RespawnsPlayer[i] = 0
	}
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled || !csdm_active())
		return PLUGIN_CONTINUE

	if (!g_TicketPlayer)
	{
		new team = get_user_team(victim)

		if (g_RespawnsTeam[team] >= g_TicketsNr)
			return PLUGIN_HANDLED

		g_RespawnsTeam[team]++

		if (g_show_T_state)	update_views(0)
	}
	else if (victim)
	{
		if (g_RespawnsPlayer[victim] >=  g_TicketsNr)
			return PLUGIN_HANDLED

		g_RespawnsPlayer[victim]++

		if (g_show_T_state)	update_views(victim)
	}	
	return PLUGIN_CONTINUE
}

public csdm_PreSpawn(player, bool:fake)
{
	if (!g_Enabled || !fake || !csdm_active())
		return PLUGIN_CONTINUE

	if (!g_TicketPlayer)
	{
		new team = get_user_team(player)
		if (g_RespawnsTeam[team] >= g_TicketsNr)
			return PLUGIN_HANDLED
	}
	else if (player)
	{
		if (g_RespawnsPlayer[player] >=  g_TicketsNr)
			return PLUGIN_HANDLED
	}

	if (g_show_T_state) update_views(player)
	
	return PLUGIN_CONTINUE
}

update_views(id)
{
	//stolen from twisty

	if (!g_TicketPlayer)
	{
		new ct = g_TicketsNr - g_RespawnsTeam[_TEAM_CT]
		new t = g_TicketsNr - g_RespawnsTeam[_TEAM_T]
		if (t < 0)
			t = 0
		if (ct < 0)
			ct = 0
		if (g_show_T_state==1)
		{
			set_hudmessage(255, 255, 255, 0.0, 0.12, 0, 6.0, 240.0, 0.1, 0.1, 4)
			new message[101]
			format(message, 100, "Round Tickets remaining - ^nTerrorists Tickets: %d^nCounter-Terrorist Tickets: %d", t , ct)
			show_hudmessage(id, message)
		}
		if (g_show_T_state==2)
		{
			client_print(id,print_chat, "Round Tickets remaining - Terrorists: %d, Counter-Terrorist: %d", t , ct)
		}
	}
	else if (id)
	{
		set_task(3.0, "show_player_tickets", id)
	}
}

public read_cfg(readAction, line[], section[])
{
	
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "tickets"))
		{
			g_TicketsNr = str_to_num(value)
		} 
		else if (equali(setting, "enabled")) 
		{
			g_Enabled = str_to_num(value) ? true : false
		}
		else if (equali(setting, "ticketing_player"))
		{
			g_TicketPlayer = str_to_num(value) ? true : false
		}
		else if (equali(setting, "show_status"))
			g_show_T_state = str_to_num(value)
	}
}

public show_player_tickets(id)
{
	if (!is_user_connected(id))
		return

	new pl = g_TicketsNr - g_RespawnsPlayer[id]
	if (pl < 0)
		pl = 0
	if (g_show_T_state==1)
	{
		set_hudmessage(255, 255, 255, 0.0, 0.12, 0, 6.0, 12.0, 0.1, 0.1, 4)
		new message[101]
		format(message, 100, "Round Tickets remaining for You: %d", pl)
		show_hudmessage(id, message)
	}
	if (g_show_T_state==2)
	{
		client_print(id,print_chat, "Round Tickets remaining for You: %d", pl)
	}
}

public eventEndRound()
{
	g_RespawnsTeam[_TEAM_T] = 0
	g_RespawnsTeam[_TEAM_CT] = 0
	for (new i = 1; i <= g_maxplayers; i++)
	{
		g_RespawnsPlayer[i] = 0
	}
}
