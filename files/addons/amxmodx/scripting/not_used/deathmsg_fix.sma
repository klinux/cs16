/*  AMX Mod X script.

    DeathMsg Fix Plugin

    (c) Copyright 2007, Simon Logic (slspam@land.ru)
    This file is provided as is (no warranties).
	
	Info:
		Plugin fixes an absence of DeathMsg (notification) on critical
		damage. This bug usually occures when player is killed by map
		entity. Very useful when playing maps with tank/gun/etc entities 
		under CSDM because a dead player will not be respawned automatically 
		in this case.
	
	Requirements:
        * CS/CZ mod
        * AMX/X 1.7x or higher
        * CStrike module
	
	Known issues:
		* Bomb Explosion Features plugin (by VEN) may start to work wrong after
		this plugin has been activated

	History:
		1.0.3 [2007-03-10]
		! fixed an issue when other plugins, placed below the current plugin 
		in plugins.ini, got an invalid arguments for Damage event (e.g. 
		receiver=0, dmg_take=1 instead of valid receiver=1, dmg_take=125)
		1.0.2 [2007-03-02]
		! avoid dealing with zero player id wihtin onDamage() function (may 
		occure under AXM/X 1.75a)
		1.0.1 [2007-02-16]
		* removed cstrike mod checking cause cstrike module has already been
		included
		* added public cvar with plugin version
		1.0.0 [2007-02-14]
		* initial release
*/

#include <amxmodx>
#include <cstrike>

#define MY_PLUGIN_NAME    "DeathMsg Fix"
#define MY_PLUGIN_VERSION "1.0.3"
#define MY_PLUGIN_AUTHOR  "Simon Logic"

#define MAX_CLIENTS 32

new bool:g_bDeathMsg[MAX_CLIENTS+1]
new bool:g_bCriticalDamage[MAX_CLIENTS+1]
new g_msgDeathMsg

public plugin_init()
{
	g_msgDeathMsg = get_user_msgid("DeathMsg")

	register_plugin(MY_PLUGIN_NAME, MY_PLUGIN_VERSION, MY_PLUGIN_AUTHOR)

	register_cvar("version_deathmsg_fix", MY_PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_event("Damage", "onDamage", "b", "2!0") // dmg_take <> 0
	register_event("DeathMsg", "onDeath", "a")
	register_event("ResetHUD", "onPlayerSpawn", "be")
}

public onPlayerSpawn(id)
{
	g_bDeathMsg[id] = false
	g_bCriticalDamage[id] = false
}

public onDeath()
{
	new victim = read_data(2)
	
	if(!g_bCriticalDamage[victim])
		g_bDeathMsg[victim] = true
}

public onDamage(id)
{
	if(id && !(is_user_alive(id) || g_bDeathMsg[id] || g_bCriticalDamage[id]))
	{
		g_bCriticalDamage[id] = true

		new arr[1]; arr[0] = id
		set_task(0.1, "taskSendDeathMsg", _, arr, sizeof(arr))
		
		new sName[24], sAuthID[20], sTeam[10]

		get_user_name(id, sName, 23)
		get_user_team(id, sTeam, 9)
		get_user_authid(id, sAuthID, 19)
	
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"world^"", sName, get_user_userid(id), sAuthID, sTeam)

		cs_set_user_deaths(id, cs_get_user_deaths(id) + 1)
	}
}

public taskSendDeathMsg(arr[1])
{
	emessage_begin(MSG_ALL, g_msgDeathMsg)
	ewrite_byte(0)  // killer (0 - world)
	ewrite_byte(arr[0]) // victim
	ewrite_byte(0) // headshot flag
	ewrite_string("world") // killer's weapon
	emessage_end()
}
