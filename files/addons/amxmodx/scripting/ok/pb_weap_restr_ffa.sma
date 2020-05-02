/* AMX Mod X
*   Plugin Restricting Weapons and Equipements for Podbot mm
*		It also checks the state FFA in CSDM 2.1 to set ffa for bots
* by KWo
*/


#include <amxmodx>
#include <amxmisc>

new Author[] = "KWo"
new Plugin[] = "Podbot mm Restrictions"
new Version[] = "1.3"


new g_szWeapRestr[27] = "00000000000000000000000000"
new g_szEquipAmmoRestr[10] = "000000000"

new g_szOldWeapRestr[27] = "00000000000000000000000000"
new g_szOldEquipAmmoRestr[10] = "000000000"
new g_szWeapRestrFixed[27] = "00000000000000000000000000"

new pv_amx_restrweapons
new pv_amx_restrequipammo
new pv_csdm_active
new pv_mp_freeforall

public check_restrictions()
{
	if (pv_amx_restrweapons)
		get_pcvar_string(pv_amx_restrweapons, g_szWeapRestr, 26)
	if (pv_amx_restrequipammo)
		get_pcvar_string(pv_amx_restrequipammo, g_szEquipAmmoRestr, 9)

	if (!equali(g_szWeapRestr, g_szOldWeapRestr))
	{
		format(g_szWeapRestrFixed, 26, g_szWeapRestr)
		g_szWeapRestrFixed[15] = g_szWeapRestr[17]
		g_szWeapRestrFixed[16] = g_szWeapRestr[18]
		g_szWeapRestrFixed[17] = g_szWeapRestr[15]
		g_szWeapRestrFixed[18] = g_szWeapRestr[16]
		set_cvar_string("pb_restrweapons", g_szWeapRestrFixed)
	}
	if (!equali(g_szEquipAmmoRestr, g_szOldEquipAmmoRestr))
	{
		set_cvar_string("pb_restrequipammo", g_szEquipAmmoRestr)
	}

	format(g_szOldWeapRestr, 26, g_szWeapRestr)
	format(g_szOldEquipAmmoRestr, 9, g_szEquipAmmoRestr)
	if ((pv_csdm_active) && (pv_mp_freeforall))
	{
		if ((get_pcvar_float(pv_csdm_active)) && (get_pcvar_float(pv_mp_freeforall)))
		{
			set_cvar_float("pb_ffa", 1.0)
		}
		else
		{
			set_cvar_float("pb_ffa", 0.0)
		}
	}
}

public check_cvar_pointers()
{
	pv_csdm_active = get_cvar_pointer("csdm_active")
	pv_mp_freeforall = get_cvar_pointer("mp_freeforall")
}

public plugin_init()
{
	register_plugin(Plugin, Version, Author)

	pv_amx_restrweapons = get_cvar_pointer("amx_restrweapons")
	pv_amx_restrequipammo = get_cvar_pointer("amx_restrequipammo")
	set_task(1.0, "check_restrictions", 789, "", 0, "b")
	set_task(10.0, "check_cvar_pointers", 790)
}
