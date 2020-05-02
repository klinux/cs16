/* AMX Mod script
*
* (c) 2003 - 2004, T(+)rget and f117bomb
* This file is provided as is (no warranties)
*
* Info:
*		[ATAC] Extension to configure all settings using an in-game menu
*
* Current supported ML Languages
* - Re-Done French Translations by L@Br3Y
* - Re-Done German Translations by ToT | V!PER
* - Dutch Translations Done By teame06 www.altavista.com translation website
* - Polish Translations Done By KWo
* - Spanish Translations Done By Faluco
* - English Translations Done By T(+)rget & f117Bomb
*
*  Read changelog_atac_cfg.txt for change logs
*
* v1.1.01 - v1.1.09 updates was done by teame06
*/

#include <amxmodx>
#include <amxmisc>

new const Author[] = "f117bomb & T(+)rget"
new const Plugin[] = "ATAC Config"
new const Version[] = "1.1.09"

//----------------------------------------------------------------------------------------------
new MenuPage[33]
new const Float:Menu0 = 0.1
new const Menu1 = 1
new const Menu5 = 5
new const Menu30 = 30
new const Menu250 = 250

/* PCvars */
new pv_atac_menu
new pv_atac_options
new pv_atac_slap_freq
new pv_atac_slap_amount
new pv_atac_slap_power
new pv_atac_jail_time
new pv_atac_bomb_mode
new pv_atac_bomb_range
new pv_atac_fire_mode
new pv_atac_ta_slap
new pv_atac_bantime
new pv_atac_banvia
new pv_atac_tk_before_ban
new pv_atac_handlenames
new pv_atac_tacontrol
new pv_atac_tanotallowedfor
new pv_atac_slayonmaxtas
new pv_atac_ta_equal_v
new pv_atac_ta_mirrordmg
new pv_atac_ta_restore
new pv_atac_tkcontrol
new pv_atac_admins_immune
new pv_atac_savetks
new pv_atac_status
new pv_atac_hostagepen
new pv_atac_hudmessages
new pv_atac_amxban
new pv_atac_dm
new pv_atac_log

//----------------------------------------------------------------------------------------------
public plugin_init()
	{
	register_plugin(Plugin, Version, Author)
	register_cvar("atac_cfg_version", Version, FCVAR_SERVER|FCVAR_SPONLY) /* For GameSpy/HLSW and such */
	register_clcmd("amx_atacmenu", "amx_atac_menu", ADMIN_CFG, "- [ATAC]: Configuration Menu")
	register_dictionary("ataccfg.txt") /* Load Languages */
	register_menucmd(register_menuid("[ATAC]"), 1023, "action_atac_set")
	
	pv_atac_menu		= get_cvar_pointer("atac_menu")
	pv_atac_options		= get_cvar_pointer("atac_options")
	pv_atac_slap_freq	= get_cvar_pointer("atac_slap_freq")
	pv_atac_slap_amount	= get_cvar_pointer("atac_slap_amount")
	pv_atac_slap_power	= get_cvar_pointer("atac_slap_power")
	pv_atac_jail_time	= get_cvar_pointer("atac_jail_time")
	pv_atac_bomb_mode	= get_cvar_pointer("atac_bomb_mode")
	pv_atac_bomb_range	= get_cvar_pointer("atac_bomb_range")
	pv_atac_fire_mode	= get_cvar_pointer("atac_fire_mode")
	pv_atac_ta_slap		= get_cvar_pointer("atac_ta_slap")
	pv_atac_bantime		= get_cvar_pointer("atac_bantime")
	pv_atac_banvia		= get_cvar_pointer("atac_banvia")
	pv_atac_tk_before_ban	= get_cvar_pointer("atac_tk_before_ban")
	pv_atac_handlenames	= get_cvar_pointer("atac_handlenames")
	pv_atac_tacontrol	= get_cvar_pointer("atac_tacontrol")
	pv_atac_tanotallowedfor	= get_cvar_pointer("atac_tanotallowedfor")
	pv_atac_slayonmaxtas	= get_cvar_pointer("atac_slayonmaxtas")
	pv_atac_ta_equal_v	= get_cvar_pointer("atac_ta_equal_v")
	pv_atac_ta_mirrordmg	= get_cvar_pointer("atac_ta_mirrordmg")
	pv_atac_ta_restore	= get_cvar_pointer("atac_ta_restore")
	pv_atac_tkcontrol	= get_cvar_pointer("atac_tkcontrol")
	pv_atac_admins_immune	= get_cvar_pointer("atac_admins_immune")
	pv_atac_savetks		= get_cvar_pointer("atac_savetks")
	pv_atac_status		= get_cvar_pointer("atac_status")
	pv_atac_hostagepen	= get_cvar_pointer("atac_hostagepen")
	pv_atac_hudmessages	= get_cvar_pointer("atac_hudmessages")
	pv_atac_amxban		= get_cvar_pointer("atac_amxban")
	pv_atac_dm		= get_cvar_pointer("atac_dm")
	pv_atac_log		= get_cvar_pointer("atac_log")
}
//----------------------------------------------------------------------------------------------
public amx_atac_menu(id, level, cid)
	{
	if(!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED
	if(id == 0)
		{
		console_print(id, "You can only use this command in-game")
	}
	else
		{
		MenuPage[id] = 1
		show_atac_set(id)
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
show_atac_set(id)
{
	new menuoption[10][64], smenu[64], menubody[512]
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)
	for(new z = 0; z < 10; ++z) menuoption[z][0] = 0 // clear string
	
	switch(MenuPage[id])
	{
		case 1:
		{
			formatex(smenu, 63, "%L", id, "MENU_CFG_STITLE")
			formatex(menuoption[0], 63, "\w1. %L^n", id, "MENU_CFG_PO")
			formatex(menuoption[1], 63, "\w2. %L^n", id, "MENU_CFG_TA")
			formatex(menuoption[2], 63, "\w3. %L^n", id, "MENU_CFG_TK")
			formatex(menuoption[3], 63, "\w4. %L^n^n", id, "MENU_CFG_AO")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[9], 63, "\w0. %L", id, "MENU_CFG_EXIT")
			keys -= (1<<4)|(1<<5)|(1<<6)|(1<<8)
		}
		case 2:
		{
			new option = get_pcvar_num(pv_atac_options)
			formatex(smenu, 63, "%L\R1/2", id, "MENU_CFG_PTITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n", id, "MENU_CFG_SLAP", (option & (1<<0)) ? "ON" : "OFF")
			formatex(menuoption[1], 63, "\w2. %L\R\y%s^n", id, "MENU_CFG_SLAP1HP", (option & (1<<1)) ? "ON" : "OFF")
			if((get_cvar_num("csdm_active") != 1) || (get_cvar_num("tdm_state") != 1) || (get_pcvar_num(pv_atac_dm) != 1))
				{
				formatex(menuoption[2], 63, "\w3. %L\R\y%s^n", id, "MENU_CFG_SLAY_NR", (option & (1<<2)) ? "ON" : "OFF")
			}
			else
				{
				formatex(menuoption[2], 63, "\w3. %L\R\y%s^n", id, "MENU_CFG_SLAY_NS", (option & (1<<2)) ? "ON" : "OFF")
			}
			formatex(menuoption[3], 63, "\w4. %L\R\y%s^n", id, "MENU_CFG_JAIL", (option & (1<<3)) ? "ON" : "OFF")
			formatex(menuoption[4], 63, "\w5. %L\R\y%s^n", id, "MENU_CFG_CHICKEN", (option & (1<<4)) ? "ON" : "OFF")
			formatex(menuoption[5], 63, "\w6. %L\R\y%s^n", id, "MENU_CFG_BURY", (option & (1<<5)) ? "ON" : "OFF")
			formatex(menuoption[6], 63, "\w7. %L\R\y%s^n^n", id, "MENU_CFG_GLOW", (option & (1<<6)) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[8], 63, "\w9. %L^n", id, "MENU_CFG_MORE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
		}
		case 3:
		{
			new option = get_pcvar_num(pv_atac_options)
			formatex(smenu, 63, "%L\R2/2", id, "MENU_CFG_PTITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n", id, "MENU_CFG_TIMEBOMB", (option & (1<<7)) ? "ON" : "OFF")
			formatex(menuoption[1], 63, "\w2. %L\R\y%s^n", id, "MENU_CFG_BLIND", (option & (1<<8)) ? "ON" : "OFF")
			formatex(menuoption[2], 63, "\w3. %L\R\y%s^n", id, "MENU_CFG_ROCKET", (option & (1<<9)) ? "ON" : "OFF")
			formatex(menuoption[3], 63, "\w4. %L\R\y%s^n", id, "MENU_CFG_DROP", (option & (1<<10)) ? "ON" : "OFF")
			formatex(menuoption[4], 63, "\w5. %L\R\y%s^n", id, "MENU_CFG_FIRE", (option & (1<<11)) ? "ON" : "OFF")
			formatex(menuoption[5], 63, "\w6. %L\R\y%s^n^n", id, "MENU_CFG_DRUG", (option & (1<<12)) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[9], 63, "\w0. %L", id, "MENU_CFG_BACK")
			keys -= (1<<6)|(1<<8)
		}
		case 4:
		{
			new noTAallowed = get_pcvar_num(pv_atac_tanotallowedfor)
			formatex(smenu, 63, "%L", id, "MENU_CFG_TAMTITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n", id, "MENU_CFG_TAC", get_pcvar_num(pv_atac_tacontrol) ? "ON" : "OFF")
			formatex(menuoption[1], 63, "\w2. %L\R\y%i^n", id, "MENU_CFG_V", get_pcvar_num(pv_atac_ta_equal_v))
			formatex(menuoption[2], 63, noTAallowed ? "\w3. %L\R\y%i SECS^n" : "\w3. %L\R\yOFF^n", id, "MENU_CFG_NAF", noTAallowed) // Check it
			formatex(menuoption[3], 63, "\w4. %L\R\y%s^n", id, "MENU_CFG_SOMV", get_pcvar_num(pv_atac_slayonmaxtas) ? "ON" : "OFF")
			formatex(menuoption[4], 63, "\w5. %L\R\y%s^n", id, "MENU_CFG_SLAPPING", get_pcvar_num(pv_atac_ta_slap) ? "ON" : "OFF")
			formatex(menuoption[5], 63, "\w6. %L\R\y%s^n", id, "MENU_CFG_MR", get_pcvar_num(pv_atac_ta_mirrordmg) ? "ON" : "OFF")
			formatex(menuoption[6], 63, "\w7. %L\R\y%s^n^n", id, "MENU_CFG_RH", get_pcvar_num(pv_atac_ta_restore) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
			keys -= (1<<8)
		}
		case 5:
		{
			new bantype[7], banvia = get_pcvar_num(pv_atac_banvia), bantime = get_pcvar_num(pv_atac_bantime)
			
			if(banvia == 1) copy(bantype, 6, "AUTHID")
			else if(banvia == 2) copy(bantype, 6, "IP")
				else if(banvia == 3) copy(bantype, 6, "KICK")
				
			formatex(smenu, 63, "%L\R1/2", id, "MENU_CFG_TKM_TITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n", id, "MENU_CFG_TKC", get_pcvar_num(pv_atac_tkcontrol) ? "ON" : "OFF")
			formatex(menuoption[1], 63, "\w2. %L\R\y%i^n", id, "MENU_CFG_V", get_pcvar_num(pv_atac_tk_before_ban))
			formatex(menuoption[2], 63, "\w3. %L\R\y%s^n", id, "MENU_CFG_PM", get_pcvar_num(pv_atac_menu) ? "ON" : "OFF")
			formatex(menuoption[3], 63, "\w4. %L\R\y%s^n", id, "MENU_CFG_BT", bantype)
			if(banvia == 3)
				{
				formatex(menuoption[4], 63, bantime ? "\d5. %L\R%i MINS^n" : "\d5. %L\RPERMANENT^n", id, "MENU_CFG_BTIME", bantime)
				keys -= (1<<4)
			}
			else
				{
				formatex(menuoption[4], 63, bantime ? "\w5. %L\R\y%i MINS^n" : "\w5. %L\R\yPERMANENT^n", id, "MENU_CFG_BTIME", bantime)
			}
			formatex(menuoption[5], 63, "\w6. %L\R\y%s^n", id, "MENU_CFG_SUR", get_pcvar_num(pv_atac_savetks) ? "ON" : "OFF")
			formatex(menuoption[6], 63, "\w7. %L\R\y%s^n^n", id, "MENU_CFG_AI", get_pcvar_num(pv_atac_admins_immune) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[8], 64, "\w9. %L^n", id, "MENU_CFG_MORE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
		}
		case 6:
		{
			formatex(smenu, 63, "%L\R2/2", id, "MENU_CFG_TKM_TITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n^n", id, "MENU_CFG_LPS", get_pcvar_num(pv_atac_status) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
			keys -= (1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)
		}
		case 7:
		{
			new bmode = get_pcvar_num(pv_atac_bomb_mode)
			if(!bmode) keys -= (1<<5)
			formatex(smenu, 63, "%L\R1/2", id, "MENU_CFG_AOM_TITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%f SEC^n", id, "MENU_CFG_ST", get_pcvar_float(pv_atac_slap_freq))
			formatex(menuoption[1], 63, "\w2. %L\R\y%i^n", id, "MENU_CFG_S", get_pcvar_num(pv_atac_slap_amount))
			formatex(menuoption[2], 63, "\w3. %L\R\y%i^n", id, "MENU_CFG_SP", get_pcvar_num(pv_atac_slap_power))
			formatex(menuoption[3], 63, "\w4. %L\R\y%i SECS^n", id, "MENU_CFG_JT", get_pcvar_float(pv_atac_jail_time))
			formatex(menuoption[4], 63, "\w5. %L\R\y%s^n", id, "MENU_CFG_BEO", bmode ? "ON" : "OFF")
			formatex(menuoption[5], 63, bmode ? "\w6. %L\R\y%i^n" : "\d6. %L\R%i^n", id, "MENU_CFG_BER", get_pcvar_num(pv_atac_bomb_range))
			formatex(menuoption[6], 63, "\w7. %L\R\y%s^n^n", id, "MENU_CFG_FEO", get_pcvar_num(pv_atac_fire_mode) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[8], 63, "\w9. %L^n", id, "MENU_CFG_MORE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
		}
		case 8:
		{
			formatex(smenu, 63, "%L\R2/2", id, "MENU_CFG_AOM_TITLE")
			formatex(menuoption[0], 63, "\w1. %L\R\y%s^n", id, "MENU_CFG_HNC", get_pcvar_num(pv_atac_handlenames) ? "ON" : "OFF")
			formatex(menuoption[1], 63, "\w2. %L\R\y%s^n", id, "MENU_CFG_HPC", get_pcvar_num(pv_atac_hostagepen) ? "ON" : "OFF")
			formatex(menuoption[2], 63, "\w3. %L\R\y%s^n", id, "MENU_CFG_SHM", get_pcvar_num(pv_atac_hudmessages) ? "ON" : "OFF")
			formatex(menuoption[3], 63, "\w4. %L\R\y%s^n", id, "MENU_CFG_UA4", get_pcvar_num(pv_atac_amxban) ? "ON" : "OFF")
			formatex(menuoption[4], 63, "\w5. %L\R\y%s^n", id, "MENU_CFG_LOG", get_pcvar_num(pv_atac_log) ? "ON" : "OFF")
			formatex(menuoption[5], 63, "\w6. %L\R\y%s^n^n", id, "MENU_CFG_DM", get_pcvar_num(pv_atac_dm) ? "ON" : "OFF")
			formatex(menuoption[7], 63, "\w8. %L^n^n", id, "MENU_CFG_SAVE")
			formatex(menuoption[9], 63, "\w0. %L^n", id, "MENU_CFG_BACK")
			keys -= (1<<6)|(1<<8)
		}
		
	}
	formatex(menubody, 511, "\y[ATAC] %s:^n^n%s%s%s%s%s%s%s%s%s%s", smenu,
	menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4], menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
	show_menu(id, keys, menubody)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public action_atac_set(id, key)
	{
	if(MenuPage[id] == 1)
		{
		switch(key)
		{
			case 0: MenuPage[id] = 2
			case 1: MenuPage[id] = 4
			case 2: MenuPage[id] = 5
			case 3: MenuPage[id] = 7
			case 7:
			{
				atac_save(id)
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 0
				return PLUGIN_HANDLED
			}
		}
		// Bypass Update System
		show_atac_set(id)
		return PLUGIN_HANDLED
	}
	if(MenuPage[id] == 2)
		{
		new option = get_pcvar_num(pv_atac_options)
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_options, option ^= (1<<0))
			case 1: set_pcvar_num(pv_atac_options, option ^= (1<<1))
			case 2: set_pcvar_num(pv_atac_options, option ^= (1<<2))
			case 3: set_pcvar_num(pv_atac_options, option ^= (1<<3))
			case 4: set_pcvar_num(pv_atac_options, option ^= (1<<4))
			case 5: set_pcvar_num(pv_atac_options, option ^= (1<<5))
			case 6: set_pcvar_num(pv_atac_options, option ^= (1<<6))
			case 7:
			{
				atac_save(id)
			}
			case 8:
			{
				MenuPage[id] = 3
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 1
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 3)
		{
		new option = get_pcvar_num(pv_atac_options)
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_options, option ^= (1<<7))
			case 1: set_pcvar_num(pv_atac_options, option ^= (1<<8))
			case 2: set_pcvar_num(pv_atac_options, option ^= (1<<9))
			case 3: set_pcvar_num(pv_atac_options, option ^= (1<<10))
			case 4: set_pcvar_num(pv_atac_options, option ^= (1<<11))
			case 5: set_pcvar_num(pv_atac_options, option ^= (1<<12))
			case 7:
			{
				atac_save(id)
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 2
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 4)
		{
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_tacontrol, get_pcvar_num(pv_atac_tacontrol) ? 0 : 1)
			case 1:
			{
				new TAequal = get_pcvar_num(pv_atac_ta_equal_v)
				if(TAequal + Menu1 > 9 || TAequal > 9) set_pcvar_num(pv_atac_ta_equal_v, 1)
				else set_pcvar_num(pv_atac_ta_equal_v, TAequal += Menu1)
			}
			case 2:
			{
				new noTAallowed = get_pcvar_num(pv_atac_tanotallowedfor)
				if(noTAallowed + Menu1 > 30 || noTAallowed > 30) set_pcvar_num(pv_atac_tanotallowedfor, 0)
				else set_pcvar_num(pv_atac_tanotallowedfor, noTAallowed += Menu1)
			}
			case 3: set_pcvar_num(pv_atac_slayonmaxtas, get_pcvar_num(pv_atac_slayonmaxtas) ? 0 : 1)
			case 4: set_pcvar_num(pv_atac_ta_slap, get_pcvar_num(pv_atac_ta_slap) ? 0 : 1)
			case 5: set_pcvar_num(pv_atac_ta_mirrordmg, get_pcvar_num(pv_atac_ta_mirrordmg) ? 0 : 1)
			case 6: set_pcvar_num(pv_atac_ta_restore, get_pcvar_num(pv_atac_ta_restore) ? 0 : 1)
			case 7:
			{
				atac_save(id)
			}
			case 9:
			{
				MenuPage[id] = 1
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 5)
		{
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_tkcontrol, get_pcvar_num(pv_atac_tkcontrol) ? 0 : 1)
			case 1:
			{
				new TKequal = get_pcvar_num(pv_atac_tk_before_ban)
				if(TKequal + Menu1 > 30 || TKequal > 30) set_pcvar_num(pv_atac_tk_before_ban, 1)
				else set_pcvar_num(pv_atac_tk_before_ban, TKequal += Menu1)
			}
			case 2:
			{
				set_pcvar_num(pv_atac_menu, get_pcvar_num(pv_atac_menu) ? 0 : 1)
			}
			case 3:
			{
				new banvia = get_pcvar_num(pv_atac_banvia)
				if(banvia == 1) set_pcvar_num(pv_atac_banvia, 2)
				else if(banvia == 2) set_pcvar_num(pv_atac_banvia, 3)
					else if(banvia == 3) set_pcvar_num(pv_atac_banvia, 1)
				}
			case 4:
			{
				new bantime = get_pcvar_num(pv_atac_bantime)
				if(bantime + Menu30 > 300 || bantime > 300) set_pcvar_num(pv_atac_bantime, 0)
				else set_pcvar_num(pv_atac_bantime, bantime += Menu30)
			}
			case 5: set_pcvar_num(pv_atac_savetks, get_pcvar_num(pv_atac_savetks) ? 0 : 1)
			case 6: set_pcvar_num(pv_atac_admins_immune, get_pcvar_num(pv_atac_admins_immune) ? 0 : 1)
			case 7:
			{
				atac_save(id)
			}
			case 8:
			{
				MenuPage[id] = 6
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 1
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 6)
		{
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_status, get_pcvar_num(pv_atac_status) ? 0 : 1)
			
			case 7:
			{
				atac_save(id)
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 5
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 7)
		{
		switch(key)
		{
			
			case 0:
			{
				new Float:slaptime = get_pcvar_float(pv_atac_slap_freq)
				if(slaptime + Menu0 > 2.0 || slaptime > 2.0) set_pcvar_float(pv_atac_slap_freq, 0.1)
				else set_pcvar_float(pv_atac_slap_freq, slaptime += Menu0)
			}
			case 1:
			{
				new slaps = get_pcvar_num(pv_atac_slap_amount)
				if(slaps + Menu1 > 30 || slaps > 30) set_pcvar_num(pv_atac_slap_amount, 1)
				else set_pcvar_num(pv_atac_slap_amount, slaps += Menu1)
			}
			case 2:
			{
				new spower = get_pcvar_num(pv_atac_slap_power)
				if(spower + Menu1 > 30 || spower > 30) set_pcvar_num(pv_atac_slap_power, 0)
				else set_pcvar_num(pv_atac_slap_power, spower += Menu1)
			}
			case 3:
			{
				new Float:jtime = get_pcvar_float(pv_atac_jail_time)
				if(jtime + Menu5 > 90 || jtime > 90) set_pcvar_float(pv_atac_jail_time, 15.0)
				else set_pcvar_float(pv_atac_jail_time, jtime += Menu5)
			}
			case 4: set_pcvar_num(pv_atac_bomb_mode, get_pcvar_num(pv_atac_bomb_mode) ? 0 : 1)
			case 5:
			{
				new bradius = get_pcvar_num(pv_atac_bomb_range)
				if(bradius + Menu250 > 3000 || bradius > 3000) set_pcvar_num(pv_atac_bomb_range, 250)
				else set_pcvar_num(pv_atac_bomb_range, bradius += Menu250)
			}
			case 6: set_pcvar_num(pv_atac_fire_mode, get_pcvar_num(pv_atac_fire_mode) ? 0 : 1)
			case 7:
			{
				atac_save(id)
			}
			case 8:
			{
				MenuPage[id] = 8
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 1
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	if(MenuPage[id] == 8)
		{
		switch(key)
		{
			case 0: set_pcvar_num(pv_atac_handlenames, get_pcvar_num(pv_atac_handlenames) ? 0 : 1)
			case 1: set_pcvar_num(pv_atac_hostagepen, get_pcvar_num(pv_atac_hostagepen) ? 0 : 1)
			case 2: set_pcvar_num(pv_atac_hudmessages, get_pcvar_num(pv_atac_hudmessages) ? 0 : 1)
			case 3:	set_pcvar_num(pv_atac_amxban, get_pcvar_num(pv_atac_amxban) ? 0 : 1)
			case 4: set_pcvar_num(pv_atac_log, get_pcvar_num(pv_atac_log) ? 0 : 1)
			case 5: set_pcvar_num(pv_atac_dm, get_pcvar_num(pv_atac_dm) ? 0 : 1)
			case 7:
			{
				atac_save(id)
			}
			case 9:
			{
				// Menu Fix (Popup)
				MenuPage[id] = 7
				// Bypass Update System
				show_atac_set(id)
				return PLUGIN_HANDLED
			}
		}
	}
	update_menu()
	return PLUGIN_HANDLED
}
//---------------------------------------------------------------------------------------------
update_menu()
{
	new admins[32], inum, menu, keys
	get_players(admins, inum)
	
	for(new i = 0; i < inum; ++i)
		{
		if(MenuPage[admins[i]] > 0 && !get_user_menu(admins[i], menu, keys)) MenuPage[admins[i]] = 0
		else if(MenuPage[admins[i]] > 0) show_atac_set(admins[i])
		}
}

//------------------------------------ Save Config to File Stuff ------------------------------
public atac_save(id)
	{
	
	new menu[64], options[64], tacontrol[64], ta_equal_v[64], tanotallowedfor[64],
	slayonmaxtas[64],  ta_slap[64], ta_mirrordmg[64], ta_restore[64], tkcontrol[64],
	tk_before_ban[64], banvia[64], bantime[64], savetks[64], admins_immune[64],
	status[64], slap_amount[64], slap_power[64], jail_time[64], bomb_mode[64],
	bomb_range[64], fire_mode[64], handlenames[64], hostagepen[64], hudmessages[64],
	amxban[64], configsdir[64], filename[128], slap_freq[64], log[64], dm[64]
	
	// Gets the directory location of the configs folder
	get_configsdir( configsdir, 63 )
	formatex(filename, 127, "%s/atac/atac.cfg", configsdir)
	
	// Get current settings from the server itself
	formatex(menu, 63, "atac_menu %i", get_pcvar_num(pv_atac_menu))
	formatex(options, 63, "atac_options %i", get_pcvar_num(pv_atac_options))
	formatex(slap_freq, 63, "atac_slap_freq %f", get_pcvar_float(pv_atac_slap_freq))
	formatex(slap_amount, 63, "atac_slap_amount %i", get_pcvar_num(pv_atac_slap_amount))
	formatex(slap_power, 63, "atac_slap_power %i", get_pcvar_num(pv_atac_slap_power))
	formatex(jail_time, 63, "atac_jail_time %f", get_pcvar_float(pv_atac_jail_time))
	formatex(bomb_mode, 63, "atac_bomb_mode %i", get_pcvar_num(pv_atac_bomb_mode))
	formatex(bomb_range, 63, "atac_bomb_range %i", get_pcvar_num(pv_atac_bomb_range))
	formatex(fire_mode, 63, "atac_fire_mode %i", get_pcvar_num(pv_atac_fire_mode))
	formatex(handlenames, 63, "atac_handlenames %i", get_pcvar_num(pv_atac_handlenames))
	formatex(hostagepen, 63, "atac_hostagepen %i", get_pcvar_num(pv_atac_hostagepen))
	formatex(hudmessages, 63, "atac_hudmessages %i", get_pcvar_num(pv_atac_hudmessages))
	formatex(amxban, 63, "atac_amxban %i", get_pcvar_num(pv_atac_amxban))
	formatex(log, 63, "atac_log %i", get_pcvar_num(pv_atac_log))
	formatex(dm, 63, "atac_dm %i", get_pcvar_num(pv_atac_dm))
	formatex(tacontrol, 63, "atac_tacontrol %i", get_pcvar_num(pv_atac_tacontrol))
	formatex(ta_equal_v, 63, "atac_ta_equal_v %i", get_pcvar_num(pv_atac_ta_equal_v))
	formatex(tanotallowedfor, 63, "atac_tanotallowedfor %i", get_pcvar_num(pv_atac_tanotallowedfor))
	formatex(slayonmaxtas, 63, "atac_slayonmaxtas %i", get_pcvar_num(pv_atac_slayonmaxtas))
	formatex(ta_slap, 63, "atac_ta_slap %i", get_pcvar_num(pv_atac_ta_slap))
	formatex(ta_mirrordmg, 63, "atac_ta_mirrordmg %i", get_pcvar_num(pv_atac_ta_mirrordmg))
	formatex(ta_restore, 63, "atac_ta_restore %i", get_pcvar_num(pv_atac_ta_restore))
	formatex(tkcontrol, 63, "atac_tkcontrol %i", get_pcvar_num(pv_atac_tkcontrol))
	formatex(tk_before_ban, 63, "atac_tk_before_ban %i", get_pcvar_num(pv_atac_tk_before_ban))
	formatex(banvia, 63, "atac_banvia %i", get_pcvar_num(pv_atac_banvia))
	formatex(bantime, 63, "atac_bantime %i", get_pcvar_num(pv_atac_bantime))
	formatex(status, 63, "atac_status %i", get_pcvar_num(pv_atac_status))
	formatex(admins_immune, 63, "atac_admins_immune %i", get_pcvar_num(pv_atac_admins_immune))
	formatex(savetks, 63, "atac_savetks %i", get_pcvar_num(pv_atac_savetks))
	
	// Write to the config file
	write_file ( filename, menu , 4 )
	write_file ( filename, options , 22 )
	write_file ( filename, slap_freq , 29 )
	write_file ( filename, slap_amount , 32 )
	write_file ( filename, slap_power , 35 )
	write_file ( filename, jail_time , 38 )
	write_file ( filename, bomb_mode , 41 )
	write_file ( filename, bomb_range , 44 )
	write_file ( filename, fire_mode , 47 )
	write_file ( filename, handlenames , 50 )
	write_file ( filename, hostagepen, 53 )
	write_file ( filename, hudmessages , 56 )
	write_file ( filename, amxban , 59 )
	write_file ( filename, log, 62 )
	write_file ( filename, dm, 65 )
	write_file ( filename, tacontrol , 71 )
	write_file ( filename, ta_equal_v , 74 )
	write_file ( filename, tanotallowedfor , 77 )
	write_file ( filename, slayonmaxtas , 80 )
	write_file ( filename, ta_slap , 83 )
	write_file ( filename, ta_mirrordmg , 86 )
	write_file ( filename, ta_restore , 89 )
	write_file ( filename, tkcontrol , 96 )
	write_file ( filename, tk_before_ban , 99 )
	write_file ( filename, banvia , 102 )
	write_file ( filename, bantime , 105 )
	write_file ( filename, status , 108 )
	write_file ( filename, admins_immune , 111 )
	write_file ( filename, savetks , 114 )
	
	client_print(id, print_chat, "%L", id, "MENU_CFG_SAVE_MSG")
	return PLUGIN_CONTINUE
}
