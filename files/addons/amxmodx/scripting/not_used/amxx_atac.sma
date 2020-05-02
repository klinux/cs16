/*  Copyright (C) 2003 Aaron J. Drabeck

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

This version of Advanced Team Attack Control is for AMX MOD x 1.01
For support please visit http://www.amxmodx.org/forums/viewtopic.php?t=11930

v2.5.4b - v.2.5.5.5 updates was done by teame06

Current supported ML Languages
- Re-Done French Translations by L@Br3Y
- Re-Done German Translations by ToT | V!PER
- Dutch Translations Done By teame06 www.altavista.com translation website
- German NOTFOUND Translations Done by ToT | V!PER
- Polish Translations Done By KWo
- Swedish Translations Done By Belsebub
- Spanish Translations Done By Faluco
- English Translations Done By T(+)rget & f117Bomb
- French, German Translations Done By KRoT@L

Current Missing Translations
- Serbian
- Turkish
- Danish
- Swedish NOTFOUND MESSAGES

*/

#include <amxmodx>
#include <amxmisc>
#include <fun>

new const Author[]	= "T(+)rget/f117bomb"
new const Plugin[]	= "ATAC"
new const Version[]	= "2.5.5.5"

/* WarCraft 3 XP Compatibility */
#define LIVESTATUS

/* ADMIN_IMMUNITY Flag (amxconst.inc for more info) */
#define ATAC_IMMUNITY_LEVEL	(1<<0) // flag "a"

/* Player Flags */
#define SETTODIE 		(1<<0) // 1
#define JAILED 			(1<<1) // 2
#define CHICKEN 		(1<<2) // 4
#define GLOWING 		(1<<3) // 8
#define BLIND 			(1<<4) // 16
#define TIMEBOMB		(1<<5) // 32
#define FIRE			(1<<6) // 64
#define DRUG			(1<<7) // 128

/* Menu Option Flags */
#define OPTION_SLAP		(1<<0)  // 1
#define OPTION_SLAPTO1		(1<<1)  // 2
#define OPTION_SLAYNR		(1<<2)  // 4
#define OPTION_JAIL		(1<<3)  // 8
#define OPTION_CHICKEN		(1<<4)  // 16
#define OPTION_BURY		(1<<5)  // 32
#define OPTION_GLOW		(1<<6)  // 64
#define OPTION_BOMB		(1<<7)  // 128
#define OPTION_BLIND		(1<<8)  // 256
#define OPTION_ROCKET		(1<<9)  // 512
#define OPTION_DROP		(1<<10) // 1024
#define OPTION_FIRE		(1<<11) // 2048
#define OPTION_DRUG		(1<<12) // 4096

/* ID 0 Fix */
#define IDNULLFIX			// Comment this for debugging ID 0 errors or getting rid of extra checks

/* Format: killer/victim (For use with Victim Menu) */
new TK[33][33]

/* Format: killer/victim (For use with /whotkedme) */
new TKHistory[33][33]

new PlayerFlags[33]
new TA[33]
new KickMe[33]
new r_origin[33]
new bool:taAllowed = true
new MenuPage[33]
new StoredName[33][32]

/* Chicken Variables */
new ChickenCount

/* Jail Variables */
new JailedCount
new PreJailOrigin[33][3]
new map_cors_pre
new map_cors_origin[3]

/* Time Variable */
new countdown[33]

/* Game Messages */
new gmsgHealth
new gmsgBattery
new gmsgShake
new gmsgFade
new gmsgDeathMsg
new gmsgStatusText
new gmsgDamage
new gmsgSetFOV
//new atac_tacontrol = 1

/* Saved TeamKills */
new savedtks[300][35]
new savedtkcount
new authids[33][32]
new atac_status_off[33]

/* Sprites */
new light
new white
new smoke
new fire
new m_fireball
new mflash
new r_trail

/* SyncObjects */
new g_HudSyncBomb
new g_HudSyncBan
new g_HudSyncDamg
new g_HudSyncHostel

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
#if defined LIVESTATUS
new pv_atac_status
#endif
new pv_atac_hostagepen
new pv_atac_hudmessages
new pv_atac_amxban
new pv_atac_dm
new pv_atac_log
new pv_mp_roundtime
new pv_mp_freezetime

/***************** PRECACHE & INIT FUNCTIONS & ENDING FUNCTIONS *****************/
public plugin_init()
	{
	register_plugin(Plugin, Version, Author)
	register_cvar("atac_version", Version, FCVAR_SERVER|FCVAR_SPONLY) /* For GameSpy/HLSW and such */
	register_dictionary("atac.txt") /* Load Languages */
	server_cmd("localinfo atac_version %s", Version) /* For Statsme/AMX Welcome */
	
	register_clcmd("amx_addmetk", "addmetk", ADMIN_LEVEL_A, "- lets you punish yourself")
	register_clcmd("say /livestatus", "say_livestatus", 0, "- toggles ATAC Live Status (lower,right corner)")
	register_clcmd("say /atacstatus", "say_atacstatus", 0, "- shows your TK/TA Violation Count")
	register_clcmd("say /whotkedme", "say_whotkedme", 0, "- shows who has tked you")
	
	register_menucmd(register_menuid("[ATAC] Menu"), 1023, "action_atac_menu")
	
	gmsgStatusText	= get_user_msgid("StatusText")
	gmsgDamage	= get_user_msgid("Damage")
	gmsgDeathMsg	= get_user_msgid("DeathMsg")
	gmsgHealth	= get_user_msgid("Health")
	gmsgBattery	= get_user_msgid("Battery")
	gmsgShake	= get_user_msgid("ScreenShake")
	gmsgFade	= get_user_msgid("ScreenFade")
	gmsgSetFOV	= get_user_msgid("SetFOV")
	
	register_event("ScreenFade", "event_screen_fade", "b")
	register_event("ResetHUD", "event_respawn", "b")
	register_event("DeathMsg", "event_Death", "a")
	register_event("Damage", "event_Damage", "b", "2!0", "3=0", "4!0")
	register_event("RoundTime", "event_RoundTime", "bc")
	register_event("SetFOV", "event_SetFOV", "be", "1<91")
	register_event("TextMsg","event_hostkill","b","2&#Killed_Hostage")
	register_event("TextMsg","event_hostinj","b","2&#Injured_Hostage")
	
	pv_atac_menu		= register_cvar("atac_menu", "1")
	pv_atac_options		= register_cvar("atac_options", "8191")
	pv_atac_slap_freq	= register_cvar("atac_slap_freq", "0.25")
	pv_atac_slap_amount	= register_cvar("atac_slap_amount", "10")
	pv_atac_slap_power	= register_cvar("atac_slap_power", "5")
	pv_atac_jail_time	= register_cvar("atac_jail_time", "45.0")
	pv_atac_bomb_mode	= register_cvar("atac_bomb_mode", "1")
	pv_atac_bomb_range	= register_cvar("atac_bomb_range", "1000")
	pv_atac_fire_mode	= register_cvar("atac_fire_mode", "1")
	pv_atac_ta_slap		= register_cvar("atac_ta_slap", "1")
	
	pv_atac_bantime		= register_cvar("atac_bantime", "120")
	pv_atac_banvia		= register_cvar("atac_banvia", "1")
	pv_atac_tk_before_ban	= register_cvar("atac_tk_before_ban", "3")
	pv_atac_handlenames	= register_cvar("atac_handlenames", "1")
	pv_atac_tacontrol	= register_cvar("atac_tacontrol", "1")
	pv_atac_tanotallowedfor	= register_cvar("atac_tanotallowedfor", "5")
	pv_atac_slayonmaxtas	= register_cvar("atac_slayonmaxtas", "1")
	pv_atac_ta_equal_v	= register_cvar("atac_ta_equal_v", "5")
	
	pv_atac_ta_mirrordmg	= register_cvar("atac_ta_mirrordmg", "1")
	pv_atac_ta_restore	= register_cvar("atac_ta_restore", "1")
	pv_atac_tkcontrol	= register_cvar("atac_tkcontrol", "1")
	pv_atac_admins_immune	= register_cvar("atac_admins_immune", "1")
	pv_atac_savetks		= register_cvar("atac_savetks", "1")
	#if defined LIVESTATUS
	pv_atac_status		= register_cvar("atac_status", "1")
	#else
	register_cvar("atac_status", "1")
	#endif
	pv_atac_hostagepen	= register_cvar("atac_hostagepen", "0")
	pv_atac_hudmessages	= register_cvar("atac_hudmessages", "1")
	
	pv_atac_amxban		= register_cvar("atac_amxban", "0")
	pv_atac_dm		= register_cvar("atac_dm", "0")
	pv_atac_log		= register_cvar("atac_log", "1")
	
	pv_mp_roundtime		= get_cvar_pointer("mp_roundtime")
	pv_mp_freezetime	= get_cvar_pointer("mp_freezetime")
	
	new atacpath[64]
	get_configsdir( atacpath, 63 )
	server_cmd("exec %s/atac/atac.cfg", atacpath )
	server_cmd("mp_tkpunish 0")
	server_cmd("mp_autokick 0")
	
	map_cors_pre = map_cors_present(map_cors_origin) /* check if that map has coordinates */
	
	/* SyncObjects */
	g_HudSyncBomb	= CreateHudSyncObj()
	g_HudSyncBan	= CreateHudSyncObj()
	g_HudSyncDamg	= CreateHudSyncObj()
	g_HudSyncHostel	= CreateHudSyncObj()
	
}

public plugin_precache()
	{
	m_fireball	= precache_model("sprites/zerogxplode.spr")
	mflash		= precache_model("sprites/muzzleflash.spr")
	r_trail		= precache_model("sprites/smoke.spr")
	light		= precache_model("sprites/lgtning.spr")
	smoke		= precache_model("sprites/steam1.spr")
	white		= precache_model("sprites/white.spr")
	fire		= precache_model("sprites/xfireball3.spr")
	
	precache_sound("ambience/thunder_clap.wav")
	precache_sound("ambience/flameburst1.wav")
	precache_sound("scientist/scream21.wav")
	precache_sound("scientist/scream07.wav")
	precache_sound("weapons/rocketfire1.wav")
	precache_sound("weapons/rocket1.wav")
}

public plugin_modules()
	{
	require_module("fun")
}

/***********************************  TA FUNCTION *********************************/
public event_Damage(vIndex)
	{
	
	switch ( get_pcvar_num ( pv_atac_tacontrol ) )
	{
		case 0:
		return PLUGIN_CONTINUE
	}
	
	#if defined IDNULLFIX
	switch ( vIndex )
	{
		case 0:
		return PLUGIN_CONTINUE
	}
	
	static aIndex
	
	aIndex			= get_user_attacker(vIndex)
	
	switch ( aIndex )
	{
		case 0:
		return PLUGIN_CONTINUE
	}
	#else
	static aIndex
	
	aIndex			= get_user_attacker(vIndex)
	#endif
	
	static aTeam
	static vTeam
	static atac_hudmessages
	static atac_tanotallowedfor
	
	aTeam			= get_user_team ( aIndex )
	vTeam			= get_user_team ( vIndex )
	atac_hudmessages	= get_pcvar_num ( pv_atac_hudmessages )
	atac_tanotallowedfor	= get_pcvar_num ( pv_atac_tanotallowedfor )
	
	if(aTeam != vTeam || vIndex == aIndex)
		{
		return PLUGIN_CONTINUE
	}
	
	new damage = read_data(2)
	
	// Set TA hud msg format
	set_hudmessage((aTeam == 1) ? 140 : 0, (aTeam == 2) ? 100 : 0, (aTeam == 2) ? 200 : 0, 0.75, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
	
	// Immunity Check
	if((get_user_flags(aIndex) & ATAC_IMMUNITY_LEVEL) && get_pcvar_num(pv_atac_admins_immune))
		{
		atac_hudmessages ? ShowSyncHudMsg(aIndex, g_HudSyncDamg, "%L", aIndex, "TA_WARNING_ADMIN_MSG", damage) :  client_print(aIndex, 3, "%L", aIndex, "TA_WARNING_ADMIN_MSG", damage)
		if(get_pcvar_num(pv_atac_ta_restore) == 2 && is_user_alive(vIndex))
			{
			set_player_health(vIndex, get_user_health(vIndex) + damage)
		}
		return PLUGIN_CONTINUE
	}
	
	switch ( taAllowed )
	{
		case 0:
		{
			switch ( atac_tanotallowedfor )
			{
				case 0:
				{
					return PLUGIN_CONTINUE
				}				
				default:
				{
					static aName[32]
					get_user_name(aIndex, aName, 31)
					
					// Set TK hud msg format
					set_hudmessage((aTeam == 1) ? 140 : 0, (aTeam == 2) ? 100 : 0, (aTeam == 2) ? 200 : 0, 0.75, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
					atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncDamg, "%L", LANG_PLAYER, "TANOTALLOWEDFOR_MSG", aName, atac_tanotallowedfor) : client_print(0, 3, "%L", LANG_PLAYER, "TANOTALLOWEDFOR_MSG", aName, atac_tanotallowedfor)
					slay(aIndex, 1)
				}
			}
		}
		case 1:
		{
			// Increase attackers TA by index
			TA[aIndex]++
			
			new atac_ta_equal_v = get_pcvar_num(pv_atac_ta_equal_v)
			
			atac_hudmessages ? ShowSyncHudMsg(aIndex, g_HudSyncDamg, "%L", aIndex, "TA_WARNING_MSG", TA[aIndex], atac_ta_equal_v, damage) : client_print(aIndex, 3, "%L", aIndex, "TA_WARNING_MSG", TA[aIndex], atac_ta_equal_v, damage)
			
			// Slap bit
			if(get_pcvar_num(pv_atac_ta_slap))
				{
				player_slap(aIndex, 0)
			}
			// Mirror Damage bit
			switch ( get_pcvar_num ( pv_atac_ta_mirrordmg ) )
			{
				case 1:
				{
					new aHeath = get_user_health(aIndex)
					if(damage >= aHeath)
						{
						set_player_health(aIndex, 1)
					}
					else
						{
						set_player_health(aIndex, aHeath - damage)
					}
				}
			}
			// Restore bit
			if(get_pcvar_num(pv_atac_ta_restore) && is_user_alive(vIndex))
				{
				set_player_health(vIndex, get_user_health(vIndex) + damage)
			}
			// Check for last warning
			if(TA[aIndex] == atac_ta_equal_v)
				{
				// If TA is equal to get_cvar_num("atac_ta_equal_v") then treat it as tk (add 1 TK point)
				KickMe[aIndex]++
				check_v(aIndex)
				// Reset TA count
				TA[aIndex] = 0
				switch ( get_pcvar_num ( pv_atac_slayonmaxtas ) )
				{
					case 1:
					{
						slay(aIndex, 1)
					}
				}
			}
			update_stat_text(aIndex)	
		}
	}
	return PLUGIN_CONTINUE
}

/**********************************  TK FUNCTIONS *********************************/
public event_Death(id)
	{
	if(get_pcvar_num(pv_atac_tkcontrol) == 1)
		{
		new kIndex = read_data(1)
		new vIndex = read_data(2)
		
		#if defined IDNULLFIX
		switch ( vIndex )
		{
			case 0:
			return PLUGIN_CONTINUE
		}
		
		switch ( kIndex )
		{
			case 0:
			return PLUGIN_CONTINUE
		}
		#endif
		
		if(PlayerFlags[vIndex] & TIMEBOMB)
			{
			new users[32], inum, kName[32]
			get_players(users, inum, "c")
			get_user_name(kIndex, kName, 31)
			client_print(0, 3, "%L", LANG_PLAYER, "NEUTRALIZED_TIMEBOMB_MSG", kName)
			PlayerFlags[vIndex] -= TIMEBOMB
		}
		if(PlayerFlags[vIndex] & FIRE)
			{
			emit_sound(kIndex, CHAN_AUTO, "scientist/scream21.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
			PlayerFlags[vIndex] -= FIRE
		}
		if(kIndex && kIndex != vIndex)
			{
			if(get_user_team(kIndex) == get_user_team(vIndex)) // Check indexes of teams
				{
				if( get_pcvar_num(pv_atac_admins_immune) && (get_user_flags(kIndex) & ATAC_IMMUNITY_LEVEL))
					{
					// If you can't punish admins display this
					client_print(vIndex, 3, "%L", vIndex, "CANT_PUNISH_ADMINS_MSG")
					
				}
				else
					{
					// Store who killed who for history
					TKHistory[kIndex][vIndex]++
					if(get_pcvar_num(pv_atac_menu) == 1)
						{
						TK[kIndex][vIndex]++
						// Check to see if someone needs the menu sent to them
						if(KickMe[kIndex] >= get_pcvar_num(pv_atac_tk_before_ban) - 1)
							{
							MenuPage[vIndex] = 3 //Ban Menu
						}
						else
							{
							MenuPage[vIndex] = 1
						}
						//						new param[2]
						//						param[0] = kIndex
						//						param[1] = vIndex
						menu_status(kIndex, vIndex)
						//						set_task(0.1, "delay_menu", 1034+vIndex , param, 2)
					}
					else if(get_pcvar_num(pv_atac_menu) == 0)
						{
						KickMe[kIndex]++
						check_v(kIndex)
					}
					update_stat_text(kIndex)
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

//**********************************
// Delay Show Menu for 1 sec for any menu that show up after respawn or if a player
// open a menu as the player get TK so that TK menu will not get overwritten.
//**********************************

public delay_menu(param[])
	{
	new kIndex = param[0]
	new vIndex = param[1]
	menu_status(kIndex, vIndex)
	return PLUGIN_CONTINUE
}

//**********************************
//  Player Menu Check
//**********************************

menu_status(kIndex, vIndex)
{
	#if defined IDNULLFIX
	switch ( vIndex )
	{
		case 0:
		return PLUGIN_CONTINUE
	}
	switch ( kIndex )
	{
		case 0:
		return PLUGIN_CONTINUE
	}
	#endif
	new menuid, keys
	get_user_menu(vIndex, menuid, keys)
	if(menuid <= 0)
		{
		show_atac_menu(kIndex, vIndex)
	}
	else if(menuid > 0)
		{
		new param[2]
		param[0] = kIndex
		param[1] = vIndex
		set_task(1.0, "menu_status_check", 1032+vIndex , param, 2,"b")
	}
	return PLUGIN_CONTINUE
}

// Return to menu status to do a check
public menu_status_check(param[])
	{
	new kIndex = param[0]
	new vIndex = param[1]
	//	menu_status(kIndex, vIndex)
	//	return PLUGIN_CONTINUE
	if (!vIndex) return PLUGIN_CONTINUE
	
	new menuid, keys
	get_user_menu(vIndex, menuid, keys)
	if(menuid <= 0)
		{
		show_atac_menu(kIndex, vIndex)
		remove_task(1032+vIndex)
	}
	return PLUGIN_CONTINUE
}

find_killer(vIndex)
{
	// Get Killer (if more than one killer, handle last one in array order first)
	new kIndex = 0, maxplayers = get_maxplayers()
	for(new k = 1; k <= maxplayers; ++k)
		{
		if(TK[k][vIndex] > 0)
			{
			kIndex = k
		}
	}
	return kIndex
}

/********************************  HOSTAGE FUNCTIONS *******************************/
public event_hostkill(id)
	{
	if( get_pcvar_num(pv_atac_admins_immune) && (get_user_flags(id) & ATAC_IMMUNITY_LEVEL))
		{
		return PLUGIN_CONTINUE
	}
	if ( !get_pcvar_num(pv_atac_hostagepen) )
		{
		return PLUGIN_CONTINUE
	}
	
	KickMe[id]++
	check_v(id)
	return PLUGIN_CONTINUE
}

public event_hostinj(id)
	{
	if( get_pcvar_num(pv_atac_admins_immune) && (get_user_flags(id) & ATAC_IMMUNITY_LEVEL))
		{
		return PLUGIN_CONTINUE
	}
	if ( !get_pcvar_num(pv_atac_hostagepen) )
		{
		return PLUGIN_CONTINUE
	}
	
	new atac_hudmessages = get_pcvar_flags(pv_atac_hudmessages)
	new atac_ta_equal_v = get_pcvar_num(pv_atac_ta_equal_v)
	new aTeam = get_user_team(id)
	new aName[32]
	get_user_name(id, aName, 31)
	
	if(!taAllowed)
		{
		
		// Set TA hud msg format
		if(aTeam == 1)
			set_hudmessage(140, 0, 0, 0.05, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
		else if(aTeam == 2)
			set_hudmessage(0, 100, 200, 0.05, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
		
		atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncHostel, "%L", LANG_PLAYER, "HOSTAGE_NEWROUND_MSG", aName, atac_ta_equal_v) : client_print(0, 3, "%L", LANG_PLAYER, "HOSTAGE_NEWROUND_MSG", aName, atac_ta_equal_v)
		slay(id, 1)
	}
	else
		{
		TA[id]++
		set_hudmessage(0, 255, 0, 0.75, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
		atac_hudmessages ? ShowSyncHudMsg(id, g_HudSyncHostel, "%L", id, "HOSTAGE_INJURED_MSG", TA[id], atac_ta_equal_v) : client_print(id, 3, "%L", id, "HOSTAGE_INJURED_MSG", TA[id], atac_ta_equal_v)
		
		if(TA[id] == atac_ta_equal_v)
			{
			KickMe[id]++
			check_v(id)
			// Reset TA count
			TA[id] = 0
			if(get_pcvar_num(pv_atac_slayonmaxtas))
				{
				slay(id, 1)
			}
		}
		
	}
	return PLUGIN_CONTINUE
}

/********************************  CHECK TK FUNCTION *******************************/
check_v(kIndex)
{
	if(is_user_connected(kIndex))
		{
		// Check to see if player has any TK's left then ban or warn
		new kName[32]
		new kAuthid[32]
		new kIP[32]
		new Date[64]
		new BanInfo[256]
		get_user_name(kIndex, kName, 31)
		get_user_authid(kIndex, kAuthid, 31)
		get_user_ip(kIndex, kIP, 31, 1)
		get_time("%m/%d/%y %H:%M:%S", Date, 63)
		new kTeam = get_user_team(kIndex)
		// Set TK hud msg format
		set_hudmessage((kTeam == 1) ? 140 : 0, (kTeam == 2) ? 100 : 0, (kTeam == 2) ? 200 : 0, 0.05, 0.50, 2, 0.1, 4.0, 0.02, 0.02, -1)
		
		new atac_tk_before_ban = get_pcvar_num(pv_atac_tk_before_ban)
		new atac_banvia = get_pcvar_num(pv_atac_banvia)
		new atac_bantime = get_pcvar_num(pv_atac_bantime)
		new atac_hudmessages = get_pcvar_num(pv_atac_hudmessages)
		new atac_amxban = get_pcvar_num(pv_atac_amxban)
		
		update_stat_text(kIndex)
		
		// Check if user needs to be banned
		if(KickMe[kIndex] >= atac_tk_before_ban && is_user_connected(kIndex))
			{
			new userid = get_user_userid(kIndex)
			if(is_user_bot(kIndex))
				{
				atac_banvia = 3
			}
			if(atac_banvia == 1 || atac_banvia == 2)
				{
				if(atac_bantime)
					{
					client_print(kIndex, 1, "%L", kIndex, "TIME_BANNED_MSG", atac_bantime)
					atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_VOLATION_TIME_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_bantime) : client_print(0, 3, "%L", LANG_PLAYER, "TK_VOLATION_TIME_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_bantime)
					formatex(BanInfo, 255, "%L", LANG_SERVER, "TIME_BAN_LOG_MSG", Date, kName, kIP, kAuthid,KickMe[kIndex], atac_tk_before_ban, atac_bantime)
				}
				else
					{
					client_print(kIndex, 1, "%L", kIndex, "PERMA_BANNED_MSG")
					atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_VOLATION_PERMA_MSG", KickMe[kIndex], atac_tk_before_ban, kName) : client_print(0, 3, "%L", LANG_PLAYER, "TK_VOLATION_PERMA_MSG", KickMe[kIndex], atac_tk_before_ban, kName)
					formatex(BanInfo, 255, "%L", LANG_SERVER, "PERMA_BAN_LOG_MSG", Date, kName, kIP, kAuthid,KickMe[kIndex], atac_tk_before_ban)
				}
				//Reomved due to steam equal("4294967295", kAuthid)
				if(atac_banvia == 2) // If LAN or IP ban via IP
					{
					if(atac_amxban != 1)
						{
						server_cmd("addip %i %s;writeip;kick #%d", atac_bantime, kIP, userid)
					}
					else
						{
						server_cmd("amx_banip %i %s Max Team Kill Violation %i/%i", atac_bantime, kIP, KickMe[kIndex], get_pcvar_num(pv_atac_tk_before_ban))
					}
				}
				else
					{
					if( atac_amxban != 1)
						{
						server_cmd("banid %i #%d kick;writeid", atac_bantime, userid)
					}
					else
						{
						server_cmd("amx_ban %i %s Max Team Kill Violation %i/%i", atac_bantime, kAuthid, KickMe[kIndex], get_pcvar_num(pv_atac_tk_before_ban))
					}
				}
			}
			else if(atac_banvia == 3)
				{
				client_print(kIndex, 1, "%L", kIndex, "KICK_MSG")
				atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_VOLATION_KICK_MSG", KickMe[kIndex], atac_tk_before_ban, kName) : client_print(0, 3, "%L", LANG_PLAYER, "TK_VOLATION_KICK_MSG", KickMe[kIndex], atac_tk_before_ban, kName)
				formatex(BanInfo, 255, "%L", LANG_SERVER, "KICK_LOG_MSG", Date, kName, kIP, kAuthid, KickMe[kIndex], atac_tk_before_ban)
				server_cmd("kick #%d", userid)
			}
			if(get_pcvar_num(pv_atac_log) == 1)
				{
				new filepath[64], filename[128]
				get_configsdir( filepath, 63 )
				format(filepath, 63, "%s/atac", filepath)
				formatex(filename, 127, "%s/atac.log", filepath)
				write_file(filename, BanInfo, -1)
			}
		}
		else
			{
			if(atac_banvia == 1 || atac_banvia == 2)
				{
				if(atac_bantime)
					{
					atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_TIME_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban, atac_bantime) : client_print(0, 3, "%L", LANG_PLAYER, "TK_TIME_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban, atac_bantime)
				}
				else
					{
					atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_PERMA_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban) : client_print(0, 3, "%L", LANG_PLAYER, "TK_PERMA_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban)
				}
			}
			else if(atac_banvia == 3)
				{
				atac_hudmessages ? ShowSyncHudMsg(0, g_HudSyncBan, "%L", LANG_PLAYER, "TK_KICK_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban) : client_print(0, 3, "%L", LANG_PLAYER, "TK_KICK_MSG", KickMe[kIndex], atac_tk_before_ban, kName, atac_tk_before_ban)
			}
		}
	}
}
/******************************* Slay Next Spawn Delay *******************************/
public event_delaydeath(id)
	{
	slay(id, 1)
	return PLUGIN_CONTINUE
}

/*******************************  RESPAWN FUNCTIONS ********************************/
public event_respawn(id)
	{
	if((get_cvar_num("csdm_active") == 1) || (get_pcvar_num(pv_atac_dm) == 1) || (get_cvar_num("tdm_state") == 1))
		{
		if(is_user_connected(id) == 1 )
			{
			new atac_handlenames = get_pcvar_num(pv_atac_handlenames)
			if(PlayerFlags[id] & SETTODIE && is_user_alive(id))
				{
				set_task(0.5, "event_delaydeath", id)
				PlayerFlags[id] -= SETTODIE
			}
			if(PlayerFlags[id] & JAILED)
				{
				if(atac_handlenames)
					{
					set_user_info(id, "name", StoredName[id])
				}
				new name[32]
				get_user_info(id, "name", name, 31)
				client_print(0, 3, "%L", LANG_PLAYER, "JAIL_MSG", name)
				PlayerFlags[id] -= JAILED
				JailedCount--
			}
			if(PlayerFlags[id] & CHICKEN)
				{
				/*  	if(atac_handlenames)
				{
					set_user_info(id, "name", StoredName[id])
				}*/
				new u_id = get_user_userid(id)					// KWo - 22.11.2005
				server_cmd("c_unchicken #%i", u_id)			// KWo - 22.11.2005
				new name[32]
				get_user_info(id, "name", name, 31)
				client_print(0, 3, "%L", LANG_PLAYER, "CHICKEN_MSG", name)
				PlayerFlags[id] -= CHICKEN
				ChickenCount--
			}
			if(PlayerFlags[id] & GLOWING)
				{
				set_player_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 1)
				PlayerFlags[id] -= GLOWING
			}
			if(PlayerFlags[id] & BLIND)
				{
				PlayerFlags[id] -= BLIND
			}
			if((PlayerFlags[id] & DRUG))
				{
				PlayerFlags[id] -= DRUG
				message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
				write_byte(90)
				message_end()
			}
		}
	}
	update_stat_text(id)
	return PLUGIN_CONTINUE
}

/*******************************  START ROUND FUNCTIONS ****************************/
public preround_start()
	{
	new atac_handlenames = get_pcvar_num(pv_atac_handlenames)
	new maxplayers = get_maxplayers()
	for(new j = 1; j <= maxplayers; ++j)
		{
		if(PlayerFlags[j] & SETTODIE && is_user_connected(j))
			{
			slay(j, 1)
			PlayerFlags[j] -= SETTODIE
		}
		if(PlayerFlags[j] & CHICKEN && is_user_connected(j))
			{
			/*			if(atac_handlenames)
			{
				set_user_info(j, "name", StoredName[j])
			}*/
			new u_id = get_user_userid(j)					// KWo - 22.11.2005
			server_cmd("c_unchicken #%i", u_id)		// KWo - 22.11.2005
			new name[32]
			get_user_info(j, "name", name, 31)
			client_print(0, 3, "%L", LANG_PLAYER, "CHICKEN_MSG", name)
			PlayerFlags[j] -= CHICKEN
			ChickenCount--
		}
		if(PlayerFlags[j] & JAILED && is_user_connected(j))
			{
			if(atac_handlenames)
				{
				set_user_info(j, "name", StoredName[j])
			}
			new name[32]
			get_user_info(j, "name", name, 31)
			client_print(0, 3, "%L", LANG_PLAYER, "JAIL_MSG", name)
			PlayerFlags[j] -= JAILED
			JailedCount--
		}
		if(PlayerFlags[j] & GLOWING && is_user_connected(j))
			{
			set_player_rendering(j, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 1)
			PlayerFlags[j] -= GLOWING
		}
		if(PlayerFlags[j] & BLIND && is_user_connected(j))
			{
			PlayerFlags[j] -= BLIND
		}
		if(PlayerFlags[j] & DRUG && is_user_connected(j))
			{
			PlayerFlags[j] -= DRUG
			message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, j)
			write_byte(90)
			message_end()
		}
	}
	return PLUGIN_CONTINUE
}

public event_RoundTime()
	{
	new Float:roundtime = get_pcvar_float(pv_mp_roundtime) * 60.0
	new rtime = read_data(1)
	
	// Round Start at start of freeze time
	if(get_pcvar_num(pv_mp_freezetime) == rtime)
		{
		set_task(0.3, "preround_start")
		new maxplayers = get_maxplayers()
		for(new i = 1; i <= maxplayers; ++i)
			{
			TA[i] = 0
		}
	}
	// Round Start after freezetime
	else if(roundtime == rtime)
		{
		new Float:tanot = get_pcvar_float(pv_atac_tanotallowedfor)
		if(tanot)
			{
			// Set timer for TA within x seconds get slayed
			taAllowed = false
			set_task(tanot, "ta_NA_timer")
		}
		//atac_tacontrol = get_pcvar_num(pv_atac_tacontrol)
	}
	return PLUGIN_CONTINUE
}

public ta_NA_timer()
	{
	taAllowed = true
	return PLUGIN_HANDLED
}

/********************************  MENU FUNCTIONS *********************************/
show_atac_menu(kIndex, vIndex)
{
	if(is_user_bot(vIndex))
		{
		set_task(0.5, "bot_tk", vIndex)
		return PLUGIN_HANDLED
	}
	new menuoption[10][64]
	new menu[8]
	new keys
	new atac_options = get_pcvar_num(pv_atac_options)
	new kName[32], menubody[512]
	get_user_name(kIndex, kName, 31)
	// Clear string
	for(new z = 0; z < 10; ++z)
		{
		menuoption[z][0] = 0
	}
	switch(MenuPage[vIndex])
	{
		case 1:		/* PAGE 1*/
		{
			copy(menu, 7, "1/2")
			keys |= (1<<0)
			formatex(menuoption[0], 63, "1. %L", vIndex, "MENU_FORGIVE")
			if(atac_options & OPTION_SLAP)
				{
				keys |= (1<<1)
				formatex(menuoption[1], 63, "2. %L", vIndex, "MENU_SLAP", get_pcvar_num(pv_atac_slap_amount))
			}
			if(atac_options & OPTION_SLAPTO1)
				{
				keys |= (1<<2)
				formatex(menuoption[2], 63, "3. %L", vIndex, "MENU_SLAP1HP")
			}
			if(atac_options & OPTION_SLAYNR)
				{
				keys |= (1<<3)
				if((get_cvar_num("csdm_active") == 1) || (get_pcvar_num(pv_atac_dm) == 1) || (get_cvar_num("tdm_state") == 1))
					{
					formatex(menuoption[3], 63, "4. %L", vIndex, "MENU_SLAYNS")
				}
				else
					{
					formatex(menuoption[3], 63, "4. %L", vIndex, "MENU_SLAYNR")
				}
			}
			if(atac_options & OPTION_JAIL  && map_cors_pre)
				{
				keys |= (1<<4)
				formatex(menuoption[4], 63, "5. %L", vIndex, "MENU_JAIL" , get_pcvar_num(pv_atac_jail_time))
			}
			if(atac_options & OPTION_CHICKEN && cvar_exists("chicken_version"))
				{
				keys |= (1<<5)
				formatex(menuoption[5], 63, "6. %L", vIndex, "MENU_CHICKEN")
			}
			if(atac_options & OPTION_BURY)
				{
				keys |= (1<<6)
				formatex(menuoption[6], 63, "7. %L", vIndex, "MENU_BURY")
			}
			if(atac_options & OPTION_GLOW)
				{
				keys |= (1<<7)
				formatex(menuoption[7], 63, "8. %L", vIndex, "MENU_GLOW")
			}
			if(atac_options & OPTION_BOMB)
				{
				keys |= (1<<8)
				formatex(menuoption[8], 63, "9. %L", vIndex, "MENU_TIMEBOMB")
			}
			if(atac_options & OPTION_BLIND || atac_options & OPTION_ROCKET || atac_options & OPTION_DROP || atac_options & OPTION_FIRE || atac_options & OPTION_DRUG)
				{
				keys |= (1<<9)
				formatex(menuoption[9], 63,  "0. %L", vIndex, "MENU_MORE")
			}
			formatex(menubody, 511, "\d[ATAC] Menu %s:\w^n%L \r%s^n^n\w%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n^n%s",
			menu, vIndex, "MENU_CPF", kName, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4], menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(vIndex, keys, menubody, -1, "[ATAC] Menu")
		}
		case 2:		/* PAGE 2*/
		{
			copy(menu, 7, "2/2")
			if(atac_options & OPTION_BLIND)
				{
				keys |= (1<<0)
				formatex(menuoption[0], 63, "1. %L", vIndex, "MENU_BLIND")
			}
			if(atac_options & OPTION_ROCKET)
				{
				keys |= (1<<1)
				formatex(menuoption[1], 63, "2. %L", vIndex, "MENU_ROCKET")
			}
			if(atac_options & OPTION_DROP)
				{
				keys |= (1<<2)
				formatex(menuoption[2], 63, "3. %L", vIndex, "MENU_DROP")
			}
			if(atac_options & OPTION_FIRE)
				{
				keys |= (1<<3)
				formatex(menuoption[3], 63, "4. %L", vIndex, "MENU_FIRE")
			}
			if(atac_options & OPTION_DRUG)
				{
				keys |= (1<<4)
				formatex(menuoption[4], 63, "5. %L", vIndex, "MENU_DRUG")
			}
			keys |= (1<<9)
			formatex(menuoption[9], 63, "0. %L", vIndex, "MENU_BACK")
			
			formatex(menubody, 511, "\d[ATAC] Menu %s:\w^n%L \r%s^n^n\w%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n^n%s",
			menu, vIndex, "MENU_CPF", kName, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4], menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(vIndex, keys, menubody, -1, "[ATAC] Menu")
		}
		case 3:		/* PAGE 3 BAN/KICK MENU */
		{
			new atac_bantime = get_pcvar_num(pv_atac_bantime)
			keys |= (1<<0)|(1<<1)
			copy(menu, 7, "Final")
			formatex(menuoption[0], 63, "1. %L", vIndex, "MENU_FORGIVE")
			if(get_pcvar_num(pv_atac_banvia) == 1 || get_pcvar_num(pv_atac_banvia) == 2)
				{
				atac_bantime ? formatex(menuoption[1], 63, "2. %L", vIndex, "MENU_TIMEBAN", atac_bantime) : formatex(menuoption[1], 63, "2. %L", vIndex, "MENU_PERMABAN")
			}
			else
				{
				formatex(menuoption[1], 63, "2. %L", vIndex, "MENU_KICK")
			}
			formatex(menubody, 511, "\d[ATAC] Menu %s:\w^n%L \r%s^n^n\w%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n%s^n^n%s",
			menu, vIndex, "MENU_CPF", kName, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4], menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(vIndex, keys, menubody, -1, "[ATAC] Menu")
		}
	}
	return PLUGIN_HANDLED
}

menu_check(vIndex)
{
	new maxplayers = get_maxplayers()
	for(new k = 1; k <= maxplayers; ++k)
		{
		if(TK[k][vIndex] > 0)
			{
			MenuPage[vIndex] = 1
			show_atac_menu(k, vIndex)
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public action_atac_menu(vIndex, key)
	{
	new kIndex = find_killer(vIndex)
	new vName[32], kName[32]
	get_user_name(vIndex, vName, 31)
	get_user_name(kIndex, kName, 31)
	switch(MenuPage[vIndex])
	{
		case 1:
		{
			switch(key)
			{
				case 0: /* Option Forgive */
				{
					if(is_user_connected(kIndex))
						{
						TK[kIndex][vIndex]--
						menu_check(vIndex)
						client_print(0, 3, "%L", LANG_PLAYER, "FORGIVE_MSG", vName, kName)
						return PLUGIN_HANDLED
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_FORGIVE")
						return PLUGIN_HANDLED
					}
				}
				case 1: /* Option Slap */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "SLAP_AROUND_MSG", kName, get_pcvar_num(pv_atac_slap_amount), vName)
						SlapXTimes(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_SLAP", get_pcvar_num(pv_atac_slap_amount))
						return PLUGIN_HANDLED
						
					}
				}
				case 2: /* Option Slap to 1hp */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "SLAPTO1HP_MSG", kName, vName)
						SlapTo1(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_SLAP1HP")
						return PLUGIN_HANDLED
					}
				}
				case 3: /* Option Slay Next Round */
				{
					if(is_user_connected(kIndex))
						{
						if((get_cvar_num("csdm_active") == 1) || (get_pcvar_num(pv_atac_dm) == 1) || (get_cvar_num("tdm_state") == 1))
							{
							client_print(0, 3, "%L", LANG_PLAYER, "SLAYNEXTSPAWN_MSG", kName, vName)
						}
						else
							{
							client_print(0, 3, "%L", LANG_PLAYER, "SLAYNEXTROUND_MSG", kName, vName)
						}
						SlayNextRound(kIndex)
					}
					else
						{
						if((get_cvar_num("csdm_active") == 1) || (get_pcvar_num(pv_atac_dm) == 1) || (get_cvar_num("tdm_state") == 1))
							{
							client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_SLAYNS")
						}
						else
							{
							client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_SLAYNR")
						}
						return PLUGIN_HANDLED
					}
				}
				case 4: /* Option Jail */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "JAILED_SEC_MSG", kName, get_pcvar_num(pv_atac_jail_time), vName)
						Jail(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_JAIL", get_pcvar_num(pv_atac_jail_time))
						return PLUGIN_HANDLED
					}
				}
				case 5: /* Option Chicken */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "TURN_CHICKEN_MSG", kName, vName)
						Chicken(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_CHICKEN")
						return PLUGIN_HANDLED
					}
				}
				case 6: /* Option Bury */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "BURIED_MSG",  kName, vName)
						Bury(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_BURY")
						return PLUGIN_HANDLED
					}
				}
				case 7: /* Option Glow */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "GLOW_MSG", kName, vName)
						Glow(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_GLOWED")
						return PLUGIN_HANDLED
					}
				}
				case 8: /* Option Bomb */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "TIMEBOMB_MSG", kName, vName)
						TimeBomb(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_TIMEBOMB")
						return PLUGIN_HANDLED
					}
				}
				case 9: /* Option More...*/
				{
					MenuPage[vIndex]++
					show_atac_menu(kIndex, vIndex)
					return PLUGIN_HANDLED
				}
			}
		}
		case 2:
		{
			switch(key)
			{
				case 0: /* Option Blind */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "BLIND_MSG", kName, vName)
						Blind(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_BLIND")
						return PLUGIN_HANDLED
					}
				}
				case 1: /* Option Rocket */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "ROCKET_MSG", kName, vName)
						Rocket(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_ROCKET")
						return PLUGIN_HANDLED
					}
				}
				case 2: /* Option Drop */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "DROPPED_MSG", kName, vName)
						Raise(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_DROP")
						return PLUGIN_HANDLED
					}
				}
				case 3: /* Option Fire */
				{
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "FIRE_MSG", kName, vName)
						Fire(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_FIRE")
						return PLUGIN_HANDLED
					}
				}
				case 4: /* Option Drug */
				{
					
					if(is_user_connected(kIndex))
						{
						client_print(0, 3, "%L", LANG_PLAYER, "DRUG_MSG", kName, vName)
						Drug(kIndex)
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_DRUG")
						return PLUGIN_HANDLED
					}
				}
				case 9: /* Option Back... */
				{
					MenuPage[vIndex]--
					show_atac_menu(kIndex, vIndex)
					return PLUGIN_HANDLED
				}
			}
		}
		case 3:
		{
			switch(key)
			{
				case 0: /* Option Forgive */
				{
					if(is_user_connected(kIndex))
						{
						TK[kIndex][vIndex]--
						menu_check(vIndex)
						client_print(0, 3, "%L", LANG_PLAYER, "FORGIVE_MSG", vName, kName)
						return PLUGIN_HANDLED
					}
					else
						{
						client_print(vIndex, 3, "%L", vIndex, "NOTFOUND_FORGIVE")
						return PLUGIN_HANDLED
					}
				}
			}
		}
	}
	TK[kIndex][vIndex]--
	menu_check(vIndex)
	KickMe[kIndex]++
	check_v(kIndex)
	return PLUGIN_HANDLED
}
public user_menu_check(id)
	{
	// Future code for checking if their a player has a menu open
	return PLUGIN_CONTINUE
}


/**********************************  BOTS  ****************************************/

public bot_tk(id)
	{
	new atac_options = get_pcvar_num(pv_atac_options)
	new g_key = 0
	if(MenuPage[id] == 1)
		{
		g_key = random_num(0, 13)
		while(((g_key == 1) && (!(atac_options & OPTION_SLAP)))
		|| ((g_key == 2) && (!(atac_options & OPTION_SLAPTO1)))
		|| ((g_key == 3) && (!(atac_options & OPTION_SLAYNR)))
		|| ((g_key == 4) && ((!(atac_options & OPTION_JAIL)) || (!map_cors_pre)))
		|| ((g_key == 5) && ((!(atac_options & OPTION_CHICKEN)) || (!(cvar_exists("chicken_version")))))
		|| ((g_key == 6) && (!(atac_options & OPTION_BURY)))
		|| ((g_key == 7) && (!(atac_options & OPTION_GLOW)))
		|| ((g_key == 8) && (!(atac_options & OPTION_BOMB)))
		|| ((g_key == 9) && (!(atac_options & OPTION_BLIND)))
		|| ((g_key == 10) && (!(atac_options & OPTION_ROCKET)))
		|| ((g_key == 11) && (!(atac_options & OPTION_DROP)))
		|| ((g_key == 12) && (!(atac_options & OPTION_FIRE)))
		|| ((g_key == 13) && (!(atac_options & OPTION_DRUG))))
		{
			g_key = random_num(0, 13)
		}
	}
	if(MenuPage[id] == 1 && g_key >= 9)
		{
		MenuPage[id] = 2
		bot_tk(id)
		g_key = 9
		return PLUGIN_HANDLED
	}
	if(MenuPage[id] == 2)
		{
		g_key = random_num(0, 4)
		while(((g_key == 0) && (!(atac_options & OPTION_BLIND)))
		|| ((g_key == 1) && (!(atac_options & OPTION_ROCKET)))
		|| ((g_key == 2) && (!(atac_options & OPTION_DROP)))
		|| ((g_key == 3) && (!(atac_options & OPTION_FIRE)))
		|| ((g_key == 4) && (!(atac_options & OPTION_DRUG))))
		{
			g_key = random_num(0, 4)
		}
	}
	if(MenuPage[id] == 3)
		{
		g_key = random_num(0, 1)
	}
	action_atac_menu(id, g_key)
	return PLUGIN_HANDLED
}

/*************************** CATCHES NAME CHANGES  ********************************/

public client_infochanged(id)
	{
	if(PlayerFlags[id] & JAILED && (get_cvar_num("amx_forcetag") != 1) && (id != 0))
		{
		new newname[33], oldname[33]
		get_user_info(id, "name", newname, 32)
		get_user_name(id, oldname, 32)
		
		if(!equal(oldname, newname))
			{
			jail_name(id)
		}
	}
	return PLUGIN_CONTINUE
}

/**********************************  PUNISHMENTS  ********************************/
public slap(skIndex[])
	{
	new kIndex = skIndex[0]
	new atac_slap_power = get_pcvar_num(pv_atac_slap_power)
	
	if(is_user_alive(kIndex))
		{
		if(get_user_health(kIndex) <= atac_slap_power)
			{
			player_slap(kIndex, 0)
		}
		else
			{
			player_slap(kIndex, atac_slap_power)
		}
	}
	return PLUGIN_CONTINUE
}

SlapXTimes(player)
{
	new splayer[2]
	splayer[0] = player
	
	if(is_user_alive(player))
		{
		set_task(get_pcvar_float(pv_atac_slap_freq), "slap", 0, splayer, 2, "a", get_pcvar_num(pv_atac_slap_amount) - 1)
	}
}

SlapTo1(player)
{
	new user_health = get_user_health(player)
	player_slap(player, user_health - 1)
}

SlayNextRound(player)
{
	if(!(PlayerFlags[player] & SETTODIE))
		{
		PlayerFlags[player] += SETTODIE
	}
}

// Functions to check if player is alive or still connected to server

player_slap(player, slappower)
{
	if(is_user_connected(player) && is_user_alive(player))
		{
		user_slap(player, slappower)
	}
}

set_player_health(player, amount)
{
	if(is_user_connected(player) && is_user_alive(player))
		{
		set_user_health(player, amount)
	}
}

set_player_rendering(player, fx, r, g, b, render, amount, alive)
{
	// Alive = 1 mean check if player is alive. Alive = 0 mean don't check if player is alive.
	if(is_user_connected(player) && is_user_alive(player) && (alive == 1))
		{
		set_user_rendering(player, fx, r, g, b, render, amount)
	}
	else if(is_user_connected(player) && (alive == 0))
		{
		set_user_rendering(player, fx, r, g, b, render, amount)
	}
}

/********************************** JAIL  *****************************/
jail_name(id)
{
	new JailName[32]
	formatex(JailName, 31, "Inmate #%i", id)
	set_user_info(id, "name", JailName)
}

Jail(player)
{
	if(is_user_alive(player) && !(PlayerFlags[player] & JAILED))
		{
		PlayerFlags[player] += JAILED
		JailedCount++
		if(get_pcvar_num(pv_atac_handlenames))
			{
			new name[32]
			get_user_name(player, name, 31)
			StoredName[player] = name
			jail_name(player)
		}
		DropWeapons(player)
		//Teleport
		get_user_origin(player, PreJailOrigin[player])
		PreJailOrigin[player][2] += 5
		set_user_origin(player, map_cors_origin)
		set_task(get_pcvar_float(pv_atac_jail_time), "un_jail", player)
		// client_print(0, 1, "DEBUG: x:%i, y:%i, z:%i", map_cors_origin[0], map_cors_origin[1], map_cors_origin[2])
	}
}

map_cors_present(maporigin[3])
{
	new filename[128], atacpath[64]
	get_configsdir( atacpath, 63 )
	format(atacpath, 63, "%s/atac", atacpath)
	formatex(filename, 127, "%s/atac.cor", atacpath)
	if(file_exists(filename))
		{
		new readdata[64]
		new currentmap[32]
		get_mapname(currentmap, 31)
		new map[32], x[16], y[16], z[16], len
		for(new i = 0; i < 100 && read_file(filename, i, readdata, 63, len); ++i)
			{
			parse(readdata, map, 31, x, 15, y, 15, z, 15)
			if(equal(map, currentmap))
				{
				maporigin[0] = str_to_num(x)
				maporigin[1] = str_to_num(y)
				maporigin[2] = str_to_num(z)
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public un_jail(player)
	{
	if(is_user_alive(player) && PlayerFlags[player] & JAILED)
		{
		if(get_pcvar_num(pv_atac_handlenames))
			{
			set_user_info(player, "name", StoredName[player])
		}
		new name[32]
		get_user_info(player, "name", name, 31)
		client_print(0, 3, "%L", LANG_PLAYER, "JAIL_MSG", name)
		set_user_origin(player, PreJailOrigin[player])
		PlayerFlags[player] -= JAILED
		JailedCount--
	}
	return PLUGIN_CONTINUE
}

/********************************** CHICKEN  *****************************/
Chicken(player)
{
	if(is_user_alive(player) && !(PlayerFlags[player] & CHICKEN))
		{
		PlayerFlags[player] += CHICKEN
		ChickenCount++
		new u_id = get_user_userid(player)		// KWo - 22.11.2005
		server_cmd("c_chicken #%i", u_id)			// KWo - 22.11.2005
		/*		emit_sound(player, CHAN_VOICE, "misc/chicken0.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		if(get_cvar_num("atac_handlenames"))
			{
			new name[32]
			get_user_name(player, name, 31)
			StoredName[player] = name
			client_cmd(player, "name ^"Chicken #00%i^"", ChickenCount)
		}*/
	}
}

/********************************** BURY  *****************************/
Bury(player)
{
	if(is_user_alive(player))
		{
		DropWeapons(player)
		new origin[3]
		get_user_origin(player, origin)
		origin[2] -= 30
		set_user_origin(player, origin)
	}
}

DropWeapons(player)
{
	//Drop Weapons
	new iwpn, iwpns[32], nwpn[32]
	get_user_weapons(player, iwpns, iwpn)
	for(new a = 0; a < iwpn; ++a)
		{
		get_weaponname(iwpns[a], nwpn, 31)
		engclient_cmd(player, "drop", nwpn)
	}
}

/********************************** GLOW  *****************************/
Glow(player)
{
	if(is_user_alive(player) && !(PlayerFlags[player] & GLOWING))
		{
		PlayerFlags[player] += GLOWING
		set_player_rendering(player, kRenderFxGlowShell, 255, 0, 255, kRenderTransAlpha, 255, 1)
	}
}

/********************************** TIME BOMB *****************************/
TimeBomb(player)
{
	if(is_user_alive(player) && !(PlayerFlags[player] & TIMEBOMB))
		{
		PlayerFlags[player] += TIMEBOMB
		countdown[player] = 10
		set_task(1.0, "TimeBombLoop", player)
	}
}

public TimeBombLoop(player)
	{
	new speak[11][] = {"fire!", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
	new red = random_num(0, 255)
	new green = random_num(0, 255)
	new blue = random_num(0, 255)
	new alpha = random_num(100, 255)
	new kName[32]
	new players[32], inum
	get_user_name(player, kName, 31)
	
	if(is_user_alive(player) && (PlayerFlags[player] & TIMEBOMB))
		{
		set_hudmessage(red, green, blue, -1.0, 0.25, 0, 1.2, 1.2, 0.5, 0.15, -1)
		if(countdown[player] > 0)
			{
			// Glow Me
			set_player_rendering(player, kRenderFxGlowShell, red, green, blue, kRenderTransAlpha, alpha, 1)
			// Annouce Me
			get_players(players, inum, "c")
			for(new i = 0; i < inum; ++i)
				{
				client_cmd(players[i], "speak ^"fvox/%s^"", speak[countdown[player]])
				ShowSyncHudMsg(0, g_HudSyncBomb, "%L", LANG_PLAYER, "EXPLODE_MSG", kName, countdown[player])
			}
			message_begin(MSG_ONE, gmsgHealth, {0,0,0}, player)
			write_byte(countdown[player])
			message_end()
			message_begin(MSG_ONE, gmsgBattery, {0,0,0}, player)
			write_short(countdown[player])
			message_end()
			countdown[player]--
			// Call Again
			set_task(1.0, "TimeBombLoop", player)
		}
		else   //explode
			{
			if(PlayerFlags[player] & TIMEBOMB)
				{
				PlayerFlags[player] -= TIMEBOMB
			}
			set_player_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 1)
			get_players(players, inum, "c")
			for(new i = 0; i < inum; ++i)
				{
				client_cmd(players[i], "speak ^"hgrunt/%s^"", speak[countdown[player]])
				message_begin(MSG_ONE, gmsgShake, {0,0,0}, players[i])
				write_short(1<<14) // shake amount
				write_short(1<<14) // shake lasts this long
				write_short(1<<14) // shake noise frequency
				message_end()
			}
			// FIRE!
			ShowSyncHudMsg(0, g_HudSyncBomb, "%L", LANG_PLAYER, "TIMEBOMB_FIRE_MSG")
			slay(player, 3)
			
			// Fade to red, for bomber
			message_begin(MSG_ONE, gmsgFade, {0,0,0}, player)
			write_short(1<<15)
			write_short(1<<10)
			write_short(1<<1)
			write_byte(100)
			write_byte(0)
			write_byte(0)
			write_byte(255)
			message_end()
			
			if(get_pcvar_num(pv_atac_bomb_mode))
				{
				get_players(players, inum, "a")
				for(new i = 0; i < inum; ++i)
					{
					new pOrigin[3]
					new kOrigin[3]
					get_user_origin(players[i], pOrigin)
					get_user_origin(player, kOrigin)
					if(get_pcvar_num(pv_atac_bomb_range) > get_distance(kOrigin, pOrigin))
						{
						// Death Msg
						message_begin(MSG_ALL, gmsgDeathMsg)
						write_byte(player)
						write_byte(players[i])
						write_byte(0)
						write_string("ATAC Timebomb")
						message_end()
						slay(players[i], 0)
						
						// Fade to red, for everyone within bomb explosion
						message_begin(MSG_ONE, gmsgFade, {0,0,0}, player)
						write_short(1<<15)
						write_short(1<<10)
						write_short(1<<1)
						write_byte(100)
						write_byte(0)
						write_byte(0)
						write_byte(255)
						message_end()
					}
				}
			}
		}
	}
	else
		{
		set_player_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255, 0)
	}
}

/********************************** BLIND  *****************************/
Blind(player)
{
	if(is_user_alive(player) && !(PlayerFlags[player] & BLIND))
		{
		message_begin(MSG_ONE, gmsgFade, {0,0,0}, player)
		write_short(1<<12)
		write_short(1<<8)
		write_short(1<<0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		message_end()
		set_task(1.0, "dely_screen_fade", player)
		PlayerFlags[player] += BLIND
	}
}

public event_screen_fade(id)
	{
	set_task(0.6, "dely_screen_fade", id)
	return PLUGIN_CONTINUE
}

public dely_screen_fade(id)
	{
	if(PlayerFlags[id] & BLIND)
		{
		// Blind Bit
		message_begin(MSG_ONE, gmsgFade, {0,0,0}, id)
		write_short(1<<0)
		write_short(1<<0)
		write_short(1<<2)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(255)
		message_end()
	}
	return PLUGIN_CONTINUE
}

/********************************** ROCKET  *****************************/
Rocket(player)
{
	if(is_user_alive(player))
		{
		emit_sound(player, CHAN_VOICE, "weapons/rocketfire1.wav", 1.0, 0.5, 0, PITCH_NORM)
		set_user_maxspeed(player, 1.2)
		set_task(0.7, "rocket_sfx", player)
	}
}

public rocket_sfx(player)
	{
	if(is_user_alive(player))
		{
		set_user_gravity(player, -0.50)
		client_cmd(player, "+jump;wait;wait;-jump")
		emit_sound(player, CHAN_VOICE, "weapons/rocket1.wav", 1.0, 0.5, 0, PITCH_NORM)
		rocket_rise(player)
		
		message_begin(MSG_ONE,gmsgShake, {0,0,0}, player)
		write_short(1<<15) // shake amount
		write_short(1<<15) // shake lasts this long
		write_short(1<<15) // shake noise frequency
		message_end()
		
		// Rocket Trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(22) // TE_BEAMFOLLOW
		write_short(player)
		write_short(r_trail)
		write_byte(30)
		write_byte(2)
		write_byte(250)
		write_byte(250)
		write_byte(250)
		write_byte(250)
		message_end()
	}
	return PLUGIN_CONTINUE
}

public rocket_rise(player)
	{
	new origin[3]
	get_user_origin(player, origin)
	draw_fire(origin)
	
	message_begin(MSG_ONE, gmsgDamage, {0,0,0}, player)
	write_byte(30) // dmg_save
	write_byte(30) // dmg_take
	write_long(1<<16) // visibleDamageBits
	write_coord(origin[0]) // damageOrigin.x
	write_coord(origin[1]) // damageOrigin.y
	write_coord(origin[2]) // damageOrigin.z
	message_end()
	
	if(r_origin[player] == origin[2])
		{
		rocket_explode(player)
		return PLUGIN_HANDLED
	}
	r_origin[player] = origin[2]
	set_task(0.2, "rocket_rise",player)
	return PLUGIN_CONTINUE
}

public rocket_explode(player)
	{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(player)
	message_end()
	
	slay(player, 2)
	emit_sound(player, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, (1<<5), PITCH_NORM)
	set_user_maxspeed(player, 1.0)
	set_user_gravity(player, 1.00)
	return PLUGIN_CONTINUE
}

/********************************** DROP  *****************************/
public Raise(player)
	{
	if(is_user_alive(player))
		{
		set_user_gravity(player, -2.0)
		client_cmd(player, "+jump;wait;wait;-jump")
		set_task(0.2, "Drop", player)
	}
	else
		{
		set_user_gravity(player, 1.0)
	}
	return PLUGIN_CONTINUE
}

public Drop(player)
	{
	if(is_user_alive(player))
		{
		set_user_gravity(player, 3.0)
		set_task(0.5, "Raise", player)
	}
	else
		{
		set_user_gravity(player, 1.0)
	}
	return PLUGIN_CONTINUE
}

/********************************** FIRE  *****************************/
Fire(player)
{
	if(!(PlayerFlags[player] & FIRE))
		{
		PlayerFlags[player] += FIRE
		ignite_effects(player)
		ignite_player(player)
	}
}

public ignite_effects(player)
	{
	if(is_user_alive(player) && PlayerFlags[player] & FIRE)
		{
		new korigin[3]
		get_user_origin(player, korigin)
		draw_fire(korigin)
		set_task(0.2, "ignite_effects", player)
	}
	return PLUGIN_CONTINUE
}

public ignite_player(player)
	{
	if(is_user_alive(player) && PlayerFlags[player] & FIRE)
		{
		new korigin[3]
		new players[32], inum = 0
		new pOrigin[3]
		new kHeath = get_user_health(player)
		get_user_origin(player, korigin)
		
		// Create some damage
		set_player_health(player, kHeath - 5)
		message_begin(MSG_ONE, gmsgDamage, {0,0,0}, player)
		write_byte(30) // dmg_save
		write_byte(30) // dmg_take
		write_long(1<<21) // visibleDamageBits
		write_coord(korigin[0]) // damageOrigin.x
		write_coord(korigin[1]) // damageOrigin.y
		write_coord(korigin[2]) // damageOrigin.z
		message_end()
		
		// Create some sound
		emit_sound(player, CHAN_ITEM, "ambience/flameburst1.wav", 0.6, ATTN_NORM, 0, PITCH_NORM)
		
		// Ignite Others
		if(get_pcvar_num(pv_atac_fire_mode))
			{
			get_players(players, inum, "a")
			for(new i = 0; i < inum; ++i)
				{
				get_user_origin(players[i], pOrigin)
				if(get_distance(korigin, pOrigin) < 100)
					{
					if(!(PlayerFlags[players[i]] & FIRE))
						{
						new spIndex[2]
						spIndex[0] = players[i]
						new pName[32], kName[32]
						get_user_name(players[i], pName, 31)
						get_user_name(player, kName, 31)
						emit_sound(players[i], CHAN_WEAPON, "scientist/scream07.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
						PlayerFlags[players[i]] += FIRE
						ignite_player(players[i])
						ignite_effects(players[i])
						get_players(players, inum, "c")
						client_print(players[i], 3, "%L", players[i], "CAUGHT_FIRE_MSG", kName, pName)
					}
				}
			}
			players[0] = 0
			pOrigin[0] = 0
			korigin[0] = 0
		}
		// Call again in 1 second
		set_task(1.0, "ignite_player", player)
	}
	return PLUGIN_CONTINUE
}

/* FIRE SPECIAL EFFECTS */
draw_fire(vec1[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(17) // TE_SPRITE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(mflash)
	write_byte(20)
	write_byte(200)
	message_end()
	
	// Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1)
	write_byte(5) // TE_SMOKE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(smoke)
	write_byte(20)
	write_byte(15)
	message_end()
}

/********************************  DRUG FUNCTION *********************************/
Drug(player)
{
	if(is_user_alive(player))
		{
		if(!(PlayerFlags[player] & DRUG))
			{
			PlayerFlags[player] += DRUG
		}
		message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, player)
		write_byte(170)
		message_end()
		
	}
}

public event_SetFOV(id)
	{
	if(is_user_alive(id))
		{
		if((PlayerFlags[id] & DRUG))
			{
			message_begin(MSG_ONE, gmsgSetFOV, {0,0,0}, id)
			write_byte(170)
			message_end()
		}
	}
}


/********************************  SLAY FUNCTIONS *********************************/
slay(player, type)
{
	if(is_user_alive(player) && is_user_connected(player))
		{
		new origin[3]
		get_user_origin(player, origin)
		origin[2] = origin[2] - 26
		switch(type)
		{
			case 1:
			{
				lightning(origin)
				emit_sound(player, CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case 2:
			{
				explode(origin)
			}
			case 3:
			{
				fireball(origin)
			}
		}
		user_kill(player, 0)
	}
}

/* SLAYING SPECIAL EFFECTS */
lightning(vec1[3])
{
	// Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(0) // TE_BEAMPOINTS
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_coord(vec1[0] + 150)
	write_coord(vec1[1] + 150)
	write_coord(vec1[2] + 400)
	write_short(light)
	write_byte(1)
	write_byte(5)
	write_byte(2)
	write_byte(20)
	write_byte(30)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	message_end()
	
	// Sparks
	message_begin(MSG_PVS, SVC_TEMPENTITY, vec1)
	write_byte(9) // TE_SPARKS
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	message_end()
	
	// Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1)
	write_byte(5) // TE_SMOKE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(smoke)
	write_byte(10)
	write_byte(10)
	message_end()
}

explode(vec1[3])
{
	// Blast Circles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1)
	write_byte(21) // TE_BEAMCYLINDER
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 16)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] + 1936)
	write_short(white)
	write_byte(0)
	write_byte(0)
	write_byte(2)
	write_byte(16)
	write_byte(0)
	write_byte(188)
	write_byte(220)
	write_byte(255)
	write_byte(255)
	write_byte(0)
	message_end()
	
	// Explosion2
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(12) // TE_EXPLOSION2
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte(188)
	write_byte(10)
	message_end()
	
	// Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1)
	write_byte(5) // TE_SMOKE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(smoke)
	write_byte(2)
	write_byte(10)
	message_end()
}

fireball(vec1[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec1)
	write_byte(17) // TE_BEAMSPRITE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2] +256)
	write_short(fire)
	write_byte(120)
	write_byte(255)
	message_end()
	
	// Implosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(14) // TE_IMPLOSION
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_byte(100)
	write_byte(20)
	write_byte(5)
	message_end()
	
	// Random Explosions
	message_begin(MSG_PVS, SVC_TEMPENTITY, vec1)
	write_byte(3) // TE_EXPLOSION
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(m_fireball)
	write_byte(30)
	write_byte(12)
	write_byte(0) // TE_EXPLFLAG_NONE
	message_end()
	
	// Lots of Smoke
	message_begin(MSG_PVS, SVC_TEMPENTITY, vec1)
	write_byte(5) // TE_SMOKE
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2])
	write_short(smoke)
	write_byte(60)
	write_byte(10)
	message_end()
}

/**********************************  STATUS FUNCTION ********************************/
public update_stat_text(id)
	{
	#if defined LIVESTATUS
	// WarCraft 3 XP Compatibility
	if(get_cvar_num("sv_warcraft3") || !get_pcvar_num(pv_atac_status))
		{
		return PLUGIN_CONTINUE
	}
	if(is_user_bot(id) || id == 0)
		{
		return PLUGIN_CONTINUE
	}
	if(atac_status_off[id])
		{
		return PLUGIN_CONTINUE
	}
	new status[64]
	formatex(status, 63, "%L", id, "STATUS_MSG", KickMe[id], get_pcvar_num(pv_atac_tk_before_ban), TA[id], get_pcvar_num(pv_atac_ta_equal_v))
	message_begin(MSG_ONE, gmsgStatusText, {0,0,0}, id)
	write_byte(1)
	write_string(status)
	message_end()
	#endif
	return PLUGIN_CONTINUE
}



/***************************** CONNECTION FUNCTIONS ******************************/
#if !defined NO_STEAM
public client_authorized(id)
	#else
public client_connect(id)
	#endif
{
	if(!is_user_bot(id) && get_pcvar_num(pv_atac_savetks))
		{
		new storedauthid[32]
		new storedtk[3]
		new authid[32]
		get_user_authid(id, authid, 31)
		authids[id] = authid
		
		for(new x = 0; x <= savedtkcount; ++x)
			{
			parse(savedtks[x], storedauthid, 31, storedtk, 2)
			if(equal(storedauthid, authid)) KickMe[id] = str_to_num(storedtk)
		}
	}
	//Check client setinfo "atac_status_off" "value"
	new satac_status_off[3]
	get_user_info(id, "atac_status_off", satac_status_off, 2)
	atac_status_off[id] = str_to_num(satac_status_off)
}

public client_disconnect(id)
	{
	if(!is_user_bot(id) && get_pcvar_num(pv_atac_savetks))
		{
		new string[35]
		new storedauthid[32]
		new storedtk[3]
		new authid[32]
		new bool:found
		get_user_authid(id, authid, 31)
		
		// Check for auth id already stored
		for(new x = 0; x <= savedtkcount; ++x)
			{
			parse(savedtks[x], storedauthid, 31, storedtk, 2)
			if(equal(storedauthid, authid))
				{
				if(KickMe[id] >= get_pcvar_num(pv_atac_tk_before_ban))
					{
					// In Case of ban, unban and reconnect on same map
					formatex(string, 34, "%s 0", authids[id])
					savedtks[x] = string
				}
				else
					{
					formatex(string, 34, "%s %i", authids[id], KickMe[id])
					savedtks[x] = string
					found = true
				}
			}
			storedauthid[0] = 0
			storedtk[0] = 0
		}
		// If not stored, store
		if(!found && savedtkcount < 300)
			{
			formatex(string, 34, "%s %i", authids[id], KickMe[id])
			savedtks[savedtkcount] = string
			savedtkcount++
		}
	}
	for(new i = 1; i <= 32; ++i)
		{
		// If disconnecting player has been killed by anyone erase history of it
		TK[i][id] = 0
		TKHistory[i][id] = 0
		// If disconnecting player has killed anyone erase history of it
		TK[id][i] = 0
		TKHistory[id][i] = 0
	}
	StoredName[id][0] = 0
	PlayerFlags[id] = 0
	KickMe[id] = 0
	authids[id][0] = 0
}

/****************************** CLIENT/ADMIN FUNCTIONS *****************************/
public say_atacstatus(id, level, cid)
	{
	client_print(id, 3, "%L", id, "STATUS_MSG", KickMe[id], get_pcvar_num(pv_atac_tk_before_ban), TA[id], get_pcvar_num(pv_atac_ta_equal_v))
	return PLUGIN_HANDLED
}

public say_livestatus(id, level, cid)
	{
	if(atac_status_off[id])
		{
		atac_status_off[id] = 0
		update_stat_text(id)
		//On
		client_print(id, 3, "%L", id, "LIVESTATUS_MSG" )
	}
	else
		{
		atac_status_off[id] = 1
		// Reset atac_status_off
		message_begin(MSG_ONE, gmsgStatusText, {0,0,0}, id)
		write_byte(0)
		write_string("")
		message_end()
		
		//OFF
		client_print(id, 3, "%L", id, "DISABLELIVE_MSG" )
	}
	return PLUGIN_HANDLED
}

public say_whotkedme(id, level, cid)
	{
	#if !defined NO_STEAM
	// Look at all killers see if Victims Match
	new maxplayers = get_maxplayers()
	new kName[32], message[1024], entry[256]
	
	message[0] = 0
	new len = copy(message, 1023, "<!DOCTYPE HTML PUBLIC -//W3C//DTD HTML 4.01 Transitional//EN><html><head><meta http-equiv=Content-Type content=text/html; charset=iso-8859-1></head><body><table width=100% border=1 cellpadding=0 cellspacing=0 bgcolor=#000000><tr><td><div align=center><font color=#FFFFFF><strong>TKed You</strong></font></div></td><td><div align=center><font color=#FFFFFF><strong>X Times</strong></font></div></td></tr>")
	
	for(new k = 1; k <= maxplayers; ++k)
		{
		if(TKHistory[k][id] > 0)
			{
			get_user_name(k, kName, 31)
			formatex(entry, 255, "<tr><td><div align=center><font color=#FFFFFF>%s</font></div></td><td><div align=center><font color=#FFFFFF>%i</font></div></td></tr>", kName, TKHistory[k][id])
			len += copy(message[len], 1023 - len, entry)
		}
	}
	len += copy(message[len], 1023 - len, "</table></body></html>")
	
	show_motd(id, message, "[ATAC] Who TKed Me:")
	#endif
	return PLUGIN_HANDLED
}

public addmetk(id, level, cid)
	{
	if(!cmd_access(id, level, cid, 1))
		{
		return PLUGIN_HANDLED
	}
	TK[id][id]++
	TKHistory[id][id]++
	
	if(KickMe[id] >= get_pcvar_num(pv_atac_tk_before_ban) - 1)
		{
		MenuPage[id] = 3
		show_atac_menu(id, id)
	}
	else
		{
		MenuPage[id] = 1
		show_atac_menu(id, id)
	}
	client_print(id, 3, "Your Flags: %i", PlayerFlags[id])
	return PLUGIN_HANDLED
}
