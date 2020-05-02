/**
 * csdm_itemmode.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 * Item editor Allows add/remove items/weapons for CSDM 2.x
 * CSDM Item Mode - Spawns different types of items all over the map.
 *
 * (C)2003-2006 Borja "FALUCO" Ferrer
 * (C)2003-2006 KWo
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
#include <cstrike>
#include <csdm>

#define MAX_ITEMS	250
#define MAX_ENTS 	1400
#define MAX_PACKS	50
#define ITEMTYPES_NUM	42
#define MAX_GRENADES 99
#define MAX_MATERIALIZE_ATTEMPTS 10

// pack slot constants...
#define SLOTS_AUX	4
#define SLOTS_MAX	8
#define SLOTS		(SLOTS_AUX+SLOTS_MAX)
#define SLOT_WP_COUNT	0
#define SLOT_ENT_ID	1
#define SLOT_PACK_ID	2
#define SLOT_LONGJUMP	3

// #define SLOTS		12

#define ITEM_LONGJUMP	31
#define ITEM_MEDKIT		32
#define ITEM_BATTERY		33
#define ITEM_PISTOLAMMO	34
#define ITEM_RIFLEAMMO	35
#define ITEM_SHOTAMMO	36
#define ITEM_SMGAMMO		37
#define ITEM_AWPAMMO		38
#define ITEM_PARAAMMO	39
#define ITEM_FULLAMMO	40
#define ITEM_ARMOR		41
#define ITEM_PACK			(MAX_ITEMS + 1)

// drop pack modes (Simon Logic: to support 2 types of dropped packs)...
#define DROP_NO_PACK 0	// disable
#define DROP_DM_PACK 1	// dtoppack will include weapon, ammo & jetpack
#define DROP_CS_PACK 2	// same as DROP_DM_PACK + include armor & heatlh also

#define CWRAP(%1,%2) (containi(%1,%2) != -1)

// Config variables
new bool:g_Enabled = false
// new bool:g_EnabledCfg = false
new bool:g_EditorEnabled = false
new bool:g_OldStateItemMode = false
new bool:g_bSkipHelp[33] = {false, ...}	// Simon Logic - to let disable Longjump help

// Simon Logic: i need this to fix bug#335 (when the droppack can be taken also with the gun,
// but weapons_stay was > 0  so You could take the gun anyway, too...
new g_iCfgWeaponStayTime 
new g_droppacks = DROP_DM_PACK

new g_battery = 15
new g_medkit = 15
new Float:g_itemTime = 20.0
new Float:g_packTime = 20.0

new g_msgItemPickup // Simon Logic
new g_msgAmmoPickup // Simon Logic
new g_iMaxNadesH // Simon Logic: max HE a player can grab
new g_iMaxNadesS // Simon Logic: max SG a player can grab
new g_iMaxNadesF // Simon Logic: max FG a player can grab
new bool:g_bPersistentItems = false // Simon Logic - to add an option against falling down items
new bool:g_bNoGunMenu = true // to prevent displaying or not gun menu if item mode is enabled

// Entity arrays
new g_EntModels[][] = 
{
	"", 
	"models/w_p228.mdl", 
	"", 
	"models/w_scout.mdl", 
	"models/w_hegrenade.mdl", 
	"models/w_xm1014.mdl", 
	"", 
	"models/w_mac10.mdl", 
	"models/w_aug.mdl", 
	"models/w_smokegrenade.mdl", 
	"models/w_elite.mdl", 
	"models/w_fiveseven.mdl", 
	"models/w_ump45.mdl", 
	"models/w_sg550.mdl", 
	"models/w_galil.mdl", 
	"models/w_famas.mdl", 
	"models/w_usp.mdl", 
	"models/w_glock18.mdl", 
	"models/w_awp.mdl", 
	"models/w_mp5.mdl", 
	"models/w_m249.mdl", 
	"models/w_m3.mdl", 
	"models/w_m4a1.mdl", 
	"models/w_tmp.mdl", 
	"models/w_g3sg1.mdl", 
	"models/w_flashbang.mdl", 
	"models/w_deagle.mdl", 
	"models/w_sg552.mdl", 
	"models/w_ak47.mdl", 
	"", 
	"models/w_p90.mdl", 
	"models/w_longjump.mdl", 
	"models/w_medkit.mdl", 
	"models/w_battery.mdl", 
	"models/w_357ammobox.mdl", 
	"models/w_9mmarclip.mdl", 
	"models/w_shotbox.mdl", 
	"models/w_9mmclip.mdl", 
	"models/w_crossbow_clip.mdl", 
	"models/w_chainammo.mdl", 
	"models/w_isotopebox.mdl", 
	"models/w_assault.mdl"
}
new g_EntClass[][] = 
{
	"", 
	"csdmw_p228", 
	"", 
	"csdmw_scout", 
	"csdmw_hegrenade", 
	"csdmw_xm1014", 
	"", 
	"csdmw_mac10", 
	"csdmw_aug", 
	"csdmw_smokegrenade", 
	"csdmw_elite", 
	"csdmw_fiveseven", 
	"csdmw_ump45", 
	"csdmw_sg550", 
	"csdmw_galil", 
	"csdmw_famas", 
	"csdmw_usp", 
	"csdmw_glock18", 
	"csdmw_awp", 
	"csdmw_mp5navy", 
	"csdmw_m249", 
	"csdmw_m3", 
	"csdmw_m4a1", 
	"csdmw_tmp", 
	"csdmw_g3sg1", 
	"csdmw_flashbang", 
	"csdmw_deagle", 
	"csdmw_sg552", 
	"csdmw_ak47", 
	"", 
	"csdmw_p90", 
	"csdm_longjump", 
	"csdm_medkit", 
	"csdm_battery", 
	"csdm_pistolammo", 
	"csdm_rifleammo", 
	"csdm_shotammo", 
	"csdm_smgammo", 
	"csdm_awpammo", 
	"csdm_paraammo", 
	"csdm_fullammo", 
	"csdm_armor"
}
stock g_Weap2Ammo[] =
{
	0,
	ITEM_PISTOLAMMO,//CSW_P228
	0,
	ITEM_RIFLEAMMO,	//CSW_SCOUT
	0,		//CSW_HEGRENADE
	ITEM_SHOTAMMO,	//CSW_XM1014
	0,		//CSW_C4
	ITEM_SMGAMMO,	//CSW_MAC10
	ITEM_RIFLEAMMO,	//CSW_AUG
	0,		//CSW_SMOKEGRENADE
	ITEM_PISTOLAMMO,//CSW_ELITE
	ITEM_PISTOLAMMO,//CSW_FIVESEVEN
	ITEM_SMGAMMO,	//CSW_UMP45
	ITEM_RIFLEAMMO,	//CSW_SG550
	ITEM_RIFLEAMMO,	//CSW_GALIL
	ITEM_RIFLEAMMO,	//CSW_FAMAS
	ITEM_PISTOLAMMO,//CSW_USP
	ITEM_PISTOLAMMO,//CSW_GLOCK18
	ITEM_AWPAMMO,	//CSW_AWP
	ITEM_SMGAMMO,	//CSW_MP5NAVY
	ITEM_PARAAMMO,	//CSW_M249
	ITEM_SHOTAMMO,	//CSW_M3
	ITEM_RIFLEAMMO,	//CSW_M4A1
	ITEM_SMGAMMO,	//CSW_TMP
	ITEM_RIFLEAMMO,	//CSW_G3SG1
	0,		//CSW_FLASHBANG
	ITEM_PISTOLAMMO,//CSW_DEAGLE
	ITEM_RIFLEAMMO,	//CSW_SG552
	ITEM_RIFLEAMMO,	//CSW_AK47
	0,		//CSW_KNIFE
	ITEM_SMGAMMO	//CSW_P90
}
new g_EntTable[MAX_ENTS] = {-1, ...}			// Contains the item_id (0-249) in the entid position(0-1500)
new g_EntType[MAX_ITEMS]			// Contains the item type (ammos, armor, ...) in the file order
new g_EntCount					// Global item count in the map (deathpacks not included)
new g_EntVecs[MAX_ITEMS][3]			// Contains the item position in the file order
new g_EntAngle[MAX_ITEMS] // Simon Logic: to set angle of items - Contains yaw angle in the file order
new g_EntId[MAX_ITEMS]				// Contains the entid (0-1500) in the file order
new g_Ent[33] = {-1, ...}				// Contains the entid (0-1500) of the closest entity for the player editing items
new bool:HasLongJump[33] =	{false, ...}
new bool:IsRestricted[ITEMTYPES_NUM] =	{false, ...}	// Contains if an item is restricted or not
new bool:g_PackID[MAX_PACKS] = {true, ...}	// If true the packid can be used, else it's being use by another pack
new g_PackContents[MAX_PACKS][SLOTS]		// Contains the pack contents in the packid position(1-64)
						// [0]=weapon_count [1]=entid [2]=packid [3]=longjump [4...]=weapons
new g_MaxPlayers
new g_AllocStr

new bool:g_MainPlugin = true

new Float:red[3] = {255.0,0.0,0.0}
new Float:yellow[3] = {255.0,200.0,20.0}
new pv_csdm_additems

// page info for settings in CSDM Setting Menu
new g_SettingsMenu = 0
new g_ItemSettMenu = 0
new g_ItemsInMenuNr = 0
new g_PageSettMenu = 0

//Tampering with the author and name lines can violate the copyrights
new PLUGINNAME[] = "CSDM Item Mode"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "FALUCO & KWo & SL"

//Menus
new g_cItemMode

new g_MainMenu[] = "CSDM: Item Manager"
new g_MainMenuID = -1
new g_cMain

new g_AddItemsMenu[] = "CSDM: Add Items Menu"
new g_AddItemsMenuID = -1
new g_cAddItems

new g_AddPistolsMenu[] = "CSDM: Add Pistols Menu"
new g_AddPistolsMenuID = -1
new g_cAddPistols

new g_AddSmgMenu[] = "CSDM: Add SMG Menu"
new g_AddSmgMenuID = -1
new g_cAddSmg

new g_AddRifles1Menu[] = "CSDM: Add Rifles(1) Menu"
new g_AddRifles1MenuID = -1
new g_cAddRifles1

new g_AddRifles2Menu[] = "CSDM: Add Rifles(2) Menu"
new g_AddRifles2MenuID = -1
new g_cAddRifles2

new g_AddShotgunMenu[] = "CSDM: Add Shotgun/Machine Gun Menu"
new g_AddShotgunMenuID = -1
new g_cAddShotgun

new g_AddEquipMenu[] = "CSDM: Add Equipement Menu"
new g_AddEquipMenuID = -1
new g_cAddEquip


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
	g_iMaxNadesH = g_MaxBPAmmo[CSW_HEGRENADE] 	// Simon Logic : max HE a player can grab
	g_iMaxNadesS = g_MaxBPAmmo[CSW_SMOKEGRENADE] // Simon Logic : max SG a player can grab
	g_iMaxNadesF = g_MaxBPAmmo[CSW_FLASHBANG] 	// Simon Logic : max FG a player can grab

	g_AllocStr = engfunc(EngFunc_AllocString, "info_target")

	pv_csdm_additems	= register_cvar("csdm_add_items", "0")

	csdm_reg_cfg("items", "cfgmain")
	csdm_reg_cfg("item_restrictions", "cfgrestricts")
	csdm_reg_cfg("settings", "cfgsettings") // Simon Logic : to get weapons_stay time...
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS)
	register_cvar("itemmode_version", CSDM_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_forward(FM_Touch, "hook_touch")

	g_MaxPlayers = get_maxplayers()
	register_concmd("edit_items", "showmen", ADMIN_MAP, "Edits Items configuration")
	register_concmd("csdm_entdump", "csdm_entdump", ADMIN_MAP, "Dumps a text file with entity information.")
	register_concmd("i_m_change_state", "i_m_change_state", ADMIN_MAP, "Changes the state of Item Mode.")
	register_clcmd("csdm_item_sett_menu", "csdm_item_sett_menu", ADMIN_MAP, "CSDM Item Settings Menu")

	g_MainPlugin = module_exists("csdm_main") ? true : false
	
	if (g_MainPlugin)
	{
		new menu = csdm_main_menu()
		g_SettingsMenu = csdm_settings_menu()

		g_ItemsInMenuNr = menu_items(g_SettingsMenu)
		g_PageSettMenu = g_ItemsInMenuNr / 7

		menu_additem(menu, "Item Editor", "edit_items", ADMIN_MAP)

		g_ItemSettMenu = menu_create("CSDM Item Settings Menu", "use_csdm_item_menu")
		menu_additem(g_SettingsMenu, "CSDM Item Settings", "csdm_item_sett_menu", ADMIN_MAP)

		if (g_ItemSettMenu)
		{
			g_cItemMode = menu_makecallback("c_ItemMode")
			menu_additem(g_ItemSettMenu, "Item Mode", "i_m_change_state", ADMIN_MAP, g_cItemMode)

			new cb_persistent = menu_makecallback("c_persist_menu")
			menu_additem(g_ItemSettMenu, "Persistent Items Enabled/Disabled", "csdm_persist_ctrl", ADMIN_MAP, cb_persistent)

			new cb_droppack = menu_makecallback("c_droppack_menu")
			menu_additem(g_ItemSettMenu, "Drop Pack DM/CS/Disabled", "csdm_droppacks_ctrl", ADMIN_MAP, cb_droppack)

			new cb_ngm = menu_makecallback("c_ngm_menu")
			menu_additem(g_ItemSettMenu, "Gun Menu Enabled/Disabled for Item Mode", "csdm_ngm_ctrl", ADMIN_MAP, cb_ngm)

			menu_additem(g_ItemSettMenu, "Back", "csdm_sett_back", ADMIN_MAP)
		}
	}

	// Simon Logic: this is for messages to send to player when item_healthkit
	// or item_armor is grabbed
	g_msgItemPickup = get_user_msgid("ItemPickup")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}

public csdm_item_sett_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_ItemSettMenu, 0)

	return PLUGIN_HANDLED
}

public use_csdm_item_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_ItemSettMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_ItemSettMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}

	if (equali(command,"i_m_change_state"))
	{
		client_cmd(id, command)
		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_persist_ctrl"))
	{
		g_bPersistentItems = (g_bPersistentItems ? false:true)
		menu_display(id, g_ItemSettMenu, 0)
		client_print(id, print_chat, "Items are %s", g_bPersistentItems ? "persistent" : "falling down")
		log_amx("CSDM Persistent Items %s", g_bPersistentItems ? "persistent" : "falling down")

		csdm_write_cfg(id, "items", "persistent_items", g_bPersistentItems ? "1" : "0")

		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_droppacks_ctrl"))
	{
		g_droppacks++
		if (g_droppacks > 2)
			g_droppacks = 0
		menu_display(id, g_ItemSettMenu, 0)
		client_print(id, print_chat, "Drop Pack %s", (g_droppacks == 0) ? "disabled" :  (g_droppacks == 1) ? "CS type" : "DM type")
		log_amx("Drop Pack %s", (g_droppacks == 0) ? "disabled" :  (g_droppacks == 1) ? "CS type" : "DM type")

		new sz[4]
		num_to_str(g_droppacks, sz, 1)
		csdm_write_cfg(id, "items", "drop_packs", sz)

		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_ngm_ctrl"))
	{
		g_bNoGunMenu = (g_bNoGunMenu ? false:true)
		menu_display(id, g_ItemSettMenu, 0)
		client_print(id, print_chat, "Gun Menu is %s for Item Mode", g_bNoGunMenu ? "disabled" : "enabled")
		log_amx("Gun Menu is %s for Item Mode", g_bNoGunMenu ? "disabled" : "enabled")

		csdm_write_cfg(id, "items", "no_gun_menu", g_bNoGunMenu ? "1" : "0")

		if (pv_csdm_additems && g_bNoGunMenu)
			set_pcvar_num(pv_csdm_additems, 1)
		else if (pv_csdm_additems)
			set_pcvar_num(pv_csdm_additems, 0)

		return PLUGIN_HANDLED
	}
	else if (equali(command,"csdm_sett_back"))
	{
		menu_display(id, g_SettingsMenu, g_PageSettMenu)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public c_persist_menu(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_persist_ctrl"))
	{
		if (!g_bPersistentItems)
		{
			menu_item_setname(menu, item, "Persistent Items Disabled")
		} else {
			menu_item_setname(menu, item, "Persistent Items Enabled")
		}
	}
}

public c_droppack_menu(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_droppacks_ctrl"))
	{
		if (g_droppacks == 0)
		{
			menu_item_setname(menu, item, "Drop Pack Disabled")
		} 
		else if (g_droppacks == 1)
		{
			menu_item_setname(menu, item, "Drop Pack CS Enabled")
		}
		else if (g_droppacks == 2)
		{
			menu_item_setname(menu, item, "Drop Pack DM Enabled")
		}
	}
}

public c_ngm_menu(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ngm_ctrl"))
	{
		if (g_bNoGunMenu)
		{
			menu_item_setname(menu, item, "Gun Menu Disabled for Item Mode")
		} else {
			menu_item_setname(menu, item, "Gun Menu Enabled for Item Mode")
		}
	}
}

public client_connect(id)
{
	if (!g_Enabled || !csdm_active())
		return

	HasLongJump[id] = false
	g_bSkipHelp[id] = false
}

public plugin_precache()
{
	precache_model("models/w_medkit.mdl")
	precache_model("models/w_battery.mdl")
	precache_model("models/w_357ammobox.mdl")		//Pistol Ammo
	precache_model("models/w_shotbox.mdl")			//Shotgun Ammo
	precache_model("models/w_9mmclip.mdl")			//SMG Ammo
	precache_model("models/w_9mmarclip.mdl")		//Rifle Ammo
	precache_model("models/w_crossbow_clip.mdl")		//Awp Ammo
	precache_model("models/w_isotopebox.mdl")		//Full ammo
	precache_model("models/w_isotopeboxt.mdl")		//Full ammo
	precache_model("models/w_chainammo.mdl")		//Full ammo
	precache_model("models/w_weaponbox.mdl")		//Drop pack
	precache_model("models/w_assault.mdl")			//assaultsuit
	precache_model("models/w_longjump.mdl")			//longjump - thanks asskicr
	precache_model("models/w_longjumpt.mdl")		//"
	precache_sound("items/smallmedkit1.wav")
	precache_sound("items/gunpickup2.wav")
	precache_sound("items/suitchargeok1.wav")
	precache_sound("items/ammopickup2.wav")
	precache_sound("items/clipinsert1.wav")

	precache_model("sprites/640hud2.spr") // Simon Logic: precache fixed sprite (to display two icons)

	return PLUGIN_CONTINUE
}

public csdm_StateChange(csdm_state)
{
	if (g_Enabled && csdm_state == CSDM_DISABLE)
	{
		destroyAllItems()
		destroyAllPacks()
		g_OldStateItemMode = g_Enabled
	}

	if ((g_OldStateItemMode) && !g_EditorEnabled && (csdm_state == CSDM_ENABLE))
	{
		g_Enabled = true
		ReadFile()
		SetEnts()
		if (pv_csdm_additems && g_bNoGunMenu)
			set_pcvar_num(pv_csdm_additems, 1)
	}
}

public i_m_change_state(id)
{
	if (!(get_user_flags(id)&ADMIN_MAP))
	{
		client_print(id, print_console, "[CSDM] You do not have appropriate access.")
		client_print(id, print_chat, "[CSDM] You do not have appropriate access.")
		return PLUGIN_HANDLED
	}

	if (g_Enabled)
	{
		if (csdm_active())
		{
			destroyAllItems()
			destroyAllPacks()
		}
		g_Enabled = false
		g_OldStateItemMode = false
		set_pcvar_num(pv_csdm_additems, 0)
		client_print(0,print_chat,"[CSDM] Item Mode disabled")
		csdm_write_cfg(id, "items", "enabled", "0")
	}
	else if (g_EntCount)
	{
		g_Enabled = true
		g_OldStateItemMode = true

		if (csdm_active())
		{
			ReadFile()
			SetEnts()
		}
		if (g_bNoGunMenu)
			set_pcvar_num(pv_csdm_additems, 1)
		client_print(0,print_chat,"[CSDM] Item Mode enabled")
		csdm_write_cfg(id, "items", "enabled", "1")
	}
	menu_display(id, g_ItemSettMenu, 0)
	return PLUGIN_HANDLED
}

public c_ItemMode(id, menu, item)
{
	new cmd[6], fItem[326], iName[64]
	new access, callback	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)

	if (g_Enabled)
	{
		format(fItem,325,"Item Mode Enabled")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	else if (!g_EntCount)
	{
		format(fItem,325,"Item Mode Disabled - no items")
		menu_item_setname(menu, item, fItem )
		return ITEM_DISABLED
	}
	else
	{
		format(fItem,325,"Item Mode Disabled")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	return ITEM_ENABLED
}

public c_PersItems(id, menu, item)
{
	new cmd[6], fItem[326], iName[64]
	new access, callback	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)

	if (g_bPersistentItems)
	{
		format(fItem,325,"Items Persistent")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	else
	{
		format(fItem,325,"Items Falling Down")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	return ITEM_ENABLED
}

public c_NoGunMenu(id, menu, item)
{
	new cmd[6], fItem[326], iName[64]
	new access, callback	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)

	if (g_bNoGunMenu)
	{
		format(fItem,325,"Gun Menu Disabled for Item Mode")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	else
	{
		format(fItem,325,"Gun Menu Enabled for Item Mode")
		menu_item_setname(menu, item, fItem )
		return ITEM_ENABLED
	}
	return ITEM_ENABLED
}

public cfgmain(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32]

		parse(line, setting, 23, sign, 2, value, 31)
		
		if (equali(setting, "enabled"))
		{
			g_Enabled = str_to_num(value) ? true : false
			g_OldStateItemMode = g_Enabled
		}
		else if (equali(setting, "persistent_items")) // Simon Logic: items without falling effect
		{
			g_bPersistentItems = str_to_num(value) ? true : false
		}
		else if (equali(setting, "drop_packs"))
		{
			g_droppacks = str_to_num(value)
			if(g_droppacks < 0) 
				g_droppacks = 0
		}
		else if (equali(setting, "battery"))
		{
			g_battery = str_to_num(value)
		}
		else if (equali(setting, "medkit"))
		{
			g_medkit = str_to_num(value)
		}
		else if (equali(setting, "item_time"))
		{
			g_itemTime = str_to_float(value)
		}
		else if (equali(setting, "drop_time"))  // Simon Logic: fix bug#339
		{
			g_itemTime = str_to_float(value)
			g_itemTime = (g_itemTime > 30.0) ? 30.0 : g_itemTime
		}
		else if (equali(setting, "max_hnades")) // Simon Logic: req#327
		{
			assignMaxNades(g_iMaxNadesH, value, CSW_HEGRENADE)
		}
		else if (equali(setting, "max_fnades")) // Simon Logic: req#327
		{
			assignMaxNades(g_iMaxNadesF, value, CSW_FLASHBANG)
		}
		else if (equali(setting, "max_snades")) // Simon Logic: req#327
		{
			assignMaxNades(g_iMaxNadesS, value, CSW_SMOKEGRENADE)
		}
		else if (equali(setting, "no_gun_menu"))
		{
			g_bNoGunMenu = str_to_num(value) ? true : false
		}
	}
}

public cfgrestricts(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new itemname[24]
		parse(line, itemname, 23)
		
		if (equali(itemname, "longjump"))
		{
			IsRestricted[ITEM_LONGJUMP] = true
		}
		else if (equali(itemname, "medkit"))
		{
			IsRestricted[ITEM_MEDKIT] = true
		}
		else if (equali(itemname, "battery"))
		{
			IsRestricted[ITEM_BATTERY] = true
		}
		else if (equali(itemname, "pistolammo"))
		{
			IsRestricted[ITEM_PISTOLAMMO] = true
		}
		else if (equali(itemname, "rifleammo"))
		{
			IsRestricted[ITEM_RIFLEAMMO] = true
		}
		else if (equali(itemname, "shotammo"))
		{
			IsRestricted[ITEM_SHOTAMMO] = true
		}
		else if (equali(itemname, "smgammo"))
		{
			IsRestricted[ITEM_SMGAMMO] = true
		}
		else if (equali(itemname, "awpammo"))
		{
			IsRestricted[ITEM_AWPAMMO] = true
		}
		else if (equali(itemname, "paraammo"))
		{
			IsRestricted[ITEM_PARAAMMO] = true
		}
		else if (equali(itemname, "fullammo"))
		{
			IsRestricted[ITEM_FULLAMMO] = true
		}
		else if (equali(itemname, "armor"))
		{
			IsRestricted[ITEM_ARMOR] = true
		} else {
			new weapname[24], weaptype
			
			format(weapname, 23, "weapon_%s", itemname)
			weaptype = getWeapId(weapname)
			
			if (weaptype != 0)
				IsRestricted[weaptype] = true
			else
				log_amx("^"%s^" is not a valid name. Check your restrictions for item mode.", itemname)
		}
	}

	if (readAction == CFG_RELOAD)
	{
		// Reset all restrictions
		arrayset(IsRestricted, false, ITEMTYPES_NUM)
	}

	if (readAction == CFG_DONE)
	{
		destroyAllItems()
		destroyAllPacks()
		ReadFile()
		if ((g_Enabled) && (csdm_active()))
		{
			SetEnts()
			if (g_bNoGunMenu)
				set_pcvar_num(pv_csdm_additems, 1)
		}
		else if (!g_Enabled)
			set_pcvar_num(pv_csdm_additems, 0)
	}
}

public cfgsettings(readAction, line[], section[]) // SL: we need to read 'weapons_stay' value only
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);

		if (equali(setting, "weapons_stay")) {
			g_iCfgWeaponStayTime = str_to_num(value)
		}
	}
}


ReadFile()
{
	new Map[32], config[32], File[64]

	get_mapname(Map, 31)
	get_localinfo("amxx_configsdir", config, 31)

	format(File, 63, "%s\csdm\items\ents_%s.cfg", config, Map)
	g_EntCount = 0

	if (file_exists(File))
	{
		new Data[51], len, EntName[25]
		new line = 0
		new pos[4][8]
		new iParamCount, iTotalItems = 0

		while ((g_EntCount < MAX_ITEMS) && ((line = read_file(File, line, Data, 50, len)) != 0))
		{
			if (strlen(Data) < 2)
				continue

			iTotalItems++

			iParamCount = parse(Data, EntName, 24, pos[0], 7, pos[1], 7, pos[2], 7, pos[3], 7)
			if(iParamCount < 4)
				continue

			parse(Data, EntName, 24, pos[0], 7, pos[1], 7, pos[2], 7)

			g_EntVecs[g_EntCount][0] = str_to_num(pos[0])
			g_EntVecs[g_EntCount][1] = str_to_num(pos[1])
			g_EntVecs[g_EntCount][2] = str_to_num(pos[2])

			if(iParamCount == 5)	// Simon Logic: store item angle (yaw) - 5th alternative value
				g_EntAngle[g_EntCount] = str_to_num(pos[3])
			else
				g_EntAngle[g_EntCount] = 0

			g_EntType[g_EntCount] = 0 // clear the data - if item editor was enabled, there might be some data for restricted items...

			if (CWRAP(EntName, "item_longjump") && (!(IsRestricted[ITEM_LONGJUMP]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_LONGJUMP
			else if (CWRAP(EntName, "item_healthkit") && (!(IsRestricted[ITEM_MEDKIT]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_MEDKIT
			else if (CWRAP(EntName, "item_battery") && (!(IsRestricted[ITEM_BATTERY]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_BATTERY
			else if (CWRAP(EntName, "pistol_ammo") && (!(IsRestricted[ITEM_PISTOLAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_PISTOLAMMO
			else if (CWRAP(EntName, "rifle_ammo") && (!(IsRestricted[ITEM_RIFLEAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_RIFLEAMMO
			else if (CWRAP(EntName, "shotgun_ammo") && (!(IsRestricted[ITEM_SHOTAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_SHOTAMMO
			else if (CWRAP(EntName, "smg_ammo") && (!(IsRestricted[ITEM_SMGAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_SMGAMMO
			else if (CWRAP(EntName, "full_ammo") && (!(IsRestricted[ITEM_FULLAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_FULLAMMO
			else if (CWRAP(EntName, "armor") && (!(IsRestricted[ITEM_ARMOR]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_ARMOR
			else if (CWRAP(EntName, "awp_ammo") && (!(IsRestricted[ITEM_AWPAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_AWPAMMO
			else if (CWRAP(EntName, "para_ammo") && (!(IsRestricted[ITEM_PARAAMMO]) || g_EditorEnabled))
				g_EntType[g_EntCount] = ITEM_PARAAMMO
			else
			{
				new weaptype = getWeapId(EntName)

				if (weaptype != 0 && (!(IsRestricted[weaptype]) || g_EditorEnabled))
					g_EntType[g_EntCount] = weaptype
			}

			g_EntCount++
		}
		log_amx("Loaded %d/%d items for map %s., Item Editor is %s.", g_EntCount, iTotalItems, Map, g_EditorEnabled? "enabled":"disabled")
	} else {
		log_amx("No items file found (%s)", File)
		g_Enabled = false
		g_OldStateItemMode = false	
	}
}

SetEnts()
{
	new id
	if (g_EntCount > 0)
	{
		for (new i = 0; i < g_EntCount; i++)
		{
			id = g_EntId[i]
			if (id)
			{
			// NOTE: if the Item Editor menu disappeared, but entities were created already, we may need to destroy them first, 
			// then create again with this function - to prevent have double entities...
				if (pev_valid(id))
				{
					engfunc(EngFunc_RemoveEntity, id)

					if (g_bPersistentItems)
					{
						if(task_exists(id))
							remove_task(id)
					}
				}
			}
			g_EntId[i] = MakeEnt(i)
		}
	}
}

CreateEntId()
{
	return engfunc(EngFunc_CreateNamedEntity, g_AllocStr)
}

MakeEnt(item_id)
{
	new entid = CreateEntId()
	if (!entid)
		return 0

	new Float:Vec[3]
	IVecFVec(g_EntVecs[item_id], Vec)
	new type = g_EntType[item_id]

	g_EntTable[entid] = item_id

	set_pev(entid, pev_classname, g_EntClass[type])
	engfunc(EngFunc_SetModel, entid, g_EntModels[type])

	//set_pev(entid, pev_origin, Vec)
	engfunc(EngFunc_SetOrigin, entid, Vec)
	set_pev(entid, pev_movetype, MOVETYPE_TOSS)
	set_pev(entid, pev_solid, SOLID_TRIGGER)
	// Simon Logic: set an angle of item
	Vec[0] = 0.0
	Vec[1] = float(g_EntAngle[item_id])
	Vec[2] = 0.0
	set_pev(entid, pev_angles, Vec)
	if ((g_bPersistentItems))
	{
		// Simon Logic: speed up item falling down
		Vec[0] = 0.0; Vec[1] = 0.0;	Vec[2] = -1999.0
		set_pev(entid, pev_velocity, Vec)
	
		// Simon Logic: hide item and launch a task to init item when it's fully
		// on gound
		set_pev(entid, pev_effects, pev(entid, pev_effects) & EF_NODRAW)
	
		new arrParams[3]
		arrParams[0] = entid // item id
		arrParams[1] = 0     // attempt nr.0
		arrParams[2] = true  // init bounding box
		set_task(0.2, "taskMaterialize", entid, arrParams, sizeof(arrParams))
	}
	else
	{
		new arrParams[3]
		arrParams[0] = entid // item id
		arrParams[1] = 0     // attempt nr.0
		arrParams[2] = true  // init bounding box
		set_task(0.2, "taskSetBoxSize", entid, arrParams, sizeof(arrParams))

		if (type <= 30)	// Is it a Weapon?
			set_pev(entid, pev_velocity,  Float:{0.0, 0.0, 0.0})
	}
	return entid
}

//-----------------------------------------------------------------------------
// Simon Logic: i moved common parts of code into one function; also
// see req#367
public removeRespawnableItem(id)
{
	if (!g_bPersistentItems)
	{
		static item_id; item_id = g_EntTable[id]

		engfunc(EngFunc_RemoveEntity, id)
		g_EntId[item_id] = 0
		g_EntTable[id] = -1

		new arr[1]; arr[0] = item_id
		set_task(g_itemTime, "taskReplenish", _, arr, sizeof(arr))
	}
	else
	{
		new arrParams[3]
		new Float:vecOrigin[3]
	
		set_pev(id, pev_effects, EF_NODRAW | pev(id, pev_effects))
		// disable call of touch function for this entity
		set_pev(id, pev_solid, SOLID_NOT)
		pev(id, pev_origin, vecOrigin)
		engfunc(EngFunc_SetOrigin, id, vecOrigin)
    
		arrParams[0] = id
		arrParams[1] = 0
		arrParams[2] = false
		set_task(g_itemTime, "taskMaterialize", id, arrParams, sizeof(arrParams))
	}
}

public hook_touch(ptr, ptd)
{
	static item_type
	static ammo_via_offset

	if (!csdm_active())
		return FMRES_HANDLED

	if (!g_Enabled)
		return FMRES_HANDLED

	if (g_EntTable[ptr] < 0)
		return FMRES_HANDLED

	if (ptd < 1 || ptd > g_MaxPlayers)
		return FMRES_HANDLED

	if (!is_user_connected(ptd))
		return FMRES_HANDLED

// Simon Logic start
	if(!(pev(ptr, pev_movetype) & MOVETYPE_TOSS)) // ignore entities with "wrong" physics
		return FMRES_IGNORED
	if(pev(ptr, pev_effects) & EF_NODRAW) // ignore invisible entities
		return FMRES_IGNORED
	if(pev(ptr, pev_solid) & SOLID_BSP) // ignore elevators, walls etc.
		return FMRES_IGNORED
	if (g_EntTable[ptr] < 0)
		return FMRES_IGNORED
	if(pev(ptd, pev_deadflag) != DEAD_NO) // ignore dead players
		return FMRES_IGNORED
// Simon Logic end

//	new item_id[1], item_type

//	item_id[0] = g_EntTable[ptr]
	item_type = (g_EntTable[ptr] < MAX_ITEMS) ? g_EntType[g_EntTable[ptr]] : g_EntTable[ptr]

	// Death Pack
	if (item_type > ITEM_PACK)
	{
		new packid = item_type - ITEM_PACK
		new maxiter = g_PackContents[packid][SLOT_WP_COUNT] + SLOTS_AUX

		new weap, weapname[24]

		if(g_droppacks == DROP_CS_PACK)
		{
			giveItemBattery(ptd, false)
			giveItemMedkit(ptd, false)
		}

		emit_sound(ptd, CHAN_ITEM, "items/ammopickup2.wav", 0.85, ATTN_NORM, 0, 150)

		// NOTE: when weapon is disappead on drop it can be packed into 
		// death pack; otherwise only ammo & grenades will be packed, because
		// active weapon is dropped on death
		
		// TODO: what about another weapons in backpack? currently they just
		// disappear if [weapons_stay] <> 0

		if(!g_iCfgWeaponStayTime)
		{   // give weapons, ammo & grenades
			for (new i = SLOTS_AUX; i < maxiter; i++)
			{
				weap = g_PackContents[packid][i]
				if(!weap || weap == CSW_C4)
					continue

				if(CanGetWeapon(ptd, weap, ammo_via_offset))
				{
					if(ammo_via_offset)
						giveWeaponAgain(ptd, weap, ammo_via_offset)
					else {
						get_weaponname(weap, weapname, sizeof(weapname)-1)
						csdm_give_item(ptd, weapname)
					}
				}
				else
					GiveAmmo(ptd, g_Weap2Ammo[weap])
			}
		}
		else
		{   // give ammo & grenades only (no weapons!)
			for(new i=SLOTS_AUX; i<maxiter; i++)
			{
				weap = g_PackContents[packid][i]
				if(!weap || weap == CSW_C4)
					continue

				if(isGrenadeItem(weap))
				{
					if(CanGetWeapon(ptd, weap, ammo_via_offset))
					{
						if(ammo_via_offset)
							giveWeaponAgain(ptd, weap, ammo_via_offset)
						else {
							get_weaponname(weap, weapname, sizeof(weapname)-1)
							csdm_give_item(ptd, weapname)
						}
					}
				}
				else
					GiveAmmo(ptd, g_Weap2Ammo[weap])
			}
		}

		if(g_PackContents[packid][SLOT_LONGJUMP] == ITEM_LONGJUMP && !HasLongJump[ptd])
		{
			csdm_give_item(ptd, "item_longjump")
			HasLongJump[ptd] = true
			printLongJumpHelp(ptd)
		}

		remove_task(ptr)
		engfunc(EngFunc_RemoveEntity, ptr)
		g_EntTable[ptr] = -1
		g_PackID[packid] = true
		ZeroPack(packid)

		return FMRES_HANDLED
	}	
	switch(item_type)
	{
		case ITEM_PISTOLAMMO..ITEM_PARAAMMO: { // Ammo
			if (CanGetAmmo(ptd, item_type))
			{
				GiveAmmo(ptd, item_type)
				removeRespawnableItem(ptr)
			}
		}

		case 1..30: { // Weapon
			if(CanGetWeapon(ptd, item_type, ammo_via_offset))
			{
				new weapname[24]

				get_weaponname(item_type, weapname, 23)
				if(ammo_via_offset)
					giveWeaponAgain(ptd, item_type, ammo_via_offset)
				else
					csdm_give_item(ptd, weapname)
				removeRespawnableItem(ptr)
			}
			else if(user_has_weapon(ptd, item_type) && CanGetAmmo(ptd, g_Weap2Ammo[item_type]))
			{	// Simon Logic: req#342

//    			server_print("[CSDM_DEBUG] player[%d] got weapon[%d] as ammo bonus", ptd, item_type)

				GiveAmmo(ptd, g_Weap2Ammo[item_type])
				removeRespawnableItem(ptr)
			}
		}

		case ITEM_BATTERY: { // Battery
			if (giveItemBattery(ptd))
			{
				removeRespawnableItem(ptr)
			}
		}

		case ITEM_MEDKIT: { // Medkit
			if (giveItemMedkit(ptd))
			{
				removeRespawnableItem(ptr)
			}
		}

		case ITEM_ARMOR: { // Armor
			if (get_user_armor(ptd) < 100)
			{
				csdm_give_item(ptd, "item_assaultsuit")
				removeRespawnableItem(ptr)
			}
		}

		case ITEM_FULLAMMO: { // Full Ammo
			if (CanGetAmmo(ptd, ITEM_PISTOLAMMO) || CanGetAmmo(ptd, ITEM_RIFLEAMMO) || CanGetAmmo(ptd, ITEM_SHOTAMMO) || CanGetAmmo(ptd, ITEM_SMGAMMO)
				|| CanGetAmmo(ptd, ITEM_AWPAMMO) || CanGetAmmo(ptd, ITEM_PARAAMMO))
			{
				GiveAmmo(ptd, ITEM_PISTOLAMMO)
				GiveAmmo(ptd, ITEM_RIFLEAMMO)
				GiveAmmo(ptd, ITEM_SHOTAMMO)
				GiveAmmo(ptd, ITEM_SMGAMMO)
				GiveAmmo(ptd, ITEM_AWPAMMO)
				GiveAmmo(ptd, ITEM_PARAAMMO)
				removeRespawnableItem(ptr)
			}
		}

		case ITEM_LONGJUMP: { // Longjump
			if (!HasLongJump[ptd])
			{
				csdm_give_item(ptd, "item_longjump")
				HasLongJump[ptd] = true
				emit_sound(ptd, CHAN_ITEM, "items/clipinsert1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				removeRespawnableItem(ptr)
				printLongJumpHelp(ptd)
			}
		}
	}

	return FMRES_HANDLED
}

//-----------------------------------------------------------------------------
stock printLongJumpHelp(pid)
{
	if(g_bSkipHelp[pid]) return
	g_bSkipHelp[pid] = true
	client_print(pid, print_chat, "[CSDM] To use LongJump, press DUCK+JUMP while moving FORWARD!")
}

//-----------------------------------------------------------------------------

public taskReplenish(arr[1]) // item respawn
{	// NO STATIC VARS!
	new item_id; item_id = arr[0]

	g_EntId[item_id] = MakeEnt(item_id)
	if(g_EntId[item_id]) {
		// NOTE: original volume is 1.0, but for CS it's better to make it 
		// lower a bit
		emit_sound(g_EntId[item_id], CHAN_WEAPON, "items/suitchargeok1.wav", 0.85, ATTN_NORM, 0, 150)
	}
}

public taskMaterialize(arr[3]) // arr = [ent_id, attempt, set_bbox]
{   // NO STATIC VARS!
	new id; id = arr[0]
	new iTemp
	new Float:vecTemp[3]

	if(!pev_valid(id)) {
		// NOTE: this should not normally happen
		g_EntTable[id] = -1
		return
	}
			
	pev(id, pev_velocity, vecTemp)
	if(vecTemp[2]) { // item is still falling
		if(arr[1] >= MAX_MATERIALIZE_ATTEMPTS) {
			// kill item
			engfunc(EngFunc_RemoveEntity, id)
			g_EntTable[id] = -1
		} else {
			// SetThink emulation...
			arr[1]++
			set_task(0.2, "taskMaterialize", id, arr, sizeof(arr))
		}
		return
	}

	iTemp = pev(id, pev_effects)
	if(iTemp & EF_NODRAW || pev(id, pev_solid) == SOLID_NOT) {
		// changing from invisible state to visible
		emit_sound(id, CHAN_WEAPON, "items/suitchargeok1.wav", 0.85, ATTN_NORM, 0, 150)
		iTemp &= ~EF_NODRAW
		iTemp |= EF_MUZZLEFLASH
		set_pev(id, pev_effects, iTemp)
		set_pev(id, pev_solid, SOLID_TRIGGER)
		// activate solidness
		pev(id, pev_origin, vecTemp)
		engfunc(EngFunc_SetOrigin, id, vecTemp)
    }
	
	// NOTE: on round start EF_NODRAW or SOLID_NO can be forced to reset
	// for each entity :(
	
	if(arr[2])
		setEntityBoxSize(id, g_EntType[g_EntTable[id]])
}

public taskSetBoxSize(arr[3]) // arr = [ent_id, attempt, set_bbox]
{
	new id; id = arr[0]
	new Float:vecTemp[3]

	if(!pev_valid(id)) {
		// NOTE: this should not normally happen
		g_EntTable[id] = -1
		return
	}
			
	pev(id, pev_velocity, vecTemp)
	if(vecTemp[2]) { // item is still falling
		if(arr[1] >= MAX_MATERIALIZE_ATTEMPTS) {
			// kill item
			engfunc(EngFunc_RemoveEntity, id)
			g_EntTable[id] = -1
		} else {
			// SetThink emulation...
			arr[1]++
			set_task(0.2, "taskSetBoxSize", id, arr, sizeof(arr))
		}
		return
	}

	
	if(arr[2])
		setEntityBoxSize(id, g_EntType[g_EntTable[id]])
}

/*
public Replenish(item_id[])
{
	g_EntId[item_id[0]] = MakeEnt(item_id[0])
	emit_sound(g_EntId[item_id[0]], CHAN_ITEM, "items/suitchargeok1.wav", 0.85, ATTN_NORM, 0, 150)
}
*/

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled || !csdm_active())
		return

	if (HasLongJump[victim])
		HasLongJump[victim] = false
}

public csdm_RoundRestart()
{
	if ((!g_Enabled) || !csdm_active())
		return

	new players[32], num, player

	get_players(players, num)

	for (new i = 0; i < num; i++)
	{
		player = players[i]
		
		if (HasLongJump[player] && is_user_alive(player))
			csdm_give_item(player, "item_longjump")
	}

	destroyAllPacks()
	destroyAllItems(false)
	SetEnts()
}

public csdm_PreDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled || !g_droppacks || !csdm_active())
		return

	new packid = GetPackId()
	if (packid < 0)
		return

	new entid = CreateEntId()
	if (!entid) 
	{
		g_PackID[packid] = true
		return
	}

	new Float:vecPos[3], Float:vecVel[3]//, Orig[3]

	//get_user_origin(victim, Orig) // Simon Logic: this is lame function =)
	//IVecFVec(Orig, Pos)
	pev(victim, pev_origin, vecPos)
	pev(victim, pev_velocity, vecVel)

	g_EntTable[entid] = ITEM_PACK + packid

	set_pev(entid, pev_classname, "csdm_deathpack")
	engfunc(EngFunc_SetModel, entid, "models/w_weaponbox.mdl")
	set_pev(entid, pev_solid, SOLID_TRIGGER)
	set_pev(entid, pev_movetype, MOVETYPE_TOSS)
	set_pev(entid, pev_owner, victim)

	//set_pev(entid, pev_origin, Pos)
	engfunc(EngFunc_SetOrigin, entid, vecPos)
	
	// NOTE: this is against CWeaponBox::Spawn() but it's still proper
	setEntityBoxSize(entid, ITEM_PACK)
	
	// Simon Logic: stolen from CBasePlayer::PackDeadPlayerItems(), also
	// this is req#351
	vecVel[0] *= 1.2 
	vecVel[1] *= 1.2
	vecVel[2] *= 1.2
	set_pev(entid, pev_velocity, vecVel)

	new Weapons[32], weapnum = 0
	get_user_weapons(victim, Weapons, weapnum)

	// TODO: pack exact amount of bullets instead of weapons

	// NOTE: first 4 elements are system:
	// [0]=weapon_count [1]=entid [2]=packid [3]=longjump
	for(new i=0; i<weapnum; i++)
	{
		g_PackContents[packid][i + SLOTS_AUX] = Weapons[i]
	}

	if (HasLongJump[victim])
	{
		g_PackContents[packid][SLOT_LONGJUMP] = ITEM_LONGJUMP
	}

	g_PackContents[packid][SLOT_WP_COUNT] = weapnum
	g_PackContents[packid][SLOT_ENT_ID] = entid
	g_PackContents[packid][SLOT_PACK_ID] = packid

	new info[2]
	info[0] = entid
	info[1] = packid
	set_task(g_packTime, "DeletePack", entid, info, sizeof(info))
}


public DeletePack(pack_info[])
{
	new packid = pack_info[1]
	new entid = pack_info[0]
	
	if (pev_valid(entid))
		engfunc(EngFunc_RemoveEntity, entid)
	g_PackID[packid] = true // set slot to free
	g_EntTable[entid] = -1
	ZeroPack(packid)
}

GetPackId()
{
	for (new i = 1; i < MAX_PACKS; i++)
	{
		if (g_PackID[i])
		{
			g_PackID[i] = false
			return i
		}
	}

	return -1
}

ZeroPack(packid)
{
	arrayset(g_PackContents[packid], 0, SLOTS)
}

/*
public csdm_HandleDrop(id, weapon, death)
{
	return (g_Enabled && g_droppacks && csdm_active()) ? CSDM_DROP_REMOVE : CSDM_DROP_CONTINUE
}
*/

bool:CanGetAmmo(id, ammotype)
{
	switch (ammotype)
	{
		case ITEM_PISTOLAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_DEAGLE) < g_MaxBPAmmo[CSW_DEAGLE])
				return true
			if (cs_get_user_bpammo(id, CSW_P228) < g_MaxBPAmmo[CSW_P228])
				return true
			if (cs_get_user_bpammo(id, CSW_USP) < g_MaxBPAmmo[CSW_USP])
				return true
			if (cs_get_user_bpammo(id, CSW_GLOCK18) < g_MaxBPAmmo[CSW_GLOCK18])
				return true
			if (cs_get_user_bpammo(id, CSW_FIVESEVEN) < g_MaxBPAmmo[CSW_FIVESEVEN])
				return true
		}
		case ITEM_SHOTAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_XM1014) < g_MaxBPAmmo[CSW_XM1014])
				return true
		}
		case ITEM_RIFLEAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_M4A1) < g_MaxBPAmmo[CSW_M4A1])
				return true
			if (cs_get_user_bpammo(id, CSW_AK47) < g_MaxBPAmmo[CSW_AK47])
				return true
		}
		case ITEM_SMGAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_MP5NAVY) < g_MaxBPAmmo[CSW_MP5NAVY])
				return true
			if (cs_get_user_bpammo(id, CSW_MAC10) < g_MaxBPAmmo[CSW_MAC10])
				return true
			if (cs_get_user_bpammo(id, CSW_P90) < g_MaxBPAmmo[CSW_P90])
				return true
		}
		case ITEM_AWPAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_AWP) < g_MaxBPAmmo[CSW_AWP])
				return true
		}
		case ITEM_PARAAMMO:
		{
			if (cs_get_user_bpammo(id, CSW_M249) < g_MaxBPAmmo[CSW_M249])
				return true
		}
	}
	
	return false
}

// Simon Logic - TODO: implement amount argument to give exact number of bullets
GiveAmmo(id, ammotype, amount=-1)
{
	if(amount < 0)
	{
		switch (ammotype)
		{
			case ITEM_PISTOLAMMO:
			{
				csdm_give_item(id, "ammo_357sig")
				csdm_give_item(id, "ammo_57mm")
				csdm_give_item(id, "ammo_45acp")
				csdm_give_item(id, "ammo_50ae")
				csdm_give_item(id, "ammo_9mm")
			}
			case ITEM_SHOTAMMO:
			{
				csdm_give_item(id, "ammo_buckshot")
			}
			case ITEM_RIFLEAMMO:
			{
				csdm_give_item(id, "ammo_762nato")
				csdm_give_item(id, "ammo_556nato")
			}
			case ITEM_SMGAMMO:
			{
				csdm_give_item(id, "ammo_9mm")
				csdm_give_item(id, "ammo_45acp")
				csdm_give_item(id, "ammo_57mm") // P90 needs it...
			}
			case ITEM_AWPAMMO:
			{
				csdm_give_item(id, "ammo_338magnum")
			}
			case ITEM_PARAAMMO:
			{
				csdm_give_item(id, "ammo_556natobox")
			}
		}
	}
	else if(amount > 0)
	{
    	// TODO: implement "amount" param
    	switch(ammotype)
    	{
    		case ITEM_PISTOLAMMO:
    		{
    		}
    		case ITEM_SHOTAMMO:
    		{
    		}
    		case ITEM_RIFLEAMMO:
    		{
    		}
    		case ITEM_SMGAMMO:
    		{
    		}
    		case ITEM_AWPAMMO:
    		{
    		}
    		case ITEM_PARAAMMO:
    		{
    		}
    	}
	}
}

// Simon Logic: added argument ammo_via_offset, which gets a value when user
// can get this weapon but it should be given via offset & not via give_xxx();
// this value may be filled for grenades only
bool:CanGetWeapon(id, wid, &ammo_via_offset)
{
	new slot = g_WeaponSlots[wid]

	ammo_via_offset = 0

	if(slot == 4) // grenade slot
	{
		new ammo; ammo = cs_get_user_bpammo(id, wid)
		switch(wid)
		{
			case CSW_HEGRENADE: {
				if(ammo >= g_iMaxNadesH)
					return false
				if(ammo >= g_MaxBPAmmo[CSW_HEGRENADE])
					ammo_via_offset = ammo + 1
			}
			case CSW_SMOKEGRENADE: {
				if(ammo >= g_iMaxNadesS)
					return false
				if(ammo >= g_MaxBPAmmo[CSW_SMOKEGRENADE])
					ammo_via_offset = ammo + 1
			}
			case CSW_FLASHBANG: {
				if(ammo >= g_iMaxNadesF)
					return false
				if(ammo >= g_MaxBPAmmo[CSW_FLASHBANG])
					ammo_via_offset = ammo + 1
			}
		}
	}
	else
	{
		new Weapons[MAX_WEAPONS], num
		
		get_user_weapons(id, Weapons, num)
		
		for(new i = 0; i < num; i++)
		{   // NOTE: player can have only one weapon per slot
			if (g_WeaponSlots[Weapons[i]] == slot)
				return false
			/*if(i == wid)
				return false*/
		}
	}
	return true
}

destroyAllItems(bool:mapchange = true)
{
	new iter, entid

	// abort any respawn task to avoid double respawns on plugin reload
	if (task_exists())
		remove_task()

	// destroy all items
	for (iter = 0; iter < MAX_ITEMS; iter++)
	{
		entid = g_EntId[iter]
		if (pev_valid(entid))
		{
			if ((g_bPersistentItems) && (task_exists(entid)))
			{
				remove_task(entid)
			}
			engfunc(EngFunc_RemoveEntity, entid)
		}
	}

	arrayset(g_EntId, 0, MAX_ITEMS)
	arrayset(g_EntTable, -1, MAX_ENTS)
	arrayset(g_Ent, -1, sizeof(g_Ent))

	if (mapchange)
		arrayset(g_EntType, 0, MAX_ITEMS)
}

destroyAllPacks()
{
	new packid, entid	

	for (new i = 1; i < MAX_PACKS; i++)
	{
		if (g_PackContents[i][0])
		{
			entid = g_PackContents[i][1]
			packid = g_PackContents[i][2]

			if (pev_valid(entid))
				engfunc(EngFunc_RemoveEntity, entid)

			remove_task(packid)

			ZeroPack(packid)
		}
	}

	arrayset(g_PackID, true, MAX_PACKS)
}

stock getWeapId(wp[])
{
	if (equali(wp, "weapon_p228")) {
		return CSW_P228
	} else if (equali(wp, "weapon_scout")) {
		return CSW_SCOUT
	} else if (equali(wp, "weapon_hegrenade")) {
		return CSW_HEGRENADE
	} else if (equali(wp, "weapon_xm1014")) {
		return CSW_XM1014
	} else if (equali(wp, "weapon_c4")) {
		return CSW_C4
	} else if (equali(wp, "weapon_mac10")) {
		return CSW_MAC10
	} else if (equali(wp, "weapon_aug")) {
		return CSW_AUG
	} else if (equali(wp, "weapon_smokegrenade")) {
		return CSW_SMOKEGRENADE
	} else if (equali(wp, "weapon_elite")) {
		return CSW_ELITE
	} else if (equali(wp, "weapon_fiveseven")) {
		return CSW_FIVESEVEN
	} else if (equali(wp, "weapon_ump45")) {
		return CSW_UMP45
	} else if (equali(wp, "weapon_sg550")) {
		return CSW_SG550
	} else if (equali(wp, "weapon_galil")) {
		return CSW_GALIL
	} else if (equali(wp, "weapon_famas")) {
		return CSW_FAMAS
	} else if (equali(wp, "weapon_usp")) {
		return CSW_USP
	} else if (equali(wp, "weapon_glock18")) {
		return CSW_GLOCK18
	} else if (equali(wp, "weapon_awp")) {
		return CSW_AWP
	} else if (equali(wp, "weapon_mp5navy")) {
		return CSW_MP5NAVY
	} else if (equali(wp, "weapon_m249")) {
		return CSW_M249
	} else if (equali(wp, "weapon_m3")) {
		return CSW_M3
	} else if (equali(wp, "weapon_m4a1")) {
		return CSW_M4A1
	} else if (equali(wp, "weapon_tmp")) {
		return CSW_TMP
	} else if (equali(wp, "weapon_g3sg1")) {
		return CSW_G3SG1
	} else if (equali(wp, "weapon_flashbang")) {
		return CSW_FLASHBANG
	} else if (equali(wp, "weapon_deagle")) {
		return CSW_DEAGLE
	} else if (equali(wp, "weapon_sg552")) {
		return CSW_SG552
	} else if (equali(wp, "weapon_ak47")) {
		return CSW_AK47
	} else if (equali(wp, "weapon_knife")) {
		return CSW_KNIFE
	} else if (equali(wp, "weapon_p90")) {
		return CSW_P90
	}
	
	return 0
}

//-----------------------------------------------------------------------------
// Simon Logic's stocks
//-----------------------------------------------------------------------------
stock assignMaxNades(&var, val[], wid)
{
	var = str_to_num(val)
	if(var > MAX_GRENADES)
		var = MAX_GRENADES
	else if(var < 0)
		var = g_MaxBPAmmo[wid]
}
//-----------------------------------------------------------------------------
stock setEntityBoxSize(ent_id, type)
{
#if defined _ASSERT	
	assert 0 <= type <= ITEM_PACK
#endif
	if(type <= 30 && !isGrenadeItem(type))
	{	// it's a weapon
		engfunc(EngFunc_SetSize, ent_id, {-24.0, -24.0, 0.0}, {24.0, 24.0, 16.0})
	}
	else
		engfunc(EngFunc_SetSize, ent_id, {-16.0, -16.0, 0.0}, {16.0, 16.0, 16.0})
}
//-----------------------------------------------------------------------------
stock bool:isGrenadeItem(w_id)
{
#if defined _ASSERT	
	assert 0 <= w_id <= 30
#endif
	return w_id == CSW_HEGRENADE || w_id == CSW_SMOKEGRENADE || w_id == CSW_FLASHBANG
}
//-----------------------------------------------------------------------------
stock sendItemPickupMsg(id, const item_name[])
{
	message_begin(MSG_ONE, g_msgItemPickup, _, id)
	write_string(item_name)
	message_end()
}
//-----------------------------------------------------------------------------
stock bool:isWeapon(ent_id) // actually is a weaponbox
{
	static sBuffer[11] // sizeof("weaponbox") + 1
	
	pev(ent_id, pev_classname, sBuffer, sizeof(sBuffer)-1)
	
	return bool:equal(sBuffer, "weaponbox")
}
//-----------------------------------------------------------------------------
stock bool:giveItemBattery(ptd, full_ack = true)
{
	static value
	
	value = get_user_armor(ptd)
	
	if(value >= 100)
		return false
	
	value += g_battery
	if(value > 100)
		value = 100
	
	set_pev(ptd, pev_armorvalue, float(value))

	if (!is_user_bot(ptd))
		sendItemPickupMsg(ptd, "item_battery")

	if(full_ack) {
		emit_sound(ptd, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	return true
}
//-----------------------------------------------------------------------------
stock bool:giveItemMedkit(ptd, full_ack = true)
{
	static Float:fValue, Float:fMaxHealth

	pev(ptd, pev_max_health, fMaxHealth)
	
	fValue = float(get_user_health(ptd))
	if(fValue >= fMaxHealth)
		return false
	 
	fValue += g_medkit
	if(fValue > fMaxHealth)
		fValue = fMaxHealth

	set_pev(ptd, pev_health, fValue)

	if (!is_user_bot(ptd))
		sendItemPickupMsg(ptd, "item_healthkit")

	if(full_ack) {
		emit_sound(ptd, CHAN_ITEM, "items/smallmedkit1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	return true
}
//-----------------------------------------------------------------------------
stock giveWeaponAgain(ptd, item_id, ammo) // grenades supported only
{
#if defined _ASSERT	
	assert 0 <= item_id <= 30
#endif
	cs_set_user_bpammo(ptd, item_id, ammo)
	if (is_user_bot(ptd))
		return
	switch(item_id)
	{
		case CSW_HEGRENADE: {
			message_begin(MSG_ONE, g_msgAmmoPickup, _, ptd)
			write_byte(12)
			write_byte(1)
			message_end()
		}
		case CSW_SMOKEGRENADE: {
			message_begin(MSG_ONE, g_msgAmmoPickup, _, ptd)
			write_byte(13)
			write_byte(1)
			message_end()
		}			
		case CSW_FLASHBANG: {
			message_begin(MSG_ONE, g_msgAmmoPickup, _, ptd)
			write_byte(11)
			write_byte(1)
			message_end()
		}
	}
	
	emit_sound(ptd, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
//-----------------------------------------------------------------------------
// Simon Logic: seems not used here
stock bool:HasWeapon(id, wid) // check if player already has a weapon
{
	new i, Weapons[MAX_WEAPONS], num

	get_user_weapons(id, Weapons, num)
	for(i=0; i<num && Weapons[i]!=wid; i++) {}
	
	return (i != num)
}
//-----------------------------------------------------------------------------


// The main part of Item Editor - some code had to be changed also above...

buildMenu()
{
// Create Menu
	g_MainMenuID = menu_create(g_MainMenu, "m_MainHandler")

//Menu Callbacks
	g_cMain = menu_makecallback("c_Main")

	menu_additem(g_MainMenuID, "Add a CSDM Item","1", 0, g_cMain)
	menu_additem(g_MainMenuID, "Edit closest Item (yellow) to Current Position","2", 0, g_cMain)
	menu_additem(g_MainMenuID, "Delete closest Item","3", 0, g_cMain)
	menu_additem(g_MainMenuID, "Refresh closest item", "4", 0, g_cMain)
	menu_additem(g_MainMenuID, "Show item statistics", "5", 0, -1)
	menu_additem(g_MainMenuID, "Dump a text file with entity information","6", 0, g_cMain)
	menu_additem(g_MainMenuID, "Back", "7", 0, -1)

//Add Items Menu
	g_AddItemsMenuID = menu_create(g_AddItemsMenu, "m_AddItemsHandler")
	g_cAddItems = menu_makecallback("c_AddItems")

	menu_additem(g_AddItemsMenuID, "Add Pistol","1", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Add Sub Machine Gun","2", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Add Rifle (1)","3", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Add Rifle (2)","4", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Add Shotgun/Machine gun","5", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Add Equipement","6", 0, g_cAddItems)
	menu_additem(g_AddItemsMenuID, "Back","7", 0, -1)

//Add Pistols Menu
	g_AddPistolsMenuID = menu_create(g_AddPistolsMenu, "m_AddPistolsHandler")
	g_cAddPistols = menu_makecallback("c_AddPistols")

	menu_additem(g_AddPistolsMenuID, "Add glock18","1", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add usp","2", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add elite","3", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add fiveseven","4", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add p228","5", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add deagle","6", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Add pistol ammo","7", 0, g_cAddPistols)
	menu_additem(g_AddPistolsMenuID, "Back","8", 0, -1)
	menu_setprop(g_AddPistolsMenuID, MPROP_PERPAGE, 0)

//Add SMG Menu
	g_AddSmgMenuID = menu_create(g_AddSmgMenu, "m_AddSmgHandler")
	g_cAddSmg = menu_makecallback("c_AddSmg")

	menu_additem(g_AddSmgMenuID, "Add p90","1", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Add tmp","2", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Add ump45","3", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Add mac10","4", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Add mp5navy","5", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Add smg ammo","6", 0, g_cAddSmg)
	menu_additem(g_AddSmgMenuID, "Back","7", 0, -1)
	menu_setprop(g_AddSmgMenuID, MPROP_PERPAGE, 0)

//Add Rifles(1) Menu
	g_AddRifles1MenuID = menu_create(g_AddRifles1Menu, "m_AddRifles1Handler")
	g_cAddRifles1 = menu_makecallback("c_AddRifles1")

	menu_additem(g_AddRifles1MenuID, "Add ak47","1", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add m4a1","2", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add aug","3", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add sg552","4", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add scout","5", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add sg550","6", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Add rifle ammo","7", 0, g_cAddRifles1)
	menu_additem(g_AddRifles1MenuID, "Back","8", 0, -1)
	menu_setprop(g_AddRifles1MenuID, MPROP_PERPAGE, 0)

//Add Rifles(2) Menu
	g_AddRifles2MenuID = menu_create(g_AddRifles2Menu, "m_AddRifles2Handler")
	g_cAddRifles2 = menu_makecallback("c_AddRifles2")

	menu_additem(g_AddRifles2MenuID, "Add g3sg1","1", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Add galil","2", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Add famas","3", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Add rifle ammo","4", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Add awp","5", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Add awp ammo","6", 0, g_cAddRifles2)
	menu_additem(g_AddRifles2MenuID, "Back","7", 0, -1)
	menu_setprop(g_AddRifles2MenuID, MPROP_PERPAGE, 0)

//Add Shotgun/Machine gun Menu
	g_AddShotgunMenuID = menu_create(g_AddShotgunMenu, "m_AddShotgunHandler")
	g_cAddShotgun = menu_makecallback("c_AddShotgun")

	menu_additem(g_AddShotgunMenuID, "Add xm1014","1", 0, g_cAddShotgun)
	menu_additem(g_AddShotgunMenuID, "Add m3","2", 0, g_cAddShotgun)
	menu_additem(g_AddShotgunMenuID, "Add shotgun ammo","3", 0, g_cAddShotgun)
	menu_additem(g_AddShotgunMenuID, "Add m249","4", 0, g_cAddShotgun)
	menu_additem(g_AddShotgunMenuID, "Add para ammo","5", 0, g_cAddShotgun)
	menu_additem(g_AddShotgunMenuID, "Back","6", 0, -1)
	menu_setprop(g_AddShotgunMenuID, MPROP_PERPAGE, 0)

//Add Equipement Menu
	g_AddEquipMenuID = menu_create(g_AddEquipMenu, "m_AddEquipHandler")
	g_cAddEquip = menu_makecallback("c_AddEquip")

	menu_additem(g_AddEquipMenuID, "Add longjump","1", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add healthkit","2", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add armor","3", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add battery","4", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add full ammo","5", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add hegrenade","6", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add flashbang","7", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Add smokegrenade","8", 0, g_cAddEquip)
	menu_additem(g_AddEquipMenuID, "Back","9", 0, -1)
	menu_setprop(g_AddEquipMenuID, MPROP_PERPAGE, 0)
}

public m_MainHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
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
			menu_display(id, g_AddItemsMenuID, 0)
		}
		case 2:
		{
			new Float:vecs[3], vec[3]
			new Float:angles[3], angle[3]
			new angle_y
			pev(id, pev_origin, vecs)
			FVecIVec(vecs,vec)
			pev(id, pev_v_angle, angles)
			FVecIVec(angles,angle)
			angle_y = angle[1]
			if (g_Ent[id] > -1)
				edit_item(vec, g_Ent[id], angle_y)
			menu_display(id, g_MainMenuID, 0)
		}
		case 3:
		{
			new iorg[3]
			get_user_origin(id, iorg)
			new distance = get_distance(iorg, g_EntVecs[g_Ent[id]])					
			if ((distance <= 200) && (g_Ent[id] > -1))
			{
				ent_unglow(g_Ent[id])
				delete_item(g_Ent[id])
				g_Ent[id] = closest_item(id)
				if (g_Ent[id] > -1)
					ent_glow(g_Ent[id],yellow)
			}
			menu_display(id, g_MainMenuID, 0)				
		}
		case 4:
		{
			if (g_Ent[id] > -1)
				ent_unglow(g_Ent[id])
			g_Ent[id] = closest_item(id)
			if (g_Ent[id] > -1)
			{
				ent_glow(g_Ent[id],yellow)
				client_print(id, print_chat, "The closest item: number %d , def: classname = %s, org[%d,%d,%d]", 
					g_Ent[id] + 1, g_EntClass[g_EntType[g_Ent[id]]], g_EntVecs[g_Ent[id]][0], g_EntVecs[g_Ent[id]][1], g_EntVecs[g_Ent[id]][2])
			}
			else if (g_EntCount == 0)
			{
				client_print(id, print_chat, "There is no item defined yet - nothing to mark.")
			}
			menu_display(id, g_MainMenuID, 0)
		}
		case 5:
		{	
			new Float:Org[3]
			pev(id, pev_origin, Org)

			client_print(id,print_chat,"Total Items: %d;^nCurrent Origin: X: %f  Y: %f  Z: %f",
				g_EntCount, Org[0], Org[1], Org[2])
			menu_display(id, g_MainMenuID, 0)
		}
		case 6:
		{
			csdm_entdump(id)
			menu_display(id, g_MainMenuID, 0)
		}
		case 7:
		{
			destroyAllItems(false)
			menu_destroy(menu)	
// 		need switch back the item_mode to the state it was before starting item editor...
			g_EditorEnabled = false
			g_Enabled = g_OldStateItemMode
			if (g_Enabled)
			{
				ReadFile()
				if (csdm_active())
					SetEnts()
			}
			menu_display(id, csdm_main_menu(), 0)
		}
	}
	return PLUGIN_HANDLED
}

public c_Main(id, menu, item)
{
	if (item == MENU_EXIT) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
		
	switch(num)
	{
		case	1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Items - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add a CSDM Item")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case	2:
		{
			if (g_EntCount < 1)
			{
				format(fItem,325,"Edit Items - No items")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else if (g_Ent[id] == -1)
			{
				format(fItem,325,"Edit Item - No item marked")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Edit closest Item (yellow) to Current Position")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case	3:
		{
			if (g_EntCount < 1)
			{
				format(fItem,325,"Delete Item - No items")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else if (g_Ent[id] == -1)
			{
				format(fItem,325,"Delete Item - No item marked")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}			
			else
			{
				new iorg[3]
				get_user_origin(id, iorg)
				new distance = get_distance(iorg, g_EntVecs[g_Ent[id]])
					
				if (distance > 200)
				{
					format(fItem,325,"Delete Item - Marked item far away")
					menu_item_setname(menu, item, fItem )
					return ITEM_DISABLED
				}
				else
				{
					format(fItem,325,"Delete closest Item")
					menu_item_setname(menu, item, fItem )
					return ITEM_ENABLED
				}
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public m_AddItemsHandler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 7) 
	{
		menu_display (id, g_MainMenuID, 0)
		return PLUGIN_HANDLED
	}

	switch(iChoice)
	{
		case 1:
		{
			menu_display(id, g_AddPistolsMenuID, 0)
		}
		case 2:
		{
			menu_display(id, g_AddSmgMenuID, 0)
		}
		case 3:
		{
			menu_display(id, g_AddRifles1MenuID, 0)
		}
		case 4:
		{
			menu_display(id, g_AddRifles2MenuID, 0)
		}
		case 5:
		{
			menu_display(id, g_AddShotgunMenuID, 0)
		}
		case 6:
		{
			menu_display(id, g_AddEquipMenuID, 0)
		}
	}
	return PLUGIN_HANDLED
}

public c_AddItems(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Pistol - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Pistol")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Sub Machine Gun - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Sub Machine Gun")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Rifle (1) - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Rifle (1)")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Rifle (2) - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Rifle (2)")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Shotgun/Machine gun - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Shotgun/Machine gun")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add Equipement - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add Equipement")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add pistols
public m_AddPistolsHandler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 8) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "weapon_p228", angle_y)
		}
		case 2:
		{
			add_item(vec, "weapon_usp", angle_y)
		}
		case 3:
		{
			add_item(vec, "weapon_elite", angle_y)
		}
		case 4:
		{
			add_item(vec, "weapon_fiveseven", angle_y)
		}
		case 5:
		{
			add_item(vec, "weapon_p228", angle_y)
		}
		case 6:
		{
			add_item(vec, "weapon_deagle", angle_y)
		}
		case 7:
		{
			add_item(vec, "pistol_ammo", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddPistolsMenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddPistols(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add glock18 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add glock18")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add usp - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add usp")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add elite - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add elite")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add fiveseven - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add fiveseven")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add p228 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add p228")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add deagle - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add deagle")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 7:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add pistol ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add pistol ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add Smg

public m_AddSmgHandler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 7) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "weapon_p90", angle_y)
		}
		case 2:
		{
			add_item(vec, "weapon_tmp", angle_y)
		}
		case 3:
		{
			add_item(vec, "weapon_ump45", angle_y)
		}
		case 4:
		{
			add_item(vec, "weapon_mac10", angle_y)
		}
		case 5:
		{
			add_item(vec, "weapon_mp5navy", angle_y)
		}
		case 6:
		{
			add_item(vec, "smg_ammo", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddSmgMenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddSmg(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add p90 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add p90")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add tmp - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add tmp")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add ump45 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add ump45")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add mac10 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add mac10")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add mp5navy - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add mp5navy")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add smg ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add smg ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add rifles (1)

public m_AddRifles1Handler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 8) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "weapon_ak47", angle_y)
		}
		case 2:
		{
			add_item(vec, "weapon_m4a1", angle_y)
		}
		case 3:
		{
			add_item(vec, "weapon_aug", angle_y)
		}
		case 4:
		{
			add_item(vec, "weapon_sg552", angle_y)
		}
		case 5:
		{
			add_item(vec, "weapon_scout", angle_y)
		}
		case 6:
		{
			add_item(vec, "weapon_sg550", angle_y)
		}
		case 7:
		{
			add_item(vec, "rifle_ammo", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddRifles1MenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddRifles1(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add ak47 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add ak47")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add m4a1 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add m4a1")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add aug - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add aug")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add sg552 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add sg552")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add scout - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add scout")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add sg550 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add sg550")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 7:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add rifle ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add rifle ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add rifles (2)

public m_AddRifles2Handler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 7) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "weapon_g3sg1", angle_y)
		}
		case 2:
		{
			add_item(vec, "weapon_galil", angle_y)
		}
		case 3:
		{
			add_item(vec, "weapon_famas", angle_y)
		}
		case 4:
		{
			add_item(vec, "rifle_ammo", angle_y)
		}
		case 5:
		{
			add_item(vec, "weapon_awp", angle_y)
		}
		case 6:
		{
			add_item(vec, "awp_ammo", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddRifles2MenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddRifles2(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add g3sg1 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add g3sg1")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add galil - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add galil")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add famas - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add famas")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add rifle ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add rifle ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add awp - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add awp")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add awp ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add awp ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add shotgun / para

public m_AddShotgunHandler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback

	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 6) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "weapon_xm1014", angle_y)
		}
		case 2:
		{
			add_item(vec, "weapon_m3", angle_y)
		}
		case 3:
		{
			add_item(vec, "shotgun_ammo", angle_y)
		}
		case 4:
		{
			add_item(vec, "weapon_m249", angle_y)
		}
		case 5:
		{
			add_item(vec, "para_ammo", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddShotgunMenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddShotgun(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add xm1014 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add xm1014")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add m3 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add m3")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add shotgun ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add shotgun ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add m249 - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add m249")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add para ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add para ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}

// Add equipement

public m_AddEquipHandler(id, menu, item)
{
	if (item < 0) 
	{
		destroyAllItems(false)
		menu_destroy(menu)	
// 	need switch back the item_mode to the state it was before starting item editor...
		g_EditorEnabled = false
		g_Enabled = g_OldStateItemMode
		if (g_Enabled)
		{
			ReadFile()
			if (csdm_active())
				SetEnts()
		}
		return PLUGIN_HANDLED
	}

	// Get item info
	new cmd[6], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback)
	
	new iChoice = str_to_num(cmd)
	
	if (iChoice == 9) 
	{
		menu_display (id, g_AddItemsMenuID, 0)
		return PLUGIN_HANDLED
	}

	new Float:vecs[3], vec[3]
	new Float:angles[3], angle[3]
	new angle_y
	pev(id, pev_origin, vecs)
	FVecIVec(vecs,vec)
	pev(id, pev_v_angle, angles)
	FVecIVec(angles,angle)
	angle_y = angle[1]

	switch(iChoice)
	{
		case 1:
		{
			add_item(vec, "item_longjump", angle_y)
		}
		case 2:
		{
			add_item(vec, "item_healthkit", angle_y)
		}
		case 3:
		{
			add_item(vec, "armor", angle_y)
		}
		case 4:
		{
			add_item(vec, "item_battery", angle_y)
		}
		case 5:
		{
			add_item(vec, "full_ammo", angle_y)
		}
		case 6:
		{
			add_item(vec, "weapon_hegrenade", angle_y)
		}
		case 7:
		{
			add_item(vec, "weapon_flashbang", angle_y)
		}
		case 8:
		{
			add_item(vec, "weapon_smokegrenade", angle_y)
		}
	}

	if (g_EntCount < MAX_ITEMS)
		menu_display(id, g_AddEquipMenuID, 0)
	else
		menu_display(id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public c_AddEquip(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64]
	new access, callback
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback)
	
	new num = str_to_num(cmd)
	
	switch (num)
  {
		case 1:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add longjump - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add longjump")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 2:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add healthkit - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add healthkit")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 3:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add armor - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add armor")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 4:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add battery - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add battery")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 5:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add full ammo - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add full ammo")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 6:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add hegrenade - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add hegrenade")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 7:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add flashbang - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add flashbang")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
		case 8:
		{
			if (g_EntCount >= MAX_ITEMS)
			{
				format(fItem,325,"Add smokegrenade - Max Items Limit Reached")
				menu_item_setname(menu, item, fItem )
				return ITEM_DISABLED
			}
			else
			{
				format(fItem,325,"Add smokegrenade")
				menu_item_setname(menu, item, fItem )
				return ITEM_ENABLED
			}
		}
	}
	return PLUGIN_HANDLED
}


add_item(vec[3], EntName[25], angle = 0)
{
	new Map[32], config[32],  MapFile[256]
	
	get_mapname(Map, 31)
	get_configsdir(config, 31 )
	format(MapFile, 255, "%s\csdm\items\ents_%s.cfg",config, Map)

	new line[128]
	if(angle)
		format(line, 127, "%s %d %d %d %d", EntName, vec[0], vec[1], vec[2], angle)
	else
		format(line, 127, "%s %d %d %d", EntName, vec[0], vec[1], vec[2])


	write_file(MapFile, line, -1)
	
	// origin
	g_EntVecs[g_EntCount][0] = vec[0]
	g_EntVecs[g_EntCount][1] = vec[1]
	g_EntVecs[g_EntCount][2] = vec[2]
	g_EntAngle[g_EntCount] = angle 

	if (CWRAP(EntName, "item_longjump"))
		g_EntType[g_EntCount] = ITEM_LONGJUMP
	else if (CWRAP(EntName, "item_healthkit"))
		g_EntType[g_EntCount] = ITEM_MEDKIT
	else if (CWRAP(EntName, "item_battery"))
		g_EntType[g_EntCount] = ITEM_BATTERY
	else if (CWRAP(EntName, "pistol_ammo"))
		g_EntType[g_EntCount] = ITEM_PISTOLAMMO
	else if (CWRAP(EntName, "rifle_ammo"))
		g_EntType[g_EntCount] = ITEM_RIFLEAMMO
	else if (CWRAP(EntName, "shotgun_ammo"))
		g_EntType[g_EntCount] = ITEM_SHOTAMMO
	else if (CWRAP(EntName, "smg_ammo"))
		g_EntType[g_EntCount] = ITEM_SMGAMMO
	else if (CWRAP(EntName, "full_ammo"))
		g_EntType[g_EntCount] = ITEM_FULLAMMO
	else if (CWRAP(EntName, "armor"))
		g_EntType[g_EntCount] = ITEM_ARMOR
	else if (CWRAP(EntName, "awp_ammo"))
		g_EntType[g_EntCount] = ITEM_AWPAMMO
	else if (CWRAP(EntName, "para_ammo"))
		g_EntType[g_EntCount] = ITEM_PARAAMMO
	else
	{
		new weaptype = getWeapId(EntName)

		if (weaptype != 0)
			g_EntType[g_EntCount] = weaptype

	}
	g_EntId[g_EntCount] = MakeEnt(g_EntCount)

	g_EntCount++
}

edit_item(vec[3], ent, angle=0)
{
	new Map[32], config[32],  MapFile[256]

	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 255, "%s\csdm\items\ents_%s.cfg",config, Map)

	if (file_exists(MapFile)) 
	{
		new Data[124], len
		new line = 0
		new pos[3][8]
		new currentVec[3], newItem[128]
		new EntName[25]

		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 )
		{
			if (strlen(Data)<2) continue
			
			parse(Data, EntName, 24, pos[0], 7, pos[1], 7, pos[2], 7)
			currentVec[0] = str_to_num(pos[0])
			currentVec[1] = str_to_num(pos[1])
			currentVec[2] = str_to_num(pos[2])

			if ( (g_EntVecs[ent][0] == currentVec[0]) && (g_EntVecs[ent][1] == currentVec[1]) && ( (g_EntVecs[ent][2] - currentVec[2])<=20) )
			{	
				if(angle)
					format(newItem, 127, "%s %d %d %d %d", EntName, vec[0], vec[1], vec[2], angle)
				else
					format(newItem, 127, "%s %d %d %d", EntName, vec[0], vec[1], vec[2])

				write_file(MapFile, newItem, line-1)
// I need this because I couldn't prevent stay the moved item in the air (instead fall down at the ground)...
				destroyAllItems(false)
				ReadFile()
				SetEnts()

				ent_glow(ent,red)
				
				break
			}
		}
	}
}

delete_item(ent)
{
	new Map[32], config[32],  MapFile[256]
	
	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 255, "%s\csdm\items\ents_%s.cfg",config, Map)

	if (file_exists(MapFile)) 
	{
		new Data[124], len
		new line = 0
		new pos[3][8]
		new currentVec[3]
		new EntName[25]
		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue

			parse(Data, EntName, 24, pos[0], 7, pos[1], 7, pos[2], 7)

			currentVec[0] = str_to_num(pos[0])
			currentVec[1] = str_to_num(pos[1])
			currentVec[2] = str_to_num(pos[2])
			
			if ( (g_EntVecs[ent][0] == currentVec[0]) && (g_EntVecs[ent][1] == currentVec[1]) && ( (g_EntVecs[ent][2] - currentVec[2])<=20) )
			{
				write_file(MapFile, "", line-1)

				destroyAllItems(false)
				ReadFile()
				SetEnts()

				break
			}
		}
	}
}

closest_item(id)
{
	new origin[3]
	new lastDist = 999999
	new closest

	if (g_EntCount == 0)
		return -1

	get_user_origin(id, origin)
	for (new x = 0; x < g_EntCount; x++)
	{
		new distance = get_distance(origin, g_EntVecs[x])

		if (distance < lastDist)
		{
			lastDist = distance
			closest = x
		}
	}
	return closest
}


ent_glow(ent,Float:color[3])
{
	new iEnt = g_EntId[ent]
	
	if (iEnt)
	{
		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell)
		set_pev(iEnt, pev_renderamt, 255.0)
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha)
		set_pev(iEnt, pev_rendercolor, color) 
	}
}

ent_unglow(ent)
{
	new iEnt = g_EntId[ent]
	
	if (iEnt)
	{
		set_pev(iEnt, pev_renderfx, kRenderFxNone) 
		set_pev(iEnt, pev_renderamt, 255.0)
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha)		
	}
}

public showmen(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	g_EditorEnabled = true
	g_OldStateItemMode = g_Enabled
// need to disable temporary item_mode if it was enabled - to prevent have double entities, 
// to have the possibility edit also restricted items, to don't pickup added item etc...
	g_Enabled = false

	destroyAllItems(false)
	destroyAllPacks()
	buildMenu()
	ReadFile()
	SetEnts()
	menu_display (id, g_MainMenuID, 0)

	return PLUGIN_HANDLED
}

public csdm_entdump(id)
{
	if (!(get_user_flags(id)&ADMIN_MAP))
	{
		client_print(id, print_console, "[CSDM] You do not have appropriate access.")
		client_print(id, print_chat, "[CSDM] You do not have appropriate access.")
		return PLUGIN_HANDLED
	}

	new i
	new model[32]
	new owner
	new class[32]
	new Text[128]
	new entid
//	new pid, did

	if (g_EntCount == 0)
	{
		client_print(id, print_console, "[CSDM] Nothing to dump - no items defined.")
		client_print(id, print_chat, "[CSDM] Nothing to dump - no items defined.")
		return PLUGIN_HANDLED
	}

	log_to_file("csdm-ents.txt", "[CSDM] Entity dump output.")
//	for (i=s; i<=EF_NumberOfEntities(); i++)

	for (i=0; i<g_EntCount; i++)
	{
		entid = g_EntId[i]

		if (pev_valid(entid)) 
		{
			pev(entid, pev_classname, class, 31)
			pev(entid, pev_model, model, 31)
			owner =	pev(entid, pev_owner)
//			pid = findPackId(i)
//			did = findDrop(i)
			format(Text, 127, "[%d] (%d, %d) ^"%s^" ^"%s^"", i, entid, owner,
//pid, did, 
			class, model)
			write_file("addons\amxmodx\logs\csdm-ents.txt", Text, -1)
		}
	}
	client_print(id, print_chat, "[CSDM] The file with entities list created - addons\amx\logs\csdm-ents.txt")	
	return PLUGIN_HANDLED
}
