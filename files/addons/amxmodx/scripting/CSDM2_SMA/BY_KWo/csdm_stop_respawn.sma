/*
 * csdm_stop_respawn.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CDSM Stop Respawn - Plugin to let You join spectators 
 * if You don't wish to be respawned
 *
 * (C)2003-2006 David "BAILOPAN" Anderson
 * (C)2003-2006 teame06
 *  Give credit where due.
 *  Share the source - it sets you free
 *  [url]http://www.opensource.org/[/url]
 *  [url]http://www.gnu.org/[/url]
 */

#include <amxmodx>
#include <amxmisc>
#include <csdm>

new bool:g_StopRespawn[33]

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}
}

public plugin_init()
{
	register_plugin("CDSM Stop Respawn", "1.0", "teame06")
	register_clcmd("amx_respawn", "restore_respawn", ADMIN_LEVEL_G, "Stop/Restore Spawns")
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if(g_StopRespawn[victim])
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public restore_respawn(id,lvl,cid)
{
	if(!cmd_access(id,lvl,cid,1))
		return PLUGIN_HANDLED

	new teamid = get_user_team(id)
	if(teamid == _TEAM_T || teamid == _TEAM_CT)
	{
		if(g_StopRespawn[id])
		{
			g_StopRespawn[id] = false
			csdm_respawn(id)

			console_print(id, "Spawning is re-enable")
			return PLUGIN_HANDLED
		}
		else
		{
			g_StopRespawn[id] = true
			user_silentkill(id)

			console_print(id, "Stop re-spawning")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public client_connect(id)
{
	g_StopRespawn[id] = false
}
