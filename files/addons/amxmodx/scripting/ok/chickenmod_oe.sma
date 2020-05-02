/* ChickenMod: Orange Edition
*
* Copyright © 2008, ChickenMod Team
*
* This file is provided as is (no warranties).
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#define PLUGIN "ChickenMod: Orange Edition"
#define VERSION "0.6.5"
#define AUTHOR "ChickenMod Team"

#define REAL_RESET        32
#define MAX_BLOCKED       57 //60

#define HU_STAND_VIEW     17.0
#define HU_DUCK_VIEW      12.0
#define CH_STAND_VIEW    -17.0
#define CH_DUCK_VIEW      2.75

const OFFSET_MODELINDEX = 491
const OFFSET_VIP        = 209
const OFFSET_LINUX      = 5 // offsets 5 higher in Linux builds

new g_MenuPage[ 33 ]
new g_PlayerMenuPage[ 33 ]
new g_menuPlayers[ 33 ][ 32 ]
new g_menuPlayersNum[ 33 ]

new feather
new chicken[ 33 ]
new chicken_sound[ 33 ]
new chicken_theme[ 33 ]
new chicken_model[ 33 ][ 32 ]
new ChickName[ 33 ][ 32 ]
new UserOldName[ 33 ][ 32 ]
new gmsgSetFOV
new maxplayers
new bomb_id
new bool:g_RoundStarted = false
new g_ModelIndex
new g_ulModelIndexChicken
new g_ulModelIndexCT
new g_ulModelIndexT
new bool:g_ChickenTeamT = false
new bool:g_ChickenVIP = false
new bool:g_ChickenTeamCT = false
new bool:g_ChickenAll = false
new bool:g_cs_running = false
new bool:g_as_running = false

// Settings from the cfg file
new ChickenVision = 135
new Float:ChickenSpeed = 500.0
new bool:HealthProtect = false
new bool:ChickenSelf = false
new bool:ChickenName = false
new bool:ChickenTalk = false
new bool:ChickenTeamTalk = false
new bool:ChickenPlayTheme = false
new ChickenHP = 30
new bool:ChickenBomb = false
new bool:ChickenGrenades = false
new bool:ChickenGlow = false
new ChickenHealth = 255
new ChickenGravity = 50
new MenuGrv = 5
new MenuHP = 10
new MenuSpd = 40
new ACCESS_MENU = ADMIN_MENU
new ACCESS_SETTINGS = ADMIN_CFG

// set_task2 functions...
new TASKID_EXEC[ 65 ]
new TASK_FUNC_NAME[ 65 ][ 32 ]
new Float:TASK_START_TIME[ 65 ]

// cvars pointers
/*
new gCVARChickenGlow
new gCVARChickenGravity
new gCVARChickenHealth
new gCVARChickenMaxSpeed
new gCVARChickenFOV
*/

new const Blocked_Items[ MAX_BLOCKED ][] =
{
	// Commands		(10)
	"buy","buyammo1","buyammo2","cl_autobuy","cl_rebuy","cl_setautobuy","cl_setrebuy","primammo","secammo",//"buyequip",
	// Pistols		(11)
	"glock","9x19mm","usp","km45","p228","228compact","deagle","nighthawk","fn57","fiveseven","elites",
	// Shotguns (4)
	"m3","12gauge","xm1014","autoshotgun",
	// Sub Machine Guns	(9)
	"tmp","mp","mac10","mp5","smg","ump45","p90","c90","m249",
	// Rifles			(18)
	"famas","clarion","galil","defender","ak47","cv47","m4a1","scout","aug","bullpup","sg552","krieg552","sg550","krieg550","awp","magnum","g3sg1","d3au1",
	// Grenades		(3)
	"flash","sgren",//"hegren",
	// Items			(5)
	"vest","vesthelm","nvgs","shield"//,"defuser"
}

public plugin_precache()
{
	// Models
	g_ulModelIndexChicken = precache_model( "models/player/chicken/chicken.mdl" )
	g_ulModelIndexCT = precache_model( "models/player/urban/urban.mdl" )
	g_ulModelIndexT = precache_model( "models/player/terror/terror.mdl" )
	precache_model( "models/w_easterEgg.mdl" )
	precache_model( "models/w_goldenEgg.mdl" )
	feather = precache_model( "models/feather.mdl" )
	// Sounds
	precache_sound( "misc/chicken0.wav" )
	precache_sound( "misc/chicken1.wav" )
	precache_sound( "misc/chicken2.wav" )
	precache_sound( "misc/chicken3.wav" )
	precache_sound( "misc/chicken4.wav" )
	precache_sound( "misc/cow.wav" )
	precache_sound( "misc/killChicken.wav" )
	precache_sound( "misc/knife_hit1.wav" )
	precache_sound( "misc/knife_hit3.wav" )
	// Music
	precache_generic( "sound/music/ChickenMod_Theme.mp3" )
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	register_dictionary("chickenmod_oe.txt")
	g_cs_running = (cstrike_running() > 0)
	if (!g_cs_running)
	{
		log_message("%s - error: failed to load plugin (Counter-Strike Only)", PLUGIN)
		return
	}

	register_cvar("chicken_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	new config[64]
	get_configsdir(config, 63)
	format(config, 63, "%s/chicken.cfg", config)
	loadcfg(config)

	new map[32]
	get_mapname(map, 31)
	if (!contain(map, "as_"))
		g_as_running = true

	register_menucmd(register_menuid("ChickenMod OE"), 1023, "action_chickenmenu")
	register_srvcmd("c_chicken", "ClientCommand_chicken", ACCESS_MENU, "<authid, nick, #userid, @1/2/3 (1 = Terrorists, 2 = Counter-Terrorists, 3 = VIP) or * (all)>")
	register_srvcmd("c_unchicken", "ClientCommand_unchicken", ACCESS_MENU, "<authid, nick, #userid, @1/2/3 (1 = Terrorists, 2 = Counter-Terrorists, 3 = VIP) or * (all)>")
	register_clcmd("amx_chicken", "ClientCommand_chicken", ACCESS_MENU, "<authid, nick, #userid, @1/2/3 (1 = Terrorists, 2 = Counter-Terrorists, 3 = VIP) or * (all)>")
	register_clcmd("amx_unchicken", "ClientCommand_unchicken", ACCESS_MENU, "<authid, nick, #userid, @1/2/3 (1 = Terrorists, 2 = Counter-Terrorists, 3 = VIP) or * (all)>")
	register_clcmd("say /chickenmenu", "amx_chick_menu", ACCESS_MENU, "[ChickenMod OE]: User Interface")
	register_clcmd("say", "chickensay")
	register_clcmd("say_team", "chickenteamsay")
	register_clcmd("say /chickenme", "chickensay", 0, "- chicken yourself")
	register_clcmd("say /unchickenme", "chickensay", 0, "- unchicken yourself")
	register_clcmd( "nightvision", "ClientCommand_nightvision" ) // Not Used Yet

	AddMenuItem(PLUGIN, "say /chickenmenu", ACCESS_MENU, PLUGIN)

	register_menucmd( register_menuid( "BuyItem", 1 ), 511, "Item_Menu" )
	register_menucmd( -34, 511, "Item_Menu" )

	register_event( "Damage", "Event_Damage", "be", "2>0" )
	register_event( "DeathMsg", "Event_DeathMsg", "a" )
	register_event( "HLTV", "Event_NewRound", "a", "1=0", "2=0" )
	register_event( "TeamInfo", "Event_TeamInfo", "a" )
	register_event( "ResetHUD", "Event_ResetHud", "b" )

	register_logevent( "Log_Event_RoundEnd", 2, "1=Round_End" )
	register_logevent( "Log_Event_RoundStart", 2, "1=Round_Start" )

	register_forward( FM_ClientCommand, "ClientCommand" )
	register_forward( FM_ClientDisconnect, "ClientDisconnect" )
	register_forward( FM_ClientPutInServer, "ClientPutInServer" )

	register_forward( FM_CmdStart, "CmdStart" )
	register_forward( FM_EmitSound, "EmitSound" )
	register_forward( FM_PlayerPreThink, "PlayerPreThink" )

	register_forward( FM_SetAbsBox, "SetAbsBox" )

	register_forward( FM_SetClientKeyValue, "SetClientKeyValue" )
	register_forward( FM_SetModel, "SetModel" )
	register_forward( FM_Touch, "Touch" )
	register_forward( FM_TraceHull, "TraceHull_Post", 1 )
	register_forward( FM_StartFrame, "StartFrame" )

	gmsgSetFOV = get_user_msgid( "SetFOV" )
	register_message( get_user_msgid( "ClCorpse" ), "Message_ClCorpse" )
	register_message( get_user_msgid( "CurWeapon" ), "Message_CurWeapon" )
	register_message( gmsgSetFOV, "Message_SetFOV" )

	maxplayers = get_maxplayers()
	g_ChickenTeamT = false
	g_ChickenTeamCT = false
	g_ChickenVIP = false
	g_ChickenAll = false
	g_ModelIndex = OFFSET_MODELINDEX

	for (new taskid = 1; taskid < 65; taskid++)
	{
		TASKID_EXEC[taskid] = 0
		TASK_FUNC_NAME[taskid][0] = '^0'
		TASK_START_TIME[taskid] = 0.0
	}
}

public plugin_end()
{
	for (new taskid = 1; taskid < 65; taskid++)
	{
		TASKID_EXEC[taskid] = 0
		TASK_FUNC_NAME[taskid][0] = '^0'
		TASK_START_TIME[taskid] = 0.0
	}

	new user[ 33 ], ptr

	for (new id = 1; id <= maxplayers; id++)
	{
		chicken[ id ] = 0
		if (!pev_valid ( id ))
			continue
		pev(id, pev_netname, ptr, user, 32)

		if ((containi(user, "Chicken") >= 0) && (UserOldName[ id ][ 0 ] != '^0')  && !is_user_bot( id ) )
		{
			set_user_info(id, "name", UserOldName[ id ])
			UserOldName[ id ][ 0 ] = '^0'
		}
	}
}

/* Registered Menus */
/******************************************************************************/
public Item_Menu( id, key )
{
	return Check_Item_Menu( id, key )
}

Check_Item_Menu( id, key )
{
	new team = get_user_team2( id )

	if ( team != 1 && team != 2 )
		return PLUGIN_HANDLED
	
	if ( !chicken[ id ] )
		return PLUGIN_CONTINUE

	switch ( key )
	{
		// Armor, Armor+Helmet, Flash Grenade, Smoke Grenade, Nightvision, Shield
		case 0, 1, 2, 4, 5, 7:
		{
			client_print( id, print_chat, "%L", id, "CHICKEN_CANT_PURCHASE_THAT" )
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

/* Registered Forwards */
/******************************************************************************/
public ClientCommand( id )
{
	if ( !is_user_alive( id ) || !chicken[ id ] )
		return FMRES_IGNORED

	new arg[ 16 ], i
	read_argv( 0, arg, 15 )

	do
	{
		if ( equali( arg, Blocked_Items[ i ] ) )
		{
			client_print( id, print_chat, "%L", id, "CHICKEN_CANT_PURCHASE_THAT" )
			return FMRES_SUPERCEDE
		}
	}
	while ( ++i < MAX_BLOCKED )

	return FMRES_IGNORED
}

public ClientDisconnect( id )
{
	if ( chicken[ id ] )
	{
		Reset_Chicken_Model( id + REAL_RESET )
		UserOldName[ id ][ 0 ] = '^0'
		set_pdata_int( id, OFFSET_MODELINDEX, 0, OFFSET_LINUX )
	}
	update_menu()
}

public ClientPutInServer(id)
{
	update_menu()
}

public CmdStart( const id, const uc_handle, random_seed )
{
	if ( !is_user_alive( id ) || !chicken[ id ] )
		return FMRES_IGNORED
	
	static buttons; buttons = get_uc( uc_handle, UC_Buttons )
	// Don't allow Chickens to use Secondary Attack!
	if ( buttons & IN_ATTACK2 )
	{
		buttons &= ~IN_ATTACK2
		set_uc( uc_handle, UC_Buttons, buttons )
	}
	return FMRES_IGNORED
}

public EmitSound( entity, channel, const sample[], Float:volume, Float:attenuation, fFlags, pitch )
{
	if ( !pev_valid( entity ) || entity > maxplayers )
		return FMRES_IGNORED

	//server_print( "Entity: %i - Sound: %s", entity, sample )
	if ( chicken[ entity ] )
	{
		// Items we don't want emitted from chickens
		if ( contain( sample, "items" ) != -1 || equal( sample, "common/bodysplat.wav" ) || equal( sample, "common/wpn_denyselect.wav" ) )
			return FMRES_SUPERCEDE

		// Make a funny chicken noise instead of knifing sound :)
		if ( contain( sample, "knife_slash" ) != -1 || contain( sample, "knife_hitw" ) != -1 )
		{
			if ( !chicken_sound[ entity ] )
			{
				static iPitch; iPitch = random_num( 100, 120 )
				switch ( random_num( 0, 3 ) )
				{
					case 0: emit_sound( entity, CHAN_VOICE, "misc/chicken1.wav", 1.0, ATTN_NORM, 0, iPitch )
					case 1: emit_sound( entity, CHAN_VOICE, "misc/chicken2.wav", 1.0, ATTN_NORM, 0, iPitch )
					case 2: emit_sound( entity, CHAN_VOICE, "misc/chicken3.wav", 1.0, ATTN_NORM, 0, iPitch )
					case 3: emit_sound( entity, CHAN_VOICE, "misc/chicken4.wav", 1.0, ATTN_NORM, 0, iPitch )
				}
				chicken_sound[ entity ] = 1
				set_task( 0.8, "Reset_Chicken_Sound", entity )
			}
			return FMRES_SUPERCEDE
		}
		// Change knife hit to something which sounds chicken like :)
		if ( contain( sample, "knife_hit" ) != -1 )
		{
			switch ( random_num( 0, 1 ) )
			{
				case 0: emit_sound( entity, CHAN_WEAPON, "weapons/knife_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
				case 1: emit_sound( entity, CHAN_WEAPON, "weapons/knife_hit3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
			}

			return FMRES_SUPERCEDE
		}
		// Block all other knifing sounds */
		if ( contain( sample, "knife" ) != -1 || contain( sample, "bhit" ) != -1 )
			return FMRES_SUPERCEDE

		// Change all killing sounds to killChicken
		if ( contain( sample, "player/d" ) != -1 )
		{
			emit_sound( entity, CHAN_VOICE, "misc/killChicken.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public PlayerPreThink( id )
{
	if ( !is_user_alive( id ) || !chicken[ id ] )
		return FMRES_IGNORED

	static flTimeStepSound; flTimeStepSound = pev( id, pev_flTimeStepSound )
	static flags; flags = pev( id, pev_flags )

	if ( flags & FL_DUCKING )
		set_pev( id, pev_view_ofs, Float:{0.0, 0.0, CH_DUCK_VIEW} )
	else
		set_pev( id, pev_view_ofs, Float:{0.0, 0.0, CH_STAND_VIEW} )

	if ( flTimeStepSound > 100 )
		set_pev( id, pev_flTimeStepSound, 100 )

	return FMRES_IGNORED
}

public SetAbsBox( id )
{
	if ( !is_user_connected( id ) )
		return FMRES_IGNORED

	static flags
	flags = pev( id, pev_flags )

	if ( chicken[ id ] )
	{
		if ( flags & FL_DUCKING ) // do we need differenet box sizes for ducking and standing chickens? Actually I (KWo) made them the same...
		{
			set_pev( id, pev_mins, Float:{-7.0, -7.0, -28.0} )
			set_pev( id, pev_maxs, Float:{7.0, 7.0, -12.0} )
			set_pev( id, pev_size, Float:{14.0, 14.0, 16.0} )
		}
		else
		{
			set_pev( id, pev_mins, Float:{-7.0, -7.0, -28.0} )
			set_pev( id, pev_maxs, Float:{7.0, 7.0, -12.0} )
			set_pev( id, pev_size, Float:{14.0, 14.0, 16.0} )
		}
	}
	else
	{
		if ( flags & FL_DUCKING )
		{
			set_pev( id, pev_mins, Float:{-16.0, -16.0, -18.0} )
			set_pev( id, pev_maxs, Float:{16.0, 16.0, 32.0} )
			set_pev( id, pev_size, Float:{32.0, 32.0, 50.0} )
		}
		else
		{
			set_pev( id, pev_mins, Float:{-16.0, -16.0, -36.0} )
			set_pev( id, pev_maxs, Float:{16.0, 16.0, 36.0} )
			set_pev( id, pev_size, Float:{32.0, 32.0, 72.0} )
		}
	}
	return FMRES_IGNORED
}

public SetClientKeyValue( id, infobuffer[], key[], value[] )
{
	if ( !is_user_alive( id ) || !chicken[ id ] || !equal( key, "model" ) )
		return FMRES_IGNORED

	if ( !equal( value, chicken_model[ id ] ) && ( chicken_model[ id ][ 0 ] != '^0' ) )
	{
		set_user_info( id, "model", chicken_model[ id ] )
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public SetInfoModel( taskid )
{
	static id
	id = taskid - 64
	if ( is_user_connected( id ) )
	{
		if ( is_user_alive( id ) )
		{
			set_user_info( id, "model", chicken_model[ id ] )
		}
	}
}

public SetModel( entity, const model[] )
{
	if ( !pev_valid( entity ) )
		return FMRES_IGNORED

	if ( equali( model, "models/w_c4.mdl" ) && chicken[ bomb_id ] )
	{
		engfunc( EngFunc_SetModel, entity, "models/w_goldenEgg.mdl" )
		return FMRES_SUPERCEDE
	}

	static id
	id = pev( entity, pev_owner )

	if ( !is_user_connected( id ) )
		return FMRES_IGNORED

	if ( equali( model, "models/w_hegrenade.mdl" ) && chicken[ id ] )
	{
		static Float:origin[ 3 ]
		pev( id, pev_origin, origin )
		engfunc( EngFunc_SetModel, entity, "models/w_easterEgg.mdl" )
		set_pev( entity, pev_velocity, Float:{ 0.0, 0.0, 0.0 } )
		engfunc( EngFunc_SetOrigin, entity, origin )
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public Touch( touched, other )
{
	if ( !pev_valid( touched ) || !pev_valid( other ) || !is_user_alive( other ) )
		return FMRES_IGNORED

	static class[ 32 ], model[ 32 ]
	pev( touched, pev_classname, class, 31 )
	pev( touched, pev_model, model, 31)

	if ( chicken[ other ] && ( equali( class, "weaponbox" ) || equali( class, "weapon_shield" ) ) && !equali( model, "models/w_backpack.mdl" ) )
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public TraceHull_Post( const Float:v1[ 3 ], const Float:v2[ 3 ], fNoMonsters, hullNumber, id, const tr_handle )
{
	if ( !is_user_alive( id ) )
		return FMRES_IGNORED
	
	static victim; victim = get_tr2( tr_handle, TR_pHit )

	if ( !is_user_alive( victim ) )
		return FMRES_IGNORED

	// Hitgroup only returns 0 ???
	// Changing flFraction forces the engine to use TraceLine it seems :)
	if ( chicken[ victim ] )
		set_tr2( tr_handle, TR_flFraction, 1.0 )

	return FMRES_IGNORED
}

/* Registered Log Events */
/******************************************************************************/
public Log_Event_RoundEnd()
{
	g_RoundStarted = false
}

public Log_Event_RoundStart()
{
	g_RoundStarted = true
	set_task( 0.5, "Set_Chicken_Speed", 0 )
}

/* Registered Events */
/******************************************************************************/
public Event_Damage( id )
{
	if ((id) && (id <= maxplayers))
	{
		if ( chicken[ id ] )
		{
			static origin[ 3 ]
			get_user_origin( id, origin )
			Spawn_Chicken_Feathers( id, origin, 5, 10, 5 )
		}
	}
}

public Event_DeathMsg()
{
	new id = read_data( 2 )
	new taskid
	if ((id) && (id <= maxplayers))
	{
		if ( task_exists ( id ) )
			remove_task ( id )
		if ( task_exists ( id ) )
			remove_task ( id )

		TASKID_EXEC[id] = 0
		TASK_FUNC_NAME[id][0] = '^0'
		TASK_START_TIME[id] = 0.0

		taskid = id + REAL_RESET
		if ( task_exists ( taskid ) )
			remove_task ( taskid )
		if ( task_exists ( taskid ) )
			remove_task ( taskid )

		TASKID_EXEC[taskid] = 0
		TASK_FUNC_NAME[taskid][0] = '^0'
		TASK_START_TIME[taskid] = 0.0

		if ( chicken[ id ] )
		{
			Set_Chicken_Timer( id, 1 )
		}
	}
}

public Event_NewRound()
{
	g_RoundStarted = false
}

public Event_TeamInfo()
{
	static id; id = read_data( 1 )
	if ( !is_user_alive( id ) )
		return PLUGIN_CONTINUE
	
	static team_name[ 2 ]; read_data( 2, team_name, 1 )
	switch ( team_name[ 0 ] )
	{
		case 'T':
		{
			if ( !chicken[ id ] && ( g_ChickenTeamT || g_ChickenAll ) )
				Set_Chicken_Timer( id )
		}
		case 'C':
		{
			if ( !chicken[ id ] && ( g_ChickenTeamCT || g_ChickenAll ) )
				Set_Chicken_Timer( id )
		}
	}
	return PLUGIN_CONTINUE
}

public Event_ResetHud( id )
{
	new team, taskid
	new Float: TaskDelay
	if ( id )
	{
		if ( task_exists ( id ) )
			remove_task (id)
		if ( task_exists ( id ) )
			remove_task (id)

		TASKID_EXEC[id] = 0
		TASK_FUNC_NAME[id][0] = '^0'
		TASK_START_TIME[id] = 0.0

		taskid = id + REAL_RESET
		if ( task_exists ( taskid ) )
			remove_task ( taskid )
		if ( task_exists ( taskid ) )
			remove_task ( taskid )

		TASKID_EXEC[taskid] = 0
		TASK_FUNC_NAME[taskid][0] = '^0'
		TASK_START_TIME[taskid] = 0.0

		taskid = id + 64
		if ( task_exists ( taskid ) )
			remove_task ( taskid )

		taskid = id + 96
		if ( task_exists ( taskid ) )
			remove_task ( taskid )

		team = get_user_team2( id )
		if ( (is_user_alive( id )) 
			&& (( chicken[ id ] ) || ( g_ChickenAll )
					|| (( team == 1 ) && ( g_ChickenTeamT ))
					|| (( team == 2 ) && ( g_ChickenTeamCT )) 
					|| (( is_user_vip( id )) && ( g_ChickenVIP ))))
		{
			Set_Chicken_Timer( id )
		}
		else if (is_user_alive( id ))
		{
			TaskDelay = 0.1 + id * 0.02
			set_task( TaskDelay, "Set_Chicken_Name", id + 96 )
		}
	}
}

public Event_TextMsg()
{
	return PLUGIN_HANDLED
}

/* Registered Messages */
/******************************************************************************/
public Message_ClCorpse( msg_id, msg_dest, id )
{
	new id = get_msg_arg_int( 12 )
	
	if ( chicken[ id ] )
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public Message_CurWeapon( msg_id, msg_dest, id )
{
	static weapon_id, weapon_active, weapon_name[ 32 ], viewmodel[ 32 ]
	weapon_active = get_msg_arg_int( 1 )
	weapon_id = get_msg_arg_int( 2 )

	if ( weapon_id == CSW_C4 )
		bomb_id = id

	if (!id || ( id > maxplayers ))
		return PLUGIN_CONTINUE

	if ( !is_user_alive( id ) || !chicken[ id ] || !weapon_active || !weapon_id )
		return PLUGIN_CONTINUE

	pev( id, pev_viewmodel, viewmodel, 31 )

	if ( contain( viewmodel, "models/shield/v_shield_" ) != -1 )
	{
		if (!task_exists (id))
		{
			set_task ( 0.1, "drop_delayed", id )
		}
	}
	else if ( (weapon_id != CSW_KNIFE) && (weapon_id != CSW_HEGRENADE) && (weapon_id != CSW_C4) )
	{
		if ( is_user_vip( id ) || (weapon_id == CSW_FLASHBANG) || (weapon_id == CSW_SMOKEGRENADE) )
		{} // do nothing
		else if (!task_exists (id))
		{
			get_weaponname( weapon_id, weapon_name, 31 )
			set_task ( 0.1, "drop_delayed", id)
		}
//		engclient_cmd( id, "weapon_knife" )

		// Hud Correction
		set_msg_arg_int( 2, ARG_BYTE, 29 )
		set_msg_arg_int( 3, ARG_BYTE, -1 )
	}

	Hide_Weapons( id )
	if ( g_RoundStarted )
		Set_Chicken_Speed( id )

	return PLUGIN_CONTINUE
}

public drop_delayed (id)
{
	new weapon_id, viewmodel[ 32 ], weapon_name[ 32 ]

	if (id && ( id <= maxplayers ))
	{
		if ( is_user_alive( id ) && chicken[ id ] )
		{
			weapon_id = get_user_weapon (id)
			if (weapon_id )
			{
				pev( id, pev_viewmodel, viewmodel, 31 )

				if ( contain( viewmodel, "models/shield/v_shield_" ) != -1 )
				{
					engclient_cmd( id, "drop" )
//					engclient_cmd( id, "weapon_knife" )
				}
				else if ( (weapon_id != CSW_KNIFE) && (weapon_id != CSW_HEGRENADE) && (weapon_id != CSW_C4) )
				{
					if ( is_user_vip( id ) || (weapon_id == CSW_FLASHBANG) || (weapon_id == CSW_SMOKEGRENADE) )
					{} // do nothing
					else
					{
						get_weaponname( weapon_id, weapon_name, 31 )
						engclient_cmd( id, "drop", weapon_name )
					}
//					engclient_cmd( id, "weapon_knife" )

				}
			}
			Hide_Weapons( id )
			if ( g_RoundStarted )
				Set_Chicken_Speed( id )
		}
	}			
}

public Message_SetFOV( msg_id, msg_dest, id )
{
	if ( !is_user_alive( id ) || !chicken[ id ] )
		return PLUGIN_CONTINUE

	static fov
	fov = get_msg_arg_int( 1 )

	if ( fov != ChickenVision )
		set_msg_arg_int( 1, ARG_BYTE, ChickenVision )

	return PLUGIN_CONTINUE
}

/* Registered Client/Server Commands */
/******************************************************************************/
// chicken a player/players
public ClientCommand_chicken( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED

	new arg1[ 32 ]
	read_argv( 1, arg1, 31 )
	new id1

	switch ( arg1[ 0 ] )
	{
		case '@':
		{
			new team = str_to_num(arg1[1])

			switch ( team )
			{
				case 1:
				{
					if ( !g_ChickenTeamT )
					{
						g_ChickenTeamT = true
						if (g_ChickenTeamCT)
							g_ChickenAll = true

						set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
						show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_T_TRANSF_INTO_CHICKENS")

						for ( id1 = 1; id1 <= maxplayers; id1++ )
						{
							if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 1 ) || chicken[ id1 ] )
								continue

							Set_Chicken_Timer( id1 )
						}
						return PLUGIN_HANDLED
					}
					else
					{
						console_print(id, "%L", id, "TEAM_T_ALREADY_CHICKENS")
					}
				}
				case 2:
				{
					if ( !g_ChickenTeamCT )
					{
						g_ChickenTeamCT = true
						if (g_ChickenTeamT)
							g_ChickenAll = true

						set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
						show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_CT_TRANSF_INTO_CHICKENS")
						for ( id1 = 1; id1 <= maxplayers; id1++ )
						{
							if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 2 ) || chicken[ id1 ] )
								continue

							Set_Chicken_Timer( id1 )
						}
						return PLUGIN_HANDLED
					}
					else
					{
						console_print(id, "%L", id, "TEAM_CT_ALREADY_CHICKENS")
					}
				}
				case 3:
				{
					if ( !g_ChickenVIP )
					{
						if ( g_as_running )
						{
							g_ChickenVIP = true

							// finding the VIP should be optimized (at round start or somewhere else)
							for ( id1 = 1; id1 <= maxplayers; id1++ )
							{
								if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 2 ) || chicken[ id1 ] )
									continue
								if (!is_user_vip( id1 ))
									continue

								Set_Chicken_Timer( id1 )
								break
							}
						}
						return PLUGIN_HANDLED
					}
					else 
					{
						console_print(id, "%L", id, "VIP_ALREADY_CHICKEN")
					}
				}
				default:
				{
					console_print(id, g_as_running ? ("%L", id, "USAGE_CH_WITH_VIP") : ("%L", id, "USAGE_CH_WITHOUT_VIP"))
				}
			}
			return PLUGIN_HANDLED
		}

		case '*':
		{
			if ((!g_ChickenAll) && !((g_ChickenTeamCT) && (g_ChickenTeamT)))
			{
				g_ChickenAll = true
				g_ChickenTeamCT = true
				g_ChickenTeamT = true
				set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
				show_hudmessage(0, "%L", LANG_PLAYER, "EVERY1_TRANSF_INTO_CHICKENS")
				for ( id1 = 1; id1 <= maxplayers; id1++ )
				{
					if ( !is_user_connected( id1 ) || !get_user_team2( id1 ) || chicken[ id1 ] )
						continue

					Set_Chicken_Timer( id1 )
				}
			}
			else
			{
				console_print(id, "%L", id, "EVERY1_ALREADY_CHICKENS")
			}
			return PLUGIN_HANDLED
		}

		default:
		{
			new user[ 32 ], player = cmd_target( id, arg1, 0 )
			get_user_name( player, user, 31 )
			new team = get_user_team2( player )
			new team1
			new CTnum, Tnum
			new bool:TeamTChickens = true
			new bool:TeamCTChickens = true

			if ( !player || !team )
				return PLUGIN_HANDLED

			if ((player == id) && is_user_alive( id ) && (get_user_health( player ) <= ChickenHP))
			{
				client_print(id, 3, "%L", id, "CANT_TURN_CHICKEN_LOW_HEALTH")
				return PLUGIN_HANDLED
			}
			if ((player == id) && !(ChickenSelf))
				return PLUGIN_HANDLED

			if (!chicken[ player ])
			{
				set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
				show_hudmessage(0, "%L", LANG_PLAYER, "PL_TRANSF_INTO_CHICKEN", user)

				// now is the part to update state of Team Menu (we need more than 2 people in each team - otherwise that function wouldn't have any sense)
				CTnum = 0
				Tnum = 0
				for ( id1 = 1; id1 <= maxplayers; id1++ )
				{
					team1 = get_user_team2( id1 )
					switch( team1 )
					{
						case 1:
						{
							Tnum++
							if (( player != id1 ) && !chicken [ id1 ] )
								TeamTChickens = false // at least one of Ts is not a chicken
						}
						case 2:
						{
							CTnum++
							if (( player != id1 ) && !chicken [ id1 ] )
								TeamCTChickens = false // at least one of CTs is not a chicken
						}
					}
				}

				if (( Tnum > 2 ) && ( TeamTChickens )) // that means - everybody in T team is already a chicken (to show and handle better in menu)
					g_ChickenTeamT = true
				if (( CTnum > 2 ) && ( TeamCTChickens )) // that means - everybody in CT team is already a chicken (to show and handle better in menu)
					g_ChickenTeamCT = true
				if (g_ChickenTeamT && g_ChickenTeamCT) // that means - everybody are already chickens (to show and handle better in menu)
					g_ChickenAll = true

				Set_Chicken_Timer( player )
				chicken[ player ] = 2 // player got punished or marked by an admin to be a chicken - no matter which team (to prevent unchicken by him-self :)
			}
			else
			{
				console_print(id, "%L", id, "PL_ALREADY_CHICKEN", user)
			}
		}
	}
	return PLUGIN_HANDLED
}

// unchicken a player/players
public ClientCommand_unchicken( id, level, cid )
{
	if ( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED

	new arg1[ 32 ]
	read_argv( 1, arg1, 31 )
	new id1

	switch ( arg1[ 0 ] )
	{
		case '@':
		{
			new team = str_to_num(arg1[1])

			switch ( team )
			{
				case 1:
				{
					if ( g_ChickenTeamT || g_ChickenAll )
					{
						if (g_ChickenAll)
							g_ChickenTeamCT = true
						g_ChickenTeamT = false
						g_ChickenAll = false

						set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
						show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_T_REST_INTO_HUMANS")

						for ( id1 = 1; id1 <= maxplayers; id1++ )
						{
							if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 1 ) || !chicken[ id1 ])
								continue

							Set_Chicken_Timer( id1, 1, 1 )
						}
						return PLUGIN_HANDLED
					}
					else if ( !g_ChickenTeamT )
					{
						console_print(id, "%L", id, "TEAM_T_ALREADY_HUMANS")
					}
				}
				case 2:
				{
					if ( g_ChickenTeamCT || g_ChickenAll )
					{
						if (g_ChickenAll)
							g_ChickenTeamT = true
						g_ChickenTeamCT = false
						g_ChickenAll = false

						set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
						show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_CT_REST_INTO_HUMANS")
						for ( id1 = 1; id1 <= maxplayers; id1++ )
						{
							if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 2 ) || !chicken[ id1 ])
								continue

							Set_Chicken_Timer( id1, 1, 1 )
						}
						return PLUGIN_HANDLED
					}
					else if ( !g_ChickenTeamCT )
					{
						console_print(id, "%L", id, "TEAM_CT_ALREADY_HUMANS")
					}
				}
				case 3:
				{
					if ( g_ChickenVIP )
					{
						if ( g_as_running )
						{
							g_ChickenVIP = false

							// finding the VIP should be optimized (at round start or somewhere else)
							for ( id1 = 1; id1 <= maxplayers; id1++ )
							{
								if ( !is_user_connected( id1 ) || (get_user_team2( id1 ) != 2 ) || !chicken[ id1 ])
									continue
								if (!is_user_vip( id1 ))
									continue

								Set_Chicken_Timer( id1, 1, 1 )
								break
							}
						}
						return PLUGIN_HANDLED
					}
					else
					{
						console_print(id, "%L", id, "VIP_ALREADY_HUMAN")
					}
				}
				default:
				{
					console_print(id, g_cs_running ? ("%L", id, "USAGE_UNCH_WITH_VIP") : ("%L", id, "USAGE_UNCH_WITHOUT_VIP"))
				}
			}
			return PLUGIN_HANDLED
		}

		case '*':
		{
			g_ChickenAll = false
			g_ChickenTeamT = false
			g_ChickenTeamCT = false
			new restoring = false
			for ( id1 = 1; id1 <= maxplayers; id1++ )
			{
				if ( !is_user_connected( id1 ) || !get_user_team2( id1 ) || !chicken[ id1 ] )
					continue

				restoring = true

				Set_Chicken_Timer( id1, 1, 1 )
			}
			if (restoring)
			{
				set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
				show_hudmessage(0, "%L", LANG_PLAYER, "EVERY1_REST_INTO_HUMANS")
			}
			else
			{
				console_print(id, "%L", id, "EVERY1_ALREADY_HUMANS")
			}
			return PLUGIN_HANDLED
		}

		default:
		{
			new user[ 32 ], player = cmd_target( id, arg1, 0 )
			new team = get_user_team2( player )
			if ( !player || !team )
				return PLUGIN_HANDLED

			get_user_name( player, user, 31 )
			if (chicken[ player ])
			{
				g_ChickenAll = false
				if (team == 1)
					g_ChickenTeamT = false
				else if (team == 2)
					g_ChickenTeamCT = false

				Set_Chicken_Timer( player, 1, 1 )

				set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
				show_hudmessage(0, "%L", LANG_PLAYER, "PL_RESTORED_INTO_HUMAN", user)
			}
			else
			{
				console_print(id, "%L", id, "PL_ALREADY_HUMAN", user)
			}
		}
	}
	return PLUGIN_HANDLED
}

/******************************************************************************/
// Does nothing at the moment
public ClientCommand_nightvision( id )
{
	if ( is_user_alive( id ) && chicken[ id ] )
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

/* Registered Tasks */
/******************************************************************************/
public Reset_Chicken_Sound( id )
{
	chicken_sound[ id ] = 0
}

public Reset_Chicken_Model( id )
{
	if ( id > maxplayers )
	{
		id -= REAL_RESET

		if (( id > maxplayers ) || !id )
			return

		if ( chicken [ id ] )
		{
			if ( is_user_alive ( id ) )
			{
//				engclient_cmd( id, "weapon_knife" )
				Show_Weapons( id )
//				if ( !is_user_bot( id ) )
//					client_cmd( id, "mp3 play stopsound" )
			}
		}

		new flags
		new Float: TaskDelay

		if ( pev_valid( id ) )
		{
			flags = pev( id, pev_flags )
			if ( flags & FL_DUCKING )
				set_pev( id, pev_view_ofs, Float:{0.0, 0.0, HU_DUCK_VIEW} )
			else
				set_pev( id, pev_view_ofs, Float:{0.0, 0.0, HU_STAND_VIEW} )
		}

		chicken[ id ] = 0

		Set_Chicken_Glowing( id )
		Set_Chicken_Gravity( id )
		Set_Chicken_Health( id )
		Set_Chicken_Speed ( id )
		Set_Chicken_Vision( id )

		SetAbsBox ( id )

		if ( is_user_alive ( id ) )
		{
			TaskDelay = 0.5 + id * 0.02
			set_task( TaskDelay, "Set_Chicken_Name", id + 96 )
			Transform_Chicken( id )
		}

		chicken_sound[ id ] = 0
		chicken_theme[ id ] = 0

		new team = get_user_team2( id )
		switch ( team )
		{
			case 1: set_pdata_int( id, g_ModelIndex, g_ulModelIndexT, OFFSET_LINUX )
			case 2: set_pdata_int( id, g_ModelIndex, g_ulModelIndexCT, OFFSET_LINUX )
			default: set_pdata_int( id, g_ModelIndex, 0, OFFSET_LINUX )
		}
	}
	else
	{
		set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FROZEN )
		set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW )
		set_pev( id, pev_solid, SOLID_NOT )
		set_pev( id, pev_takedamage, DAMAGE_NO )
		if ((is_user_connected ( id )) &&  (!is_user_alive ( id )  ))
		{
			new origin[ 3 ]
			get_user_origin( id, origin )
			Spawn_Chicken_Feathers( id, origin, 5, 30, 30 )
		}
	}
	chicken_model[ id ][ 0 ] = '^0'
	dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) )
}

public Set_Chicken_Model( id )
{
	if ( !is_user_connected ( id ) || !is_user_alive( id ) )
		return

	new model_name[ 32 ]
	// Update Hitboxes (ServerSide)
	set_pdata_int( id, g_ModelIndex, g_ulModelIndexChicken, OFFSET_LINUX )
/*
	if (( ChickenPlayTheme ) && ( !is_user_bot( id ) ) && is_user_alive( id ) && ( !chicken_theme[ id ] ))
	{
		client_cmd( id, "mp3 play ^"sound/music/ChickenMod_Theme.mp3^"" )
		chicken_theme[ id ] = 1
	}
*/
	if ( chicken[ id ] != 2 )
		chicken[ id ] = 1

	get_user_info( id, "model", model_name, 31 )
	if (!equal( model_name, "chicken") )
	{
		formatex( chicken_model[ id ], 31, "chicken" )
		set_user_info( id, "model", chicken_model[ id ] )
	}

	Set_Chicken_Glowing( id )
	Set_Chicken_Gravity( id )
	Set_Chicken_Health( id )
	Set_Chicken_Speed ( id )
	Set_Chicken_Vision( id )
	new Float: TaskDelay = 0.5 + id * 0.02
	set_task( TaskDelay, "Set_Chicken_Name", id + 96)
	Set_Chicken_Weapon( id, "item_longjump" )

	SetAbsBox ( id )

	if (is_user_alive( id ))
	{
		Transform_Chicken( id )
		has_user_shield( id )
//		engclient_cmd( id, "weapon_knife" )
		Hide_Weapons( id )
	}
}

/* Misc Functions */
/******************************************************************************/
public Set_Chicken_Speed( id )
{
	if ( g_RoundStarted )
	{
		if (( id ) && is_user_connected( id ))
		{
			if ( chicken[ id ] )
				set_pev( id, pev_maxspeed, ChickenSpeed )
			else
				set_pev(id, pev_maxspeed, 240.0)
		}
		else if (id == 0)
		{
			for (new id1 = 1; id1 <= maxplayers; id1++)
			{
				if (is_user_connected( id1 ) && (chicken[ id1 ]))
				{
					set_pev( id1, pev_maxspeed, ChickenSpeed )
				}
			}
		}
	}
}

Set_Chicken_Vision( id )
{
	new Float: TaskDelay
	if (( id ) && is_user_connected( id ))
	{
		message_begin( MSG_ONE, gmsgSetFOV, _, id )
		write_byte( (chicken[ id ] && is_user_alive( id ) ) ? ChickenVision : 90 )
		message_end()
		if ( is_user_bot (id ) )
			set_pev( id, pev_fov, chicken[ id ] ? float(ChickenVision) : 90.0 )
	}
	else if (id == 0)
	{
		for (new id1 = 1; id1 <= maxplayers; id1++)
		{
			if (is_user_connected( id1 ) && (chicken[ id1 ]))
			{
				TaskDelay = 0.5 + id1 * 0.02
				set_task( TaskDelay, "Set_Chicken_Vision", id1 )
			}
		}
	}
}

Set_Chicken_Glowing( id )
{
	if ( ( id ) && is_user_connected( id ) )
	{
 		if ( chicken [ id ] && (ChickenGlow) )
		{
			set_player_rendering(id, kRenderFxGlowShell, (get_user_team2(id) == 1) ? 250 : 0, 0, (get_user_team2(id) == 2) ? 250 : 0, kRenderTransAlpha, 255 , 1)
		}
		else
		{
			set_player_rendering( id, kRenderFxNone, 255, 255, 255, kRenderNormal, 16, 0 )
		}
	}
	else if ( id  == 0 )
	{
		for (new id1 = 1; id1 <= maxplayers; id1++)
		{
			if ( is_user_connected( id1 ) )
			{
				if ( (chicken [ id1 ]) && (ChickenGlow) )
					set_player_rendering( id1, kRenderFxGlowShell, (get_user_team2(id1) == 1) ? 250 : 0, 0, (get_user_team2(id1) == 2) ? 250 : 0, kRenderTransAlpha, 255 , 1 )
				else
					set_player_rendering( id1, kRenderFxNone, 255, 255, 255, kRenderNormal, 16, 0 )
			}
		}
	}
}

Set_Chicken_Gravity( id )
{
	if (( id ) && is_user_connected( id ))
	{
		if ( chicken[ id ] )
			set_pev(id, pev_gravity, float(ChickenGravity) / 100.0)	
		else
			set_pev(id, pev_gravity, 1.0)
	}
	else if (id == 0)
	{
		for (new id1 = 1; id1 <= maxplayers; id1++)
		{
			if ((chicken [ id1 ]) && is_user_connected( id1 ))
				set_pev(id1, pev_gravity, float(ChickenGravity) / 100.0)	
		}
	}
}

Set_Chicken_Health( id )
{
	static Float:Health
	static Float:MaxHealth

	if ( !pev_valid (id) )
		return

	if ( !is_user_alive ( id ) )
		return

	pev( id, pev_health, Health )
	pev( id, pev_max_health, MaxHealth )

	if ( !chicken[ id ] )
	{
		Health = MaxHealth * (Health / (float(ChickenHealth)))
		if (Health < 1.0)
			Health = 1.0
		if ( Health > MaxHealth )
			Health = MaxHealth
		set_pev(id, pev_health, Health)
	}
	else
		set_pev(id, pev_health, ( Health * float(ChickenHealth)) / MaxHealth )
}

public Set_Chicken_Name( id )
{
	if ( id > maxplayers )
		id -= 96

	if ( id > maxplayers )
		return

	if (!is_user_connected( id ))
		return

	new user[33]
	get_user_name(id, user, 32)

	if ((ChickenName) && chicken[ id ])
	{
		if (containi(user, "Chicken") == -1)
		{
			copy(UserOldName[ id ], 32, user)
			format(ChickName[ id ], 32, "Chicken #%i", id)
			if (is_user_alive( id ))
			{
				set_user_info(id, "name", ChickName[id])
				if (task_exists(667788))
					remove_task(667788)
				set_task(0.3, "update_menu",667788)
			}
		}
	}
	else
	{
		if ((containi(user, "Chicken") >= 0) && (UserOldName[ id ][ 0 ] != '^0'))
		{
			if (is_user_alive( id ))
			{
				set_user_info(id, "name", UserOldName[id])
				UserOldName[ id ][ 0 ] = '^0'
				if (task_exists(667788))
					remove_task(667788)
				set_task(0.3, "update_menu",667788)
			}
		}
	}
}

Set_Chicken_Timer( id, reset = 0, real = 0 )
{
	static Float: TaskDelay
	TaskDelay = 0.1 + id * 0.02
	set_task2( TaskDelay, reset ? "Reset_Chicken_Model" : "Set_Chicken_Model", real ? id + REAL_RESET : id )
}

Show_Weapons( id )
{
	set_pev( id, pev_viewmodel2, "models/v_knife.mdl" )
	set_pev( id, pev_weaponmodel2, "models/p_knife.mdl" )
}

Hide_Weapons( id )
{
	set_pev( id, pev_viewmodel, 0 )
	set_pev( id, pev_weaponmodel, 0 )
}

Set_Chicken_Weapon( id, const item_name[] )
{
	new item = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, item_name ) )
	
	if ( item )
	{
		new Float:origin[ 3 ]
		pev( id, pev_origin, origin )

		set_pev( item, pev_origin, origin )
		set_pev( item, pev_spawnflags, pev( item, pev_spawnflags ) & (1<<30) )
		dllfunc( DLLFunc_Spawn, item )

		new solid = pev( item, pev_solid )
		dllfunc( DLLFunc_Touch, item, id )
		if ( pev( item, pev_solid ) == solid )
			engfunc( EngFunc_RemoveEntity,  item )
	}
}

Spawn_Chicken_Feathers( id, origin[ 3 ], velocity, random, amount )
{
	static Float:size[ 3 ]
	pev( id, pev_size, size )

	message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
	write_byte( TE_BREAKMODEL )
	// position
	write_coord( origin[ 0 ] )
	write_coord( origin[ 1 ] )
	write_coord( origin[ 2 ] )
	// size
	engfunc( EngFunc_WriteCoord, size[ 0 ] )
	engfunc( EngFunc_WriteCoord, size[ 1 ] )
	engfunc( EngFunc_WriteCoord, size[ 2 ] )
	// velocity
	write_coord( 0 )
	write_coord( 0 )
	write_coord( velocity )
	// randomization
	write_byte( random )
	// Model
	write_short( feather )
	// # of shards
	write_byte( amount )
	// duration
	write_byte( 300 )
	// flags
	write_byte( 0x04 ) // BREAK_FLESH
	message_end()
}

Transform_Chicken( id )
{
	static origin[ 3 ]
	get_user_origin( id, origin )

	message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
	write_byte( TE_TELEPORT )
	write_coord( origin[ 0 ] )
	write_coord( origin[ 1 ] )
	write_coord( origin[ 2 ] )
	message_end()
}

get_user_team2( id )
{
	static team_name[ 2 ]

	if ((id < 0) || (id > maxplayers))
		return 0

	if (!is_user_connected( id ))
		return 0

	get_user_team( id, team_name, 1 )
	
	switch ( team_name[ 0 ] )
	{
		case 'T': return 1
		case 'C': return 2
	}

	return 0
}

is_user_vip( id )
{
	if ( get_pdata_int( id, OFFSET_VIP, OFFSET_LINUX ) & (1<<8) )
		return 1

	return 0
}

has_user_shield( id )
{
	static viewmodel[ 32 ]
	pev( id, pev_viewmodel, viewmodel, 31 )

	if ( contain( viewmodel, "models/shield/v_shield_" ) != -1 )
	{
		engclient_cmd( id, "drop" )
		return 1
	}
	return 0
}

//----------------------------------------------------------------------------------------------
/* LOAD/READ CONFIG CODE */
loadcfg(filename[])
{
	if (file_exists(filename))
	{
		new readdata[128], set[30], val[30], len
		for(new i = 0; i < 100 && read_file(filename, i, readdata, 127, len); ++i)
		{
			parse(readdata, set, 29, val, 29)
			
			if (equal(set, "ChickenVision"))
			{
				ChickenVision = str_to_num(val)
			}
			else if (equal(set, "HealthProtect"))
			{
				if (!equal(val, "0"))
				{
					HealthProtect = true
				}
			}
			else if (equal(set, "ChickenName"))
			{
				if (!equal(val, "0"))
				{
					ChickenName = true
				}
			}
			else if (equal(set, "ChickenSelf"))
			{
				if (!equal(val, "0"))
				{
					ChickenSelf = true
				}
			}
			else if (equal(set, "ChickenHP"))
			{
				ChickenHP = str_to_num(val)
			}
			else if (equal(set, "ChickenTalk"))
			{
				if (!equal(val, "0"))
				{
					ChickenTalk = true
				}
			}
			else if (equal(set, "ChickenTeamTalk"))
			{
				if (!equal(val, "0"))
				{
					ChickenTeamTalk = true
				}
			}
			else if (equal(set, "ChickenPlayTheme"))
			{
				if (!equal(val, "0"))
				{
					ChickenPlayTheme = true
				}
			}
			else if (equal(set, "ChickenBomb"))
			{
				if (!equal(val, "0"))
				{
					ChickenBomb = true
				}
			}
			else if (equal(set, "ChickenGrenades"))
			{
				if (!equal(val, "0"))
				{
					ChickenGrenades = true
				}
			}
			else if (equal(set, "ChickenGlow"))
			{
				if (!equal(val, "0"))
				{
					ChickenGlow = true
				}
			}
			else if (equal(set, "ChickenHealth"))
			{
				if (HealthProtect)
				{
					if (str_to_num(val) > 255)
					{
						ChickenHealth = 255
					}
					else
					{
						ChickenHealth = str_to_num(val)
					}
				}
				else
				{
					ChickenHealth = str_to_num(val)
				}
			}
			else if (equal(set, "ChickenGravity"))
			{
				if (str_to_num(val) > 100)
				{
					ChickenGravity = 100
				}
				else
				{
					ChickenGravity = str_to_num(val)
				}
			}
			else if (equal(set, "ChickenSpeed"))
			{
				if (str_to_num(val) > 600)
				{
					ChickenSpeed = 600.0
				}
				else
				{
					ChickenSpeed = float(str_to_num(val))
				}
			}
			else if (equal(set, "MenuGrv"))
			{
				MenuGrv = str_to_num(val)
			}
			else if (equal(set, "MenuHP"))
			{
				MenuHP = str_to_num(val)
			}
			else if (equal(set, "MenuSpd"))
			{
				MenuSpd = str_to_num(val)
			}
			else if (equal(set, "ACCESS_MENU"))
			{
				ACCESS_MENU = read_flags(val)
			}
			else if (equal(set, "ACCESS_SETTINGS"))
			{
				ACCESS_SETTINGS = read_flags(val)
			}
		}
	}
	return PLUGIN_HANDLED
}

//----------------------------------------------------------------------------------------------
/* SAY COMMAND CODE */
public chickensay(id)
{
	if (is_user_bot(id))
	{
		return PLUGIN_CONTINUE
	}
	new words[32]
	read_args(words, 31)
	new team
	new name[32]

	if ( chicken[id] )
	{
		if (ChickenSelf)
		{
			if (equali(words, "^"/unchickenme^""))
			{
				if (!is_user_alive(id))
				{
					client_print(id, 3, "%L", id, "TURN_BACK_INTO_HUMAN_RESPAWN")
				}
				else
				{
					get_user_name(id, name, 31)
					emit_sound(id, CHAN_ITEM, "misc/cow.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "REST_HUMAN_HIMSELF", ChickenName ? UserOldName[id] : name )
				}
				team = get_user_team2( id )
				if (team == 1)
					g_ChickenTeamT = false
				else
					g_ChickenTeamCT = false
				g_ChickenAll = false
				Reset_Chicken_Model(id + REAL_RESET)
				return PLUGIN_HANDLED
			}
		}
		if (ChickenTalk && is_user_alive(id) && !is_user_bot(id))
		{
			saying_match(id)
			return PLUGIN_HANDLED
		}
	}
	else if (equali(words, "^"/chickenme^""))
	{
		if (ChickenSelf)
		{
			if ((get_user_health(id) <= ChickenHP) && is_user_alive(id))
			{
				client_print(id, 3, "%L", id, "CANT_TURN_CHICKEN_LOW_HEALTH")
				return PLUGIN_HANDLED
			}
			if (!is_user_alive(id))
			{
				client_print(id, 3, "%L", id, "TURN_CHICKEN_RESPAWN")
			}
			else
			{
				get_user_name(id, name, 31)
				emit_sound(id, CHAN_ITEM, "misc/chicken0.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
				show_hudmessage(0, "%L", LANG_PLAYER, "TRANSF_HIMSELF_INTO_CHICKEN", name)
			}
			Set_Chicken_Model(id)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
/* SAY_TEAM COMMAND CODE */
public chickenteamsay(id)
{
	if (ChickenTeamTalk && chicken [id] && is_user_alive(id) && !is_user_bot(id))
	{
		saying_match(id)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
/* SAY/SAY_TEAM CHICKEN CODE */
saying_match(id)
{
	new user[33], ChickenMsg = random_num(0, 4)
	get_user_name(id, user, 32)

	if (ChickenMsg == 0)
	{
		client_print(0, 3, "%s: buk buk", user)
		play_chicken_sound(1)
	}
	else if (ChickenMsg == 1)
	{
		client_print(0, 3, "%s: buk buk", user)
		play_chicken_sound(2)
	}
	else if (ChickenMsg == 2)
	{
		client_print(0, 3, "%s: buk buk", user)
		play_chicken_sound(3)
	}
	else
	{
		client_print(0, 3, "%s: buGAWK", user)
		play_chicken_sound(4)
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
/* SOUND SFX CODE */
play_chicken_sound(sndno)
{
	new users[32], inum
	get_players(users, inum, "c")

	for(new i = 0; i < inum; ++i)
	{
		switch(sndno)
		{
			case 0: client_cmd(users[i], "speak sound/misc/chicken0")
			case 1: client_cmd(users[i], "speak sound/misc/chicken1")
			case 2: client_cmd(users[i], "speak sound/misc/chicken2")
			case 3: client_cmd(users[i], "speak sound/misc/chicken3")
			case 4: client_cmd(users[i], "speak sound/misc/chicken4")
			case 5: client_cmd(users[i], "speak sound/misc/cow")
		}
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
/* RENDERING PLAYER SFX CODE */
set_player_rendering( id, renderfx, red, green, blue, rendermode, renderamt, alive )
{
	if ( is_user_connected( id ) && ( is_user_alive( id ) && alive == 1 ) || alive == 0 )
	{
		new Float:rendercolor[ 3 ]
		set_pev( id, pev_renderfx, renderfx )
		rendercolor[ 0 ] = float( red )
		rendercolor[ 1 ] = float( green )
		rendercolor[ 2 ] = float( blue )
		set_pev( id, pev_rendercolor, rendercolor )
		set_pev( id, pev_rendermode, rendermode )
		set_pev( id, pev_renderamt, float( renderamt ) )
	}
}
//----------------------------------------------------------------------------------------------
/* SHOW MENU CODE */
public amx_chick_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
	{
		return PLUGIN_HANDLED
	}
	g_MenuPage[id] = 1
	show_chickenmenu(id)
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
show_chickenmenu(id)
{
	new menuoption[10][64], smenu[64], menubody[512]
	new keys
	for(new z = 0; z < 10; ++z) menuoption[z][0] = 0 // clear string

	switch(g_MenuPage[id])
	{
		case 1: /* Main Menu */
		{
			formatex(smenu, 63, "%L", id, "MAIN_MENU")
			formatex(menuoption[0], 63, "1. %L^n", id, "PLAYERS_MENU")
			formatex(menuoption[1], 63, "2. %L^n", id, "TEAM_MENU")

			if (id && get_user_flags(id) & ACCESS_SETTINGS != ACCESS_SETTINGS) {}
			else
			{
				formatex(menuoption[2], 63, "3. %L^n", id, "SETTINGS_MENU")
				keys |= (1<<2)
			}
			formatex(menuoption[9], 63, "^n0. %L", id, "EXIT")
			keys |= (1<<0)|(1<<1)|(1<<9)

			formatex(menubody, 511, "%L", id, "CHICKENMOD_OPTIONS",
				smenu, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4],
				menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(id, keys, menubody, -1, "ChickenMod OE")
		}
		case 2: /* Players Menu */
		{
			switch(g_PlayerMenuPage[id])
			{
				default:
				{
					get_players(g_menuPlayers[id], g_menuPlayersNum[id])
					new b = 0, i, user[32], menu = g_PlayerMenuPage[id], start = menu * 7

					if(start >= g_menuPlayersNum[id])
					{
						start = g_PlayerMenuPage[id] = 0
					}
					formatex(smenu, 63, "%L", id, "PLAYERS_MENU")
					new len = formatex(menubody, 511, "%L", id, "CHICKENMOD_PLAYERS", smenu,
						++menu, (g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0)))

					new pkeys = (1<<8)|(1<<9), end = start + 7

					if (end > g_menuPlayersNum[id])
					{
						end = g_menuPlayersNum[id]
					}
					for(new a = start; a < end; ++a)
					{
						i = g_menuPlayers[id][a]
						get_user_name(i, user, 31)

						if (!get_user_team2(i))
						{
							++b
							len += formatex(menubody[len], 511 - len, "\d%d. %s\R%L^n\w", b, user, id, "SPEC")
						}
						else
						{
							pkeys |= (1<<b)
							len += formatex(menubody[len], 511 - len, "%d. %s\R\y%L^n\w", ++b, user, id, chicken[ i ] ? "CHICKEN" : "HUMAN")
						}
					}
					if (end != g_menuPlayersNum[id])
					{
						len += formatex(menubody[len], 511 - len, "^n8. %L^n^n9. %L^n0. %L", id, "MORE", id, "BACK", id, "EXIT")
						pkeys |= (1<<7)
					}
					else
					{
						len += formatex(menubody[len], 511 - len, "^n9. %L^n0. %L", id, "BACK", id, "EXIT")
					}
					show_menu(id, pkeys, menubody, -1, "ChickenMod OE")
				}
			}
		}
		case 3:  /* Team Menu */
		{
			formatex(smenu, 63, "%L", id, "TEAM_MENU")
			formatex(menuoption[0], 63, "1. %L\R\y%L^n\w", id, "TERRORISTS", id, (g_ChickenTeamT || g_ChickenAll) ? "YES" : "NO")
			formatex(menuoption[1], 63, "2. %L\R\y%L^n\w", id, "COUNTER-TERRORISTS", id, (g_ChickenTeamCT || g_ChickenAll) ? "YES" : "NO")
			formatex(menuoption[2], 63, "3. %L\R\y%L^n\w", id, "EVERYONE", id, g_ChickenAll ? "YES" : "NO")

			keys = (1<<0)|(1<<1)|(1<<2)|(1<<8)|(1<<9)
			if ( g_as_running )
			{
				formatex(menuoption[3], 63, "4. VIP\R\y%L^n\w", id, g_ChickenVIP ? "YES" : "NO")
				keys = keys |(1<<3)
			}
			formatex(menuoption[8], 63, "^n9. %L", id, "BACK")
			formatex(menuoption[9], 63, "^n0. %L", id, "EXIT")

			formatex(menubody, 511, "%L", id, "CHICKENMOD_OPTIONS",
				smenu, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4],
				menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(id, keys, menubody, -1, "ChickenMod OE")
		}
		case 4:  /* Setting Menu 1*/
		{
			formatex(smenu, 63, "%L", id, "SETTINGS_MENU")
			formatex(menuoption[0], 63, "1. %L\R\y%L^n\w", id, "CHICKEN_BOMBING", id, ChickenBomb ? "ON" : "OFF")
			formatex(menuoption[1], 63, "2. %L\R\y%L^n\w", id, "CHICKEN_GRENADES", id, ChickenGrenades ? "ON" : "OFF")
			formatex(menuoption[2], 63, "3. %L\R\y%L^n\w", id, "CHICKEN_GLOWING", id, ChickenGlow ? "ON" : "OFF")
			formatex(menuoption[3], 63, "4. %L\R\y%L^n\w", id, "HEALTH_PROTECTION", id, HealthProtect ? "ON" : "OFF")
			formatex(menuoption[4], 63, "5. %L\R\y%L^n\w", id, "CHICKEN_NAMING", id, ChickenName ? "ON" : "OFF")
			formatex(menuoption[5], 63, "6. %L\R\y%L^n\w", id, "CHICKEN_SELF_ABILITY", id, ChickenSelf ? "ON" : "OFF")
			formatex(menuoption[6], 63, "7. %L\R\y%L^n^n\w", id, "CHICKEN_TALKING", id, ChickenTalk ? "ON" : "OFF")
			formatex(menuoption[7], 63, "8. %L^n^n", id, "MORE")
			formatex(menuoption[8], 63, "9. %L^n", id, "BACK")
			formatex(menuoption[9], 63, "0. %L", id, "EXIT")
			keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

			formatex(menubody, 511,  "%L", id, "CHICKENMOD_OPTIONS",
				smenu, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4],
				menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(id, keys, menubody, -1, "ChickenMod OE")
		}
		case 5: /* Setting Menu 2*/
		{
			formatex(smenu, 63, "%L", id, "SETTINGS_MENU")
			formatex(menuoption[0], 63, "1. %L\R\y%L^n\w", id, "CHICKEN_TEAM_TALKING", id, ChickenTeamTalk ? "ON" : "OFF")
			formatex(menuoption[1], 63, "2. %L\R\y%L^n\w", id, "CHICKEN_PLAY_THEME", id, ChickenPlayTheme ? "ON" : "OFF")
			formatex(menuoption[2], 63, ChickenSelf ? "3. %L\R\y%i^n\w" : "\d3. %L\R%i^n\w", id, "NOT_ALLOWED_CHICKEN", ChickenHP)
			formatex(menuoption[3], 63, "4. %L\R\y%i^n\w", id, "CHICKEN_HEALTH", ChickenHealth)
			formatex(menuoption[4], 63, "5. %L\R\y%i^n\w", id, "CHICKEN_GRAVITY", ChickenGravity)
			formatex(menuoption[5], 63, "6. %L\R\y%i^n\w", id, "CHICKEN_SPEED", floatround(ChickenSpeed))
			formatex(menuoption[6], 63, "7. %L\R\y%i^n\w", id, "CHICKEN_VISION", ChickenVision)
			formatex(menuoption[8], 63, "9. %L^n", id, "BACK")
			formatex(menuoption[9], 63, "0. %L", id, "EXIT")
			keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<8)|(1<<9)

			formatex(menubody, 511,  "%L", id, "CHICKENMOD_OPTIONS",
				smenu, menuoption[0], menuoption[1], menuoption[2], menuoption[3], menuoption[4],
				menuoption[5], menuoption[6], menuoption[7], menuoption[8], menuoption[9])
			show_menu(id, keys, menubody, -1, "ChickenMod OE")
		}
	}
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
/* ACTION MENU CODE */
public action_chickenmenu(id, key)
{
	if (g_MenuPage[ id ] == 1)
	{
		switch(key)
		{
			case 0: g_MenuPage[ id ] = 2 // PLAYERS MENU BUTTON (1)
			case 1: g_MenuPage[ id ] = 3 // TEAM MENU BUTTON (2)
			case 2: g_MenuPage[ id ] = 4 // SETTINGS MENU BUTTON (3)
			case 9: // EXIT BUTTON (0)
			{
				// Menu Fix (Popup)
				g_MenuPage[ id ] = 0
				return PLUGIN_HANDLED
			}
		}
		// Bypass Update System
		show_chickenmenu( id )
		return PLUGIN_HANDLED
	}
	else if (g_MenuPage[ id ] == 2)
	{
		switch(key)
		{
			case 7: // MORE BUTTON (8)
			{
				++g_PlayerMenuPage[ id ]
				// Bypass Update System
				show_chickenmenu( id )
				return PLUGIN_HANDLED
			}
			case 8: // BACK BUTTON (9)
			{
				if (g_PlayerMenuPage[ id ] > 0)
				{
					// Bypass Update System
					--g_PlayerMenuPage[ id ]
					show_chickenmenu( id )
					return PLUGIN_HANDLED
				}
				else
				{
					// Bypass Update System
					g_MenuPage[ id ] = 1
					show_chickenmenu( id )
					return PLUGIN_HANDLED
				}
			}
			case 9: // EXIT BUTTON (0)
			{
				// Menu Fix (Popup)
				g_MenuPage[ id ] = 0
				return PLUGIN_HANDLED
			}
			default:
			{
				new player = g_menuPlayers[id][g_PlayerMenuPage[id] * 7 + key]
				new userid = get_user_userid(player)

				if (chicken[ player ])
				{
					server_cmd("c_unchicken #%d", userid)
				}
				else
				{
					server_cmd("c_chicken #%d", userid)
				}
			}
		}
	}
	else if (g_MenuPage[ id ] == 3)
	{
		switch( key )
		{
			case 0:
			{
				if ((!g_ChickenTeamT) && (!g_ChickenAll))
				{
					server_cmd("c_chicken @1")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_T_TRANSF_INTO_CHICKENS")
				}
				else
				{
					server_cmd("c_unchicken @1")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_T_REST_INTO_HUMANS")
				}
			}
			case 1:
			{
				if ((!g_ChickenTeamCT) && (!g_ChickenAll))
				{
					server_cmd("c_chicken @2")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_CT_TRANSF_INTO_CHICKENS")
				}
				else
				{
					server_cmd("c_unchicken @2")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "TEAM_CT_REST_INTO_HUMANS")
				}
			}
			case 2:
			{
				if ((!g_ChickenAll) && ((!g_ChickenTeamT) || (!g_ChickenTeamCT)))
				{
					server_cmd("c_chicken *")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "EVERY1_TRANSF_INTO_CHICKENS")
				}
				else
				{
					server_cmd("c_unchicken *")
					set_hudmessage(255, 25, 255, 0.05, 0.65, 2, 0.1, 4.0, 0.02, 0.02, 10)
					show_hudmessage(0, "%L", LANG_PLAYER, "EVERY1_REST_INTO_HUMANS")
				}
			}
			case 3:
			{
				if ( g_as_running )
				{
					if ( !g_ChickenVIP )
					{
						server_cmd("c_chicken @3")
					}
					else
					{
						server_cmd("c_unchicken @3")
					}
				}
			}
			case 8: // BACK BUTTON (9)
			{
				// Bypass Update System
				g_MenuPage[ id ] = 1
				show_chickenmenu(id)
				return PLUGIN_HANDLED
			}
			case 9: // EXIT BUTTON (0)
			{
				// Menu Fix (Popup)
				g_MenuPage[ id ] = 0
				return PLUGIN_HANDLED
			}
		}
	}
	else if (g_MenuPage[ id ] == 4)
	{
		switch( key )
		{
			case 0:
			{
				ChickenBomb ? (ChickenBomb = false) : (ChickenBomb = true)
			}
			case 1:
			{
				ChickenGrenades ? (ChickenGrenades = false) : (ChickenGrenades = true)
			}
			case 2:
			{
				(ChickenGlow) ? (ChickenGlow = false) : (ChickenGlow = true)
				Set_Chicken_Glowing( 0 )
			}
			case 3:
			{
				HealthProtect ? (HealthProtect = false) : (HealthProtect = true)
			}
			case 4:
			{
				ChickenName ? (ChickenName = false) : (ChickenName = true)
			}
			case 5:
			{
				ChickenSelf ? (ChickenSelf = false) : (ChickenSelf = true)
			}
			case 6:
			{
				ChickenTalk ? (ChickenTalk = false) : (ChickenTalk = true)
			}
			case 7: // MORE BUTTON (8)
			{
				// Bypass Update System
				g_MenuPage[id] = 5
				show_chickenmenu(id)
				return PLUGIN_HANDLED
			}
			case 8: // BACK BUTTON (9)
			{
				// Bypass Update System
				g_MenuPage[ id ] = 1
				show_chickenmenu(id)
				return PLUGIN_HANDLED
			}
			case 9: // EXIT BUTTON (0)
			{
				// Menu Fix (Popup)
				g_MenuPage[ id ] = 0
				return PLUGIN_HANDLED
			}
		}
	}
	else if ( g_MenuPage[ id ] == 5 )
	{
		switch(key)
		{
			case 0:
			{
				ChickenTeamTalk ? (ChickenTeamTalk = false) : (ChickenTeamTalk = true)
			}
			case 1:
			{
				ChickenPlayTheme ? (ChickenPlayTheme = false) : (ChickenPlayTheme = true)
			}
			case 2:
			{
				if ( !ChickenSelf )
				{
					// Bypass Update System
					show_chickenmenu(id)
					return PLUGIN_HANDLED
				}
				else if (ChickenHP + MenuGrv > 100 || ChickenHP > 100)
				{
					ChickenHP = 0
				}
				else
				{
					ChickenHP += MenuGrv
				}
			}
			case 3:
			{
				new health = ChickenHealth

				if ( HealthProtect )
				{
					if ( (health + MenuHP > 255) || (health > 255) )
					{
						ChickenHealth = 1
					}
					else
					{
						ChickenHealth = (health += MenuHP)
					}
				}
				else
				{
					ChickenHealth = (health += MenuHP)
				}
			}
			case 4:
			{
				new gravity = ChickenGravity

				if ( (gravity + MenuGrv > 100) || (gravity > 100) )
				{
					ChickenGravity = 0
				}
				else
				{
					ChickenGravity = (gravity += MenuGrv)
				}
				Set_Chicken_Gravity( 0 ) // Update all Chickens to new gravity setting
			}
			case 5:
			{
				new Float:speed = ChickenSpeed

				if ( (speed + float(MenuSpd) > 600.0) || (speed > 600.0) )
				{
					ChickenSpeed = 0.0
				}
				else
				{
					ChickenSpeed = (speed += float(MenuSpd))
				}
				Set_Chicken_Speed( 0 ) // Update all Chickens to new speed setting
			}
			case 6:
			{
				if ( (ChickenVision + MenuGrv > 255) || (ChickenVision > 255) )
				{
					ChickenVision = 0
				}
				else
				{
					ChickenVision += MenuGrv
				}
				Set_Chicken_Vision( 0 ) // Update all Chickens to new vision setting
			}
			case 8: // BACK BUTTON (9)
			{
				// Bypass Update System
				g_MenuPage[ id ] = 4
				show_chickenmenu(id)
				return PLUGIN_HANDLED
			}
			case 9: // EXIT BUTTON (0)
			{
				// Menu Fix (Popup)
				g_MenuPage[ id ] = 0
				return PLUGIN_HANDLED
			}
		}
	}
	set_task(0.5, "update_menu")
	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
/* MENU UPDATER */
public update_menu()
{
	new admins[32], inum
	get_players(admins, inum)
	for(new i = 0; i < inum; ++i)
	{
		if (g_MenuPage[admins[i]] > 1)
		{
			show_chickenmenu(admins[i])
		}
	}
}
//----------------------------------------------------------------------------------------------
/* SPECIAL TASKS CALLING FOR MODELLING */
public set_task2( Float:time, const function[], taskid )
{
	if ((taskid < 65) && (taskid > 0))
	{
		TASK_START_TIME[taskid] = get_gametime() + time
		format(TASK_FUNC_NAME[taskid], 31, function)
		TASKID_EXEC[taskid] = 1
	}
}

public StartFrame()
{
	static taskid
	static Float: game_time
	static tasknr
	tasknr = 0
	game_time = get_gametime()

	if (!g_cs_running)
		return

	for (taskid = 1; taskid < 65; taskid++)
	{
		if (!TASKID_EXEC[taskid])
			continue
		if (TASK_START_TIME[taskid] > game_time)
			continue
		if (TASK_FUNC_NAME[taskid][0] == '^0')
			continue

		TASKID_EXEC[taskid] = 0
		TASK_START_TIME[taskid] = 0.0

		if (callfunc_begin(TASK_FUNC_NAME[ taskid ]) == 1)
		{
			callfunc_push_int(taskid)
			callfunc_end()
		}

		tasknr++
		if (tasknr > 1)
			break
	}
}
