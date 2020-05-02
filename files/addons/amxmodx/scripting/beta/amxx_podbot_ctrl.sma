/*------------------------------------------------------------------------------

Control of bots on the server
It keeps the constant amount of bots on the server (ie 10) until another 
constant amount of human-players joins the server. Then - next human enters - one
bot gets kicked.

Plugin cvars:

pb_min_humans
pb_bots_quota

------------------------------------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN "POD-Bot MM Quota Control"
#define VERSION "1.0 RC 1"
#define AUTHOR "KWo"


new pcvar_pb_min_humans
new pcvar_pb_bots_quota
new pcvar_pb_minbots
new pcvar_pb_maxbots

new g_maxplayers
new g_humans_nr
new g_bots_nr
new g_humans[32]
new g_bots[32]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	pcvar_pb_min_humans = register_cvar("pb_min_humans", "10")
	pcvar_pb_bots_quota = register_cvar("pb_bots_quota", "10")
	g_maxplayers = get_maxplayers()
	if (cvar_exists("pb_version"))
	{
		pcvar_pb_minbots = get_cvar_pointer("pb_minbots")
		pcvar_pb_maxbots = get_cvar_pointer("pb_maxbots")
		if (pcvar_pb_minbots && pcvar_pb_maxbots)
			set_task(1.0, "check_players", 8765, "", 0, "b")
	}
}

public check_players()
{
	new min_humans = get_pcvar_num(pcvar_pb_min_humans)
	new bots_quota = get_pcvar_num(pcvar_pb_bots_quota)

	if (get_pcvar_num(pcvar_pb_minbots) != 0)
		set_pcvar_num(pcvar_pb_minbots, 0)
	if (get_pcvar_num(pcvar_pb_maxbots) != 0)
		set_pcvar_num(pcvar_pb_maxbots, 0)

	if (min_humans < 0)
		min_humans = 0
	else if (min_humans > g_maxplayers)
		min_humans = g_maxplayers

	if (bots_quota < 0)
		bots_quota = 0
	else if (bots_quota > g_maxplayers - 1)
		bots_quota = g_maxplayers - 1 // we need at least one slot to connect...

	get_players(g_humans,g_humans_nr,"c")
	get_players(g_bots,g_bots_nr,"d")

	if (min_humans + bots_quota > g_maxplayers - 1)
		bots_quota = g_maxplayers - min_humans - 1

	if (g_humans_nr <= min_humans)
	{
		if (g_bots_nr < bots_quota)
		{
			server_cmd("pb add")
		}
		else if (g_bots_nr > bots_quota)
		{
			new i = random_num(0, g_bots_nr - 1)
			new u_id = get_user_userid(g_bots[i])
			server_cmd("kick #%d", u_id)
		}
	}
	else
	{
		if (g_humans_nr - min_humans + g_bots_nr - bots_quota < 0)
		{
			server_cmd("pb add")
		}
		else if ((g_humans_nr - min_humans + g_bots_nr - bots_quota > 0) && (g_bots_nr > 0))
		{
			new i = random_num(0, g_bots_nr - 1)
			new u_id = get_user_userid(g_bots[i])
			server_cmd("kick #%d", u_id)
		}
	}
}
