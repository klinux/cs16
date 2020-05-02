/*	
* 
* 	CSDM Teambalancer V1.1 by DA 
* 	Date: 03.04.2008
* 
* 			
* 	Description:
* 			This plugin balance the teams in CS 1.6 without to end the round. It was made for CSDM (Deathmatch) Servers
* 
* 					
* 	Installation:
* 			Download the sma file and compile it
* 			Load the compiled csdm_teambalancer.amxx to your plugins folder
* 			Add a line "csdm_teambalancer.amxx" (without quotes) to your plugins.ini
* 			If you want to play a sound to the player who switched by the plugin then copy the massteleporttarget.wav to your /sound/misc/ folder and add this to your amxx.cfg: amx_tsound 1
* 			Change the map or restart the Server
*	
* 						
* 	SVAR's:
* 			amx_tfreq			(Default: 50)	-	All 50 (Default) death the plugin checks the players and switch they
* 			amx_tmaxplayers		(Default:  4)	-	Max players on the server that it works
* 			amx_tsound			(Default:  0)	- 	Plays a sound to the player if he will be changed	
* 
* 
* 	Credits:
* 			Jim for some code and the idea
* 			Geesu for the sound file from wc3ft
* 					
* 
*/ 


#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define PLUGIN	"CSDM Teambalancer"
#define AUTHOR	"DA"
#define VERSION	"1.1c"

#define Team_T      1
#define Team_CT     2

new counter = 0;
new pv_amx_tmaxfreq, pv_amx_tmaxplayers, pv_amx_tsound;
new g_msgTeamInfo

const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5

public plugin_precache()
{
	precache_sound("misc/massteleporttarget.wav");
	return PLUGIN_CONTINUE;
}


public on_death()
{
	counter++;
	if	(counter >= get_pcvar_num(pv_amx_tmaxfreq))
	{
		if	(get_playersnum() >= get_pcvar_num(pv_amx_tmaxplayers))
		{
			counter = 0;
			transfer_player();
		}
	}
}


transfer_player() 
{ 
	new name[32], players[32], scores[32];
	new player, playercount, bestscore, theone, i;
	new CTCount = 0, TCount = 0;

	get_players ( players, playercount );
	
	for ( i = 0; i < playercount; ++i )
	{
		if ( fm_get_user_team( players[i] ) == Team_CT )
		{
			++CTCount;
		}
		else if ( fm_get_user_team( players[i] ) == Team_T )
		{
			++TCount;
		}
	}
	
	new WhichTeam;

	if ( ( CTCount - TCount ) >= 2 )
	{
		WhichTeam = Team_CT;
	}
	
	else if ( ( TCount - CTCount ) >= 2 )
	{
		WhichTeam = Team_T;
	}
	
	else
	{
		return PLUGIN_CONTINUE;
	}
	
	for	(i=0; i<playercount; i++) 
	{
		player = players[i];
		
		if ( fm_get_user_team( player ) == WhichTeam )
		{
			scores[i] = get_user_frags(player) - get_user_deaths(player);
		}
	}
	
	bestscore = -9999;
	for	(i=0; i<playercount; i++) 
	{
		if (scores[i] > bestscore) 
		{
			bestscore = scores[i];
			theone = players[i];
		}
	}
	
	fm_set_user_team(theone, WhichTeam == Team_T ? Team_CT : Team_T);
	cs_reset_user_model( theone );
	if	(get_pcvar_num(pv_amx_tsound) == 1) 
		client_cmd(theone, "speak misc/MassTeleportTarget");
	set_hudmessage(255, 140, 0, -1.0, 0.40, 2, 0.02, 5.0, 0.01, 0.1, 2);
	show_hudmessage(theone,"You have been transfered to %s", WhichTeam == Team_T ? "CT" : "Terrorist");
	get_user_name(theone,name,31);
	client_print(0,print_chat,"%s has been transfered to %s.", name, WhichTeam == Team_T ? "CT" : "Terrorist");
	console_print(0,"%s has been transfered to %s.", name, WhichTeam == Team_T ? "CT" : "Terrorist");
	
	return PLUGIN_CONTINUE;
}


stock fm_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

stock fm_set_user_team(id, team)
{
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX);
	fm_set_user_team_msg(id);
}

// Send User Team Message
public fm_set_user_team_msg(id)
{
	// Beware: this message can now be picked up by other metamod
	// plugins (yeah, that includes AMXX plugins as well)
		
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_msgTeamInfo)
	ewrite_byte(id)
	switch (fm_get_user_team(id))
	{
		case CS_TEAM_UNASSIGNED: ewrite_string("UNASSIGNED");
		case CS_TEAM_T: ewrite_string("TERRORIST");
		case CS_TEAM_CT: ewrite_string("CT");
		case CS_TEAM_SPECTATOR: ewrite_string("SPECTATOR");
	}	
	emessage_end()
}


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	pv_amx_tmaxfreq = register_cvar("amx_tmaxfreq", "50");
	pv_amx_tmaxplayers = register_cvar("amx_tmaxplayers", "4");
	pv_amx_tsound = register_cvar("amx_tsound", "1");
	register_event("DeathMsg", "on_death", "a");
	g_msgTeamInfo = get_user_msgid("TeamInfo");
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1031\\ f0\\ fs16 \n\\ par }
*/
