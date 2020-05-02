/* Vehicle Kills 1.25 by Damaged Soul

   AMX Mod X Version: 1.75 and above
   Supported Mods: Counter-Strike 1.6 and Condition Zero
   
   This file is provided as is (no warranties).
  
   ***************
   * Description *
   ***************
   This plugin allows players to see death messages that can show who killed whom with a vehicle.
   
   ********************
   * Required Modules *
   ********************
   Cstrike
   Fakemeta
   
   *********
   * Usage *
   *********
   Cvars:
      amx_vk_frags [Default Value: 1]
         - Determines how many frags a player gets for killing someone on the other team 
           with a vehicle
	 
      amx_vk_tkpenalty [Default Value: 1]
         - Determines how many frags a player loses for killing someone on the same team
           with a vehicle

      amx_vk_tkpunish [Default Value: 0]
         - Determines whether or not to instantly kill a player when they kill a teammate with
           a vehicle
         - If set to 1, a TKer will be killed directly after killing someone on the same team with
           a vehicle
         - If set to 0, then the plugin will do nothing directly after killing someone on the same
           team with a vehicle

      amx_vk_version
         - Shows the version of the plugin

   *******************
   * Version History *
   *******************
   1.25 [July 4, 2006]
      - Added: amx_vk_version cvar for more easily finding a server with this plugin
      - Death messages are now also done via emessage_begin which now allows team kill plugins, such
        as ATAC, to detect vehicle kills. This should allow things such as forgiving the team kill.
      - No longer relies on the Engine module

   1.22 [Apr. 26, 2006]
      - Added: amx_vk_tkpunish cvar that when set to 1 will instantly kill a player after they kill
               a teammate
      - Fixed: No death message appeared when there was a suicide involving a vehicle (somehow the
               bug returned or wasn't fixed properly the first time)

   1.21 [Apr. 23, 2006]
      - Fixed: As a side effect of replacing suicides with vehicle deaths in the HL logs, chat
               logging (as well as most logged information from CS/CZ) was blocked

   1.20 [Apr. 21, 2006]
      - Minor optimizations to code
      - Now uses the pcvar natives for getting values of cvars
      - Fixed: Runtime errors involving invalid players
      - Fixed: When a true suicide involving a vehicle occurred no death message appeared at all
      - Fixed: Vehicle deaths were still being reported as suicides in standard HL logs

   1.10 [Oct. 7, 2004]
      - Public release
      - Changed to no longer rely on fun module
      - Added: amx_vk_tkpenalty cvar for how many frags to subtract for team killing with a vehicle

   1.00 [Oct. 4, 2004]
      - Initial version
*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>

// Plugin information constants
new const PLUGIN[] = "Vehicle Kills"
new const AUTHOR[] = "Damaged Soul"
new const VERSION[] = "1.25"

// Message IDs
new g_msgDeathMsg, g_msgScoreInfo
// Cvar pointers
new g_cvarFrags, g_cvarTkPenalty, g_cvarTkPunish

// Has a death involving a vehicle occurred?
new bool:g_vehicleDeathHasOccurred = false
// Victim and killer entity indicies for when a vehicle death occurs
new g_vehicleVictim = 0, g_vehicleKiller = 0

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("amx_vk_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	g_cvarFrags = register_cvar("amx_vk_frags", "1", FCVAR_SERVER)
	g_cvarTkPenalty = register_cvar("amx_vk_tkpenalty", "1", FCVAR_SERVER)
	g_cvarTkPunish = register_cvar("amx_vk_tkpunish", "0", FCVAR_SERVER)
	
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	
	register_message(g_msgDeathMsg, "hookmsg_death")
	register_message(g_msgScoreInfo, "hookmsg_scoreinfo")
	register_forward(FM_AlertMessage, "hook_alertmessage")
}

public hookmsg_death(msgid, msgdest, msgargs)
{
	new weapon[32]
	get_msg_arg_string(4, weapon, 31)
	
	// Vehicle death message has occurred so block it
	if (equal(weapon, "vehicle"))
	{
		g_vehicleDeathHasOccurred = true
		
		// Get the victim of the vehicle death
		g_vehicleVictim = get_msg_arg_int(2)
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public hookmsg_scoreinfo(msgid, msgdest, msgargs)
{
	// If vehicle death message hasn't occurred, skip this
	if (!g_vehicleDeathHasOccurred) return PLUGIN_CONTINUE
	
	// If this message was not sent to the MSG_BROADCAST (unreliable to all) channel...
	// Then we know it's the ScoreInfo for the killer
	if (msgdest != MSG_BROADCAST)
		g_vehicleKiller = get_msg_arg_int(1) // Get killer
	else
		set_task(0.1, "score_delay") // Delay new DeathMsg and ScoreInfo

	return PLUGIN_CONTINUE
}

public hook_alertmessage(atype, msg[])
{
	if (contain(msg, ">^" committed suicide with ^"vehicle^" (world)") > 0)
		return FMRES_SUPERCEDE
		
	return FMRES_IGNORED
}

public score_delay()
{
	if (!is_user_connected(g_vehicleVictim) || (g_vehicleKiller > 0 && !is_user_connected(g_vehicleKiller)))
		return
	
	// Send new death message showing who killed who using a vehicle
	message_begin(MSG_ALL, g_msgDeathMsg, {0,0,0}, 0)
	write_byte(g_vehicleKiller) // Killer
	write_byte(g_vehicleVictim) // Victim
	write_byte(0) // Headshot
	write_string("vehicle") // Weapon
	message_end()
	
	// Send new death message to all hooks (such as team kill plugins)
	emessage_begin(MSG_ALL, g_msgDeathMsg, {0,0,0}, 0)
	ewrite_byte(g_vehicleKiller) // Killer
	ewrite_byte(g_vehicleVictim) // Victim
	ewrite_byte(0) // Headshot
	ewrite_string("vehicle") // Weapon
	emessage_end()
	
	log_kill(g_vehicleKiller, g_vehicleVictim, "vehicle")
	
	// If we have a killer and it wasn't a suicide then update frag count of killer
	if (g_vehicleKiller)
	{
		new newFragCount
		new killerTeam = get_user_team(g_vehicleKiller)
	
		// If player has committed team kill, subtract amx_vk_tkpenalty
		// If player has committed kill on a player of other team, add amx_vk_frags
		if (killerTeam == get_user_team(g_vehicleVictim))
		{
			newFragCount = get_user_frags(g_vehicleKiller) - (get_pcvar_num(g_cvarTkPenalty) - 1)
			
			if (get_pcvar_num(g_cvarTkPunish) != 0)
			{
				// Reset internal TK flag because we don't want the game to handle it
				cs_set_user_tked(g_vehicleKiller, 0, 0)
				// Now slay TKer
				user_kill(g_vehicleKiller)
				
				new name[32]
				get_user_name(g_vehicleKiller, name, 31)
				
				// Print message saying why player was killed
				client_print(0, print_chat, "%s has been slain for killing a teammate with a vehicle", name)
			}
		}
		else
			newFragCount = get_user_frags(g_vehicleKiller) + (get_pcvar_num(g_cvarFrags) - 1)

		// Set new frag count for killer
		set_pev(g_vehicleKiller, pev_frags, float(newFragCount))
	
		// Update the scoreboard
		message_begin(MSG_ALL, g_msgScoreInfo, {0,0,0}, 0)
		write_byte(g_vehicleKiller) // Player ID
		write_short(newFragCount) // Frags
		write_short(cs_get_user_deaths(g_vehicleKiller)) // Deaths
		write_short(0) // Not sure what this is for
		write_short(killerTeam) // Team
		message_end()
	}
	

	// Reset vehicle death check
	g_vehicleDeathHasOccurred = false
	// Reset entity indices
	g_vehicleVictim = 0
	g_vehicleKiller = 0
}

log_kill(killer, victim, const weapon[])
{
	new vname[32], vauth[40], vteam[10]
	
	// Get necessary information about victim for the log
	get_user_name(victim, vname, 31)
	get_user_authid(victim, vauth, 39)
	get_user_team(victim, vteam, 9)
	
	if (killer)
	{
		new  kname[32], kauth[40], kteam[10]
		
		// Get necessary information about killer for the log
		get_user_name(killer, kname, 31)
		get_user_authid(killer, kauth, 39)
		get_user_team(killer, kteam, 9)
		
		// We have a killer and victim involved, so log both of them in this line
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
				kname, get_user_userid(killer), kauth, kteam,
				vname, get_user_userid(victim), vauth, vteam, weapon)
	}
	else
	{
		// Log a suicide death
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"",
				vname, get_user_userid(victim), vauth, vteam, weapon)
	}
	
}
