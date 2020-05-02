#include <amxmodx>
#include <amxmisc>
// #include <cstrike>
#include <engine>

new PLUGINNAME[] = "Rendering Test"
new VERSION[] = "1.1"
new AUTHORS[] = "KWo"
new gPlayerId = 0
new gFxType = kRenderFxNone
new gColor[3] = {255, 255, 255}
new gRenderMode = kRenderNormal
new gRenderAmount = 16

new gFxName[21][] = {	"kRenderFxNone", "kRenderFxPulseSlow", "kRenderFxPulseFast", "kRenderFxPulseSlowWide",
											"kRenderFxPulseFastWide", "kRenderFxFadeSlow", "kRenderFxFadeFast","kRenderFxSolidSlow", 
											"kRenderFxSolidFast", "kRenderFxStrobeSlow", "kRenderFxStrobeFast", "kRenderFxStrobeFaster",
											"kRenderFxFlickerSlow", "kRenderFxFlickerFast", "kRenderFxNoDissipation", "kRenderFxDistort", 
											"kRenderFxHologram", "kRenderFxDeadPlayer", "kRenderFxExplode", "kRenderFxGlowShell",
											"kRenderFxClampMinScale" }

new gRenderModeName[6][] = {"kRenderNormal", "kRenderTransColor", "kRenderTransTexture",
														"kRenderGlow", "kRenderTransAlpha", "kRenderTransAdd"}
new gPlayers[32]

//Menus
new g_MainMenu[] = "Main Rendering Menu"
new g_MainMenuID = -1
new g_PlayerMenu[] = "Choose Player For Rendering Menu"
new g_PlayerMenuID = -1
new g_FxMenu[] = "Render Effect Choose Menu"
new g_FxMenuID = -1
new g_ColorMenu[] = "Render RGB Choose Menu"
new g_ColorMenuID = -1	
new g_RenderModeMenu[] = "Render Mode Choose Menu"
new g_RenderModeMenuID = -1	
new g_RenderAmountMenu[] = "Render Amount Choose Menu"
new g_RenderAmountMenuID = -1	

/*
Render Fx:
	kRenderFxNone
	kRenderFxPulseSlow
	kRenderFxPulseFast
	kRenderFxPulseSlowWide
	kRenderFxPulseFastWide
	kRenderFxFadeSlow
	kRenderFxFadeFast
	kRenderFxSolidSlow
	kRenderFxSolidFast
	kRenderFxStrobeSlow
	kRenderFxStrobeFast
	kRenderFxStrobeFaster
	kRenderFxFlickerSlow
	kRenderFxFlickerFast
	kRenderFxNoDissipation
	kRenderFxDistort
	kRenderFxHologram
	kRenderFxDeadPlayer
	kRenderFxExplode
	kRenderFxGlowShell

Render Mode:
	kRenderNormal
	kRenderTransColor
	kRenderTransTexture
	kRenderGlow
	kRenderTransAlpha
	kRenderTransAdd
*/


public plugin_init()
{	
	register_plugin(PLUGINNAME, VERSION, AUTHORS)
	register_clcmd("rendering_menu", "rendering_menu", ADMIN_MAP, "Rendering Menu")
	AddMenuItem("Rendering Menu", "rendering_menu", ADMIN_MAP, PLUGINNAME)

	register_concmd("amx_set_rendering","amx_set_rendering",ADMIN_MAP,"Sets the rendering for the player")
	register_concmd("amx_get_rendering","amx_get_rendering",ADMIN_MAP,"Gets the rendering of the player")

	g_MainMenuID = menu_create(g_MainMenu, "m_mm_handler", 0)
	g_PlayerMenuID = menu_create(g_PlayerMenu, "m_pm_handler", 0)
	g_FxMenuID = menu_create(g_FxMenu, "m_fxm_handler", 0)
	g_ColorMenuID = menu_create(g_ColorMenu, "m_cm_handler", 0)
	g_RenderModeMenuID = menu_create(g_RenderModeMenu, "m_rmm_handler", 0)
	g_RenderAmountMenuID = menu_create(g_RenderAmountMenu, "m_ram_handler", 0)

	menu_additem(g_MainMenuID, g_PlayerMenu, "1", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, g_FxMenu, "2", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, g_ColorMenu, "3", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, g_RenderModeMenu, "4", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, g_RenderAmountMenu, "5", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, "Set Rendering on The Player", "6", ADMIN_MAP, -1)
	menu_additem(g_MainMenuID, "Get Rendering of The Player", "7", ADMIN_MAP, -1)

	menu_additem(g_FxMenuID, "kRenderFxNone", "1", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxPulseSlow", "2", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxPulseFast", "3", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxPulseSlowWide", "4", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxPulseFastWide", "5", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxFadeSlow", "6", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxFadeFast", "7", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxSolidSlow", "8", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxSolidFast", "9", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxStrobeSlow", "10", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxStrobeFast", "11", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxStrobeFaster", "12", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxFlickerSlow", "13", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxFlickerFast", "14", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxNoDissipation", "15", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxDistort", "16", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxHologram", "17", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxDeadPlayer", "18", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxExplode", "19", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "kRenderFxGlowShell", "20", ADMIN_MAP, -1)
	menu_additem(g_FxMenuID, "Back to the Main Menu", "21", ADMIN_MAP, -1)

	menu_additem(g_ColorMenuID, "Increase R", "1", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Decrease R", "2", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Increase G", "3", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Decrease G", "4", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Increase B", "5", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Decrease B", "6", ADMIN_MAP, -1)
	menu_additem(g_ColorMenuID, "Back to the Main Menu", "7", ADMIN_MAP, -1)

	menu_additem(g_RenderModeMenuID, "kRenderNormal", "1", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "kRenderTransColor", "2", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "kRenderTransTexture", "3", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "kRenderGlow", "4", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "kRenderTransAlpha", "5", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "kRenderTransAdd", "6", ADMIN_MAP, -1)
	menu_additem(g_RenderModeMenuID, "Back to the Main Menu", "7", ADMIN_MAP, -1)

	menu_additem(g_RenderAmountMenuID, "Increase Render Amount", "1", ADMIN_MAP, -1)
	menu_additem(g_RenderAmountMenuID, "Decrease Render Amount", "2", ADMIN_MAP, -1)
	menu_additem(g_RenderAmountMenuID, "Back to the Main Menu", "3", ADMIN_MAP, -1)

}

public client_connect(id)
{
	new UserName[32], ItemName[2]
	new item_id
	if ((g_PlayerMenuID > 0) && (id))
	{
		item_id = menu_items(g_PlayerMenuID) + 1
		num_to_str(item_id, ItemName, 2)
		get_user_name(id, UserName, 31)
		menu_additem(g_PlayerMenuID, UserName, ItemName, ADMIN_MAP, -1)
		gPlayers[item_id - 1] = id
	}
}

public client_disconnect(id)
{
	if (gPlayerId == id)
		gPlayerId = -1
	for (new i = 0; i < 32; i++)
	{
		if (gPlayers[i] == id)
		{
			gPlayers[i] = -1
		}
	}
}

public rendering_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	menu_display(id, g_MainMenuID, 0)	

	return PLUGIN_HANDLED	
}

public amx_set_rendering(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (gPlayerId == 0)
	{
		client_print(id, print_chat, "Player for rendering test not selected.")
		return PLUGIN_HANDLED
	}
	else if (gPlayerId == -1)
	{
		client_print(id, print_chat, "Selected player not in game.")
		return PLUGIN_HANDLED
	}
	else if (!is_user_connected(gPlayerId))
	{
		client_print(id, print_chat, "Selected player not in game.")
		return PLUGIN_HANDLED
	}
	else if (!is_user_alive(gPlayerId))
	{
		client_print(id, print_chat, "Selected player not alive.")
		return PLUGIN_HANDLED
	}
	if ((gFxType < 0) || (gFxType > 20))
	{
		client_print(id, print_chat, "Selected Fx out of range.")
		return PLUGIN_HANDLED
	}
	if ((gColor[0] < 0) || (gColor[0] > 255) || (gColor[1] < 0) || (gColor[1] > 255)
		|| (gColor[2] < 0) || (gColor[2] > 255))
	{
		client_print(id, print_chat, "Selected Rendering Color parameters out of range.")
		return PLUGIN_HANDLED
	}
	if ((gRenderMode < 0) || (gRenderMode > 5))
	{
		client_print(id, print_chat, "Selected Rendering Mode out of range.")
		return PLUGIN_HANDLED
	}
	if ((gRenderAmount < 0) || (gRenderAmount > 255))
	{
		client_print(id, print_chat, "Selected Rendering Amount out of range.")
		return PLUGIN_HANDLED
	}
	new name[32]
	get_user_name(gPlayerId, name, 31)
	set_rendering(gPlayerId, gFxType, gColor[0], gColor[1], gColor[2], gRenderMode, gRenderAmount)
	client_print(id, print_chat,"The rendering for player %s was set: FxType = %s, r = %d, g = %d, b = %d", 
		name, gFxName[gFxType], gColor[0], gColor[1], gColor[2])
 	client_print(id, print_chat,"RenderMode = %s, RenderAmount = %d.", gRenderModeName[gRenderMode], gRenderAmount)

	return PLUGIN_HANDLED	
}

public amx_get_rendering(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if (!gPlayerId)
	{
		client_print(id, print_chat, "Player for rendering check not selected.")
		return PLUGIN_HANDLED
	}
	if (!is_user_connected(gPlayerId))
	{
		client_print(id, print_chat, "Selected player not in game.")
		return PLUGIN_HANDLED
	}
	if (!is_user_alive(gPlayerId))
	{
		client_print(id, print_chat, "Selected player not alive.")
		return PLUGIN_HANDLED
	}
	new name[32]
	new FxType, Color[3], RenderMode, RenderAmount
	get_user_name(gPlayerId, name, 31)
	get_rendering(gPlayerId, FxType, Color[0], Color[1], Color[2], RenderMode, RenderAmount)

	client_print(id, print_chat,"The player %s has rendering set: FxType = %s, r = %d, g = %d, b = %d", name, gFxName[FxType], Color[0], Color[1], Color[2])
	client_print(id, print_chat,"RenderMode = %s, RenderAmount = %d.", gRenderModeName[RenderMode], RenderAmount)

	return PLUGIN_HANDLED	
}

public m_pm_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[3], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 2, iName, 63, callback)

	new index = str_to_num(cmd)
	new pl_id = gPlayers[index - 1]
	new PlayerName[32]
	new bool:ReloadMenu = false

	if (pl_id == 0)
	{
		ReloadMenu = true
	}
	else if (pl_id == -1) 
	{
		client_print(id, print_chat,"The selected player is no longer connected. Choose another one.")
		ReloadMenu = true
	}
	else if (!is_user_connected(pl_id)) 
	{
		client_print(id, print_chat,"The selected player is no longer connected. Choose another one.")
		ReloadMenu = true
	}
	else if (!is_user_alive(pl_id))
	{
		client_print(id, print_chat,"The selected player is not alive. Choose another one.")
		ReloadMenu = true
	}

	if (ReloadMenu)
	{
		if (g_PlayerMenuID > 0)
		{
			menu_destroy(g_PlayerMenuID)
			g_PlayerMenuID = menu_create(g_PlayerMenu, "m_pm_handler", 0)
		}

		new numplayers, pl_id, i, item
		new UserName[32], ItemName[2]
		get_players(gPlayers, numplayers)

		for(i = 0; i < numplayers; ++i)
		{
			pl_id = gPlayers[i]
			item = i + 1
			num_to_str(item, ItemName, 2)
			if (is_user_connected(pl_id))
			{
				get_user_name(pl_id, UserName, 31)
				menu_additem(g_PlayerMenuID, UserName, ItemName, ADMIN_MAP, -1)
			}
		}
		menu_display(id, g_PlayerMenuID, 0)
		return PLUGIN_HANDLED
	}

	gPlayerId = pl_id
	get_user_name(pl_id, PlayerName, 31)
	menu_display(id, g_MainMenuID, 0)
	client_print(id, print_chat, "Selected Player for rendering = %s", PlayerName)
	return PLUGIN_HANDLED
}

public m_mm_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[2], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 1, iName, 63, callback)

	new choice = str_to_num(cmd)

	switch(choice)
	{
		case 1:
		{
			if (g_PlayerMenuID > 0)
			{
				menu_destroy(g_PlayerMenuID)
				g_PlayerMenuID = menu_create(g_PlayerMenu, "m_pm_handler", 0)
			}

			new numplayers, pl_id, i, item
			new UserName[32], ItemName[2]
			get_players(gPlayers, numplayers)

			for(i = 0; i < numplayers; ++i)
			{
				pl_id = gPlayers[i]
				item = i + 1
				num_to_str(item, ItemName, 2)
				if (is_user_connected(pl_id))
				{
					get_user_name(pl_id, UserName, 31)
					menu_additem(g_PlayerMenuID, UserName, ItemName, ADMIN_MAP, -1)
				}
			}
			menu_display(id, g_PlayerMenuID, 0)
		}
		case 2:
		{
			menu_display(id, g_FxMenuID, 0)
		}
		case 3:
		{
			menu_display(id, g_ColorMenuID, 0)
		}
		case 4:
		{
			menu_display(id, g_RenderModeMenuID, 0)
		}
		case 5:
		{
			menu_display(id, g_RenderAmountMenuID, 0)
		}
		case 6:
		{
			menu_display(id, g_MainMenuID, 0)
			console_cmd(id, "amx_set_rendering")
		}
		case 7:
		{
			menu_display(id, g_MainMenuID, 0)
			console_cmd(id, "amx_get_rendering")
		}
	}
	return PLUGIN_HANDLED	
}

public m_fxm_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[3], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 2, iName, 63, callback)

	new choice = str_to_num(cmd)

	switch(choice)
	{
		case 1:
		{
			gFxType = kRenderFxNone
		}
		case 2:
		{
			gFxType = kRenderFxPulseSlow
		}
		case 3:
		{
			gFxType = kRenderFxPulseFast
		}
		case 4:
		{
			gFxType = kRenderFxPulseSlowWide
		}
		case 5:
		{
			gFxType = kRenderFxPulseFastWide
		}
		case 6:
		{
			gFxType = kRenderFxFadeSlow
		}
		case 7:
		{
			gFxType = kRenderFxFadeFast
		}
		case 8:
		{
			gFxType = kRenderFxSolidSlow
		}
		case 9:
		{
			gFxType = kRenderFxSolidFast
		}
		case 10:
		{
			gFxType = kRenderFxStrobeSlow
		}
		case 11:
		{
			gFxType = kRenderFxStrobeFast
		}
		case 12:
		{
			gFxType = kRenderFxStrobeFaster
		}
		case 13:
		{
			gFxType = kRenderFxFlickerSlow
		}
		case 14:
		{
			gFxType = kRenderFxFlickerFast
		}
		case 15:
		{
			gFxType = kRenderFxNoDissipation
		}
		case 16:
		{
			gFxType = kRenderFxDistort
		}
		case 17:
		{
			gFxType = kRenderFxHologram
		}
		case 18:
		{
			gFxType = kRenderFxDeadPlayer
		}
		case 19:
		{
			gFxType = kRenderFxExplode
		}
		case 20:
		{
			gFxType = kRenderFxGlowShell
		}
	}
	menu_display(id, g_MainMenuID, 0)
	client_print(id, print_chat, "Selected FxType = %s", gFxName[gFxType])

	return PLUGIN_HANDLED	
}

public m_rmm_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[2], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 1, iName, 63, callback)

	new choice = str_to_num(cmd)

	switch(choice)
	{
		case 1:
		{
			gRenderMode = kRenderNormal
		}
		case 2:
		{
			gRenderMode = kRenderTransColor
		}
		case 3:
		{
			gRenderMode = kRenderTransTexture
		}
		case 4:
		{
			gRenderMode = kRenderGlow
		}
		case 5:
		{
			gRenderMode = kRenderTransAlpha
		}
		case 6:
		{
			gRenderMode = kRenderTransAdd
		}
	}
	menu_display(id, g_MainMenuID, 0)
	client_print(id, print_chat, "Selected Render Mode = %s", gRenderModeName[gRenderMode])

	return PLUGIN_HANDLED	
}

public m_cm_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[2], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 1, iName, 63, callback)

	new choice = str_to_num(cmd)
	switch(choice)
	{
		case 1:
		{
			gColor[0] += 5
			if (gColor[0] > 255)
			{
				gColor[0] = 255
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 2:
		{
			gColor[0] -= 5
			if (gColor[0] < 0)
			{
				gColor[0] = 0
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 3:
		{
			gColor[1] += 5
			if (gColor[1] > 255)
			{
				gColor[1] = 255
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 4:
		{
			gColor[1] -= 5
			if (gColor[1] < 0)
			{
				gColor[1] = 0
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 5:
		{
			gColor[2] += 5
			if (gColor[2] > 255)
			{
				gColor[2] = 255
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 6:
		{
			gColor[2] -= 5
			if (gColor[2] < 0)
			{
				gColor[2] = 0
			}
			menu_display(id, g_ColorMenuID, 0)
		}
		case 7:
		{
			menu_display(id, g_MainMenuID, 0)
		}
	}
	client_print(id, print_chat, "Selected Color for Rendering = [%d, %d, %d].", gColor[0], gColor[1], gColor[2])

	return PLUGIN_HANDLED	
}

public m_ram_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_CONTINUE
	}

	new cmd[2], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 1, iName, 63, callback)

	new choice = str_to_num(cmd)

	switch(choice)
	{
		case 1:
		{
			if (gRenderAmount < 16)
			{
				gRenderAmount++
			}
			else
			{
				gRenderAmount += 5
			}
			if (gRenderAmount > 255)
				gRenderAmount = 255

			menu_display(id, g_RenderAmountMenuID, 0)
		}
		case 2:
		{
			if (gRenderAmount < 16)
			{
				gRenderAmount--
			}
			else
			{
				gRenderAmount -= 5
			}
			if (gRenderAmount < 0)
				gRenderAmount = 0

			menu_display(id, g_RenderAmountMenuID, 0)
		}
		case 3:
		{
			menu_display(id, g_MainMenuID, 0)
		}
	}

	client_print(id, print_chat, "Selected Amount for Rendering = %d.", gRenderAmount)
	return PLUGIN_HANDLED	
}

stock get_rendering(index, &fx, &r, &g, &b, &render, &amount)
{
	fx = entity_get_int(index,EV_INT_renderfx)
	new Float:RenderColor[3]
	entity_get_vector(index,EV_VEC_rendercolor,RenderColor);
	r = floatround(RenderColor[0])
	g = floatround(RenderColor[1])
	b = floatround(RenderColor[2])
	render = entity_get_int(index,EV_INT_rendermode)
	amount = floatround(entity_get_float(index,EV_FL_renderamt))
	return 1
}
