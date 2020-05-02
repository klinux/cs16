/* AMX Mod X
*   Misc. Stats Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation, 
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve, 
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx>
#include <fakemeta>
#include <csx>
#include <cstrike>

public MultiKill
public MultiKillSound
public BombPlanting
public BombDefusing
public BombPlanted
public BombDefused
public BombFailed
public BombPickUp
public BombDrop
public BombCountHUD
public BombCountVoice
public BombCountDef
public BombReached
public ItalyBonusKill
public EnemyRemaining
public LastMan
public LastManSound
public KnifeKill
public KnifeKillSound
public GrenadeKill
public GrenadeSuicide
public HeadShotKill
public HeadShotKillSound
public RoundCounter
public RoundCounterSound
public KillingStreak
public KillingStreakSound
public KillingStreakChat
public KillingStreakHUD
public KillingStreakEndHUD
public KillingStreakSay
public DoubleKill
public DoubleKillSound
public PlayerName
public FirstBloodSound
public FallKill
public Suicide
public AirKill
public WaterKill
public WallShot

new g_streakKills[33][2]
new g_multiKills[33][2]
new g_kills[33] = {0,...}
new g_deaths[33] = {0,...}
new g_knife[33] = {0,...}
new g_hs[33] = {0,...}
new g_nade[33] = {0,...}
new g_longestKillStreak[33] = {0,...}
new g_longestDeathStreak[33] = {0,...}
new Float:g_DeathStats[33] = {0.0,...}

new g_C4Timer
new g_mp_c4timer
new Float:g_mp_freezetime
new g_maxplayers
new g_Defusing
new g_Planter
new Float:g_LastOmg
new g_LastAnnounce
new g_roundCount
new Float:g_doubleKill
new Float:g_fHUDDuration

new g_doubleKillId
new g_friend[33]
new g_firstBlood
new g_center1_sync
new g_announce_sync
new g_status_sync
new g_left_sync
new g_bottom_sync
new g_he_sync
new g_bomb_hud_sync
new g_kill_end_sync
new g_FM_Running

new g_MultiKillMsg[7][] =
{
	"Multi-Kill! %s^n%L %d %L (%d %L)", 
	"Ultra-Kill!!! %s^n%L %d %L (%d %L)", 
	"%s IS ON A KILLING SPREE!!!^n%L %d %L (%d %L)", 
	"RAMPAGE!!! %s^n%L %d %L (%d hs)", 
	"%s IS UNSTOPPABLE!!!^n%L %d %L (%d %L)", 
	"%s IS A MONSTER!^n%L %d %L (%d %L)", 
	"%s IS GODLIKE!!!!^n%L %d %L (%d %L)"
}

new g_Sounds[7][] =
{
	"multikill", 
	"ultrakill", 
	"killingspree", 
	"rampage", 
	"unstoppable", 
	"monsterkill", 
	"godlike"
}
new g_KillingMsg[7][] =
{
	"%s: Multi-Kill!", 
	"%s: Ultra-Kill!!!", 
	"%s IS ON A KILLING SPREE!!!", 
	"%s: RAMPAGE!!!", 
	"%s IS UNSTOPPABLE!!!", 
	"%s IS A MONSTER!", 
	"%s IS GODLIKE!!!"
}

new g_KinfeMsg[4][] =
{
	"KNIFE_MSG_1", 
	"KNIFE_MSG_2", 
	"KNIFE_MSG_3", 
	"KNIFE_MSG_4"
}

new g_LastMessages[4][] =
{
	"LAST_MSG_1", 
	"LAST_MSG_2", 
	"LAST_MSG_3", 
	"LAST_MSG_4"
}

new g_HeMessages[4][] =
{
	"HE_MSG_1", 
	"HE_MSG_2", 
	"HE_MSG_3", 
	"HE_MSG_4"
}

new g_SHeMessages[4][] =
{
	"SHE_MSG_1", 
	"SHE_MSG_2", 
	"SHE_MSG_3", 
	"SHE_MSG_4"
}

new g_HeadShots[7][] =
{
	"HS_MSG_1", 
	"HS_MSG_2", 
	"HS_MSG_3", 
	"HS_MSG_4", 
	"HS_MSG_5", 
	"HS_MSG_6", 
	"HS_MSG_7"
}

new g_FallKillMessages[3][] =
{
	"FALL_MSG_1", 
	"FALL_MSG_2", 
	"FALL_MSG_3"
}

new g_SuicideMessages[2][] =
{
	"SK_MSG_1", 
	"SK_MSG_2"
}

new g_AirKillMessages[3][] =
{
	"AIR_MSG_1", 
	"AIR_MSG_2", 
	"AIR_MSG_3"
}

new g_WaterKillMessages[3][] =
{
	"WAT_MSG_1", 
	"WAT_MSG_2", 
	"WAT_MSG_3"
}

new g_WallShotMessages[3][] =
{
	"WALL_MSG_1", 
	"WALL_MSG_2", 
	"WALL_MSG_3"
}

new g_teamsNames[4][] =
{
	"TERRORIST", 
	"CT", 
	"TERRORISTS", 
	"CTS"
}

public plugin_init()
{
	register_plugin("CS Misc. Stats2", AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("miscstats2.txt")
	g_FM_Running = is_module_loaded("FakeMeta")
	register_clcmd("say /streak","cmdKillingStreak",0,"- display info. about your killing streak")
	register_event("ResetHUD","eResetHud","be")

	register_logevent("SuicideMsg",4,"1=committed suicide with")
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w")
	register_event("SendAudio", "eEndRound", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")
	register_event("RoundTime", "eNewRound", "bc")
	register_event("StatusValue", "setTeam", "be", "1=1")
	register_event("StatusValue", "showStatus", "be", "1=2", "2!0")
	register_event("StatusValue", "hideStatus", "be", "1=1", "2=0")

	new mapname[32]
	get_mapname(mapname, 31)

	if (equali(mapname, "de_", 3) || equali(mapname, "csde_", 5))
	{
		register_event("StatusIcon", "eGotBomb", "be", "1=1", "1=2", "2=c4")
		register_event("TextMsg", "eBombPickUp", "bc", "2&#Got_bomb")
//		register_event("TextMsg", "eBombPickUp", "bc", "2&#Game_bomb_p")
		register_event("TextMsg", "eBombDrop", "bc", "2&#Game_bomb_d")
	}
	else if (equali(mapname, "cs_italy"))
	{
		register_event("23", "chickenKill", "a", "1=108", /*"12=106", */ "15=4")
		register_event("23", "radioKill", "a", "1=108", /*"12=294", */ "15=2")
	}

	g_center1_sync = CreateHudSyncObj()
	g_announce_sync = CreateHudSyncObj()
	g_status_sync = CreateHudSyncObj()
	g_left_sync = CreateHudSyncObj()
	g_bottom_sync = CreateHudSyncObj()
	g_he_sync = CreateHudSyncObj()
	g_bomb_hud_sync = CreateHudSyncObj()
	g_kill_end_sync = CreateHudSyncObj()
}

public plugin_cfg()
{
	new g_addStast[] = "amx_statscfg add ^"%s^" %s"
	
	server_cmd(g_addStast, "ST_MULTI_KILL", "MultiKill")
	server_cmd(g_addStast, "ST_MULTI_KILL_SOUND", "MultiKillSound")
	server_cmd(g_addStast, "ST_BOMB_PLANTING", "BombPlanting")
	server_cmd(g_addStast, "ST_BOMB_DEFUSING", "BombDefusing")
	server_cmd(g_addStast, "ST_BOMB_PLANTED", "BombPlanted")
	server_cmd(g_addStast, "ST_BOMB_DEF_SUCC", "BombDefused")
	server_cmd(g_addStast, "ST_BOMB_DEF_FAIL", "BombFailed")
	server_cmd(g_addStast, "ST_BOMB_PICKUP", "BombPickUp")
	server_cmd(g_addStast, "ST_BOMB_DROP", "BombDrop")
	server_cmd(g_addStast, "ST_BOMB_CD_HUD", "BombCountHUD")
	server_cmd(g_addStast, "ST_BOMB_CD_VOICE", "BombCountVoice")
	server_cmd(g_addStast, "ST_BOMB_CD_DEF", "BombCountDef")
	server_cmd(g_addStast, "ST_BOMB_SITE", "BombReached")
	server_cmd(g_addStast, "ST_ITALY_BONUS", "ItalyBonusKill")
	server_cmd(g_addStast, "ST_LAST_MAN", "LastMan")
	server_cmd(g_addStast, "ST_LAST_MAN_SOUND", "LastManSound")
	server_cmd(g_addStast, "ST_KNIFE_KILL", "KnifeKill")
	server_cmd(g_addStast, "ST_KNIFE_KILL_SOUND", "KnifeKillSound")
	server_cmd(g_addStast, "ST_HE_KILL", "GrenadeKill")
	server_cmd(g_addStast, "ST_HE_SUICIDE", "GrenadeSuicide")
	server_cmd(g_addStast, "ST_HS_KILL", "HeadShotKill")
	server_cmd(g_addStast, "ST_HS_KILL_SOUND", "HeadShotKillSound")
	server_cmd(g_addStast, "ST_ROUND_CNT", "RoundCounter")
	server_cmd(g_addStast, "ST_ROUND_CNT_SOUND", "RoundCounterSound")
	server_cmd(g_addStast, "ST_KILL_STR", "KillingStreak")
	server_cmd(g_addStast, "ST_KILL_STR_SOUND", "KillingStreakSound")
	server_cmd(g_addStast, "ST_KILL_STR_CHAT", "KillingStreakChat")
	server_cmd(g_addStast, "ST_KILL_STR_HUD", "KillingStreakHUD")
	server_cmd(g_addStast, "ST_KILL_STR_END", "KillingStreakEndHUD")
	server_cmd(g_addStast, "ST_KILL_STR_SAY", "KillingStreakSay")
	server_cmd(g_addStast, "ST_ENEMY_REM", "EnemyRemaining")
	server_cmd(g_addStast, "ST_DOUBLE_KILL", "DoubleKill")
	server_cmd(g_addStast, "ST_DOUBLE_KILL_SOUND", "DoubleKillSound")
	server_cmd(g_addStast, "ST_PLAYER_NAME", "PlayerName")
	server_cmd(g_addStast, "ST_FIRST_BLOOD_SOUND", "FirstBloodSound")
	server_cmd(g_addStast, "ST_FALL_KILL", "FallKill")
	server_cmd(g_addStast, "ST_SUICIDE", "Suicide")
	if(g_FM_Running) 
	{
		server_cmd(g_addStast,"ST_AIR_KILL", "AirKill")
		server_cmd(g_addStast,"ST_WATER_KILL", "WaterKill")
		server_cmd(g_addStast,"ST_WALL_SHOT", "WallShot")
	}
	get_config_cvars()
}

// Get config parameters.
get_config_cvars()
{
	g_fHUDDuration = get_cvar_float("amx_statsx_duration")
	
	if (g_fHUDDuration < 1.0)
		g_fHUDDuration = 1.0

	g_mp_c4timer = get_cvar_num("mp_c4timer")
	g_mp_freezetime = get_cvar_float("mp_freezetime")
	g_maxplayers = get_maxplayers()
}

bool:can_see_fm(entindex1, entindex2)
{
	if ((!g_FM_Running) || !entindex1 || !entindex2)
		return false
//  new ent1, ent2

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}
 
public client_putinserver(id)
{
	g_multiKills[id] = {0, 0}
	g_streakKills[id] = {0, 0}
	g_kills[id] = 0
	g_deaths[id] = 0
	g_knife[id] = 0
	g_hs[id] = 0
	g_nade[id] = 0
	g_longestDeathStreak[id] = 0
	g_longestKillStreak[id] = 0
	g_DeathStats[id] = 0.0
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (wpnindex == CSW_C4)
		return

	if ((killer) && (g_Defusing == victim))
		g_Defusing = 0
	new headshot = (hitplace == HIT_HEAD) ? 1 : 0
	new selfkill = (killer == victim) ? 1 : 0
	new enemykill = !TK && !selfkill

	g_DeathStats[victim] = get_gametime() + g_fHUDDuration

	new dm_ppl[32], plnum = 0
	get_players(dm_ppl, plnum, "c")
	new tempId
	new Float:f_gametime = get_gametime()

	if(KillingStreakHUD)
	{
		new param[8]
		param[0] = victim
		param[1] = g_kills[victim]
		param[2] = g_hs[victim]
		param[3] = g_nade[victim]
		param[4] = g_knife[victim]
		param[5] = g_longestKillStreak[victim]
		param[6] = g_longestDeathStreak[victim]
		param[7] = 1
		set_task(g_fHUDDuration + 1.0, "showKillingStreakHud", 12345+victim, param, 8)
	}
	if((g_kills[victim] > 4) && KillingStreakEndHUD && (killer != victim) && killer)
	{
		new param[6]
		param[0] = victim
		param[1] = killer
		param[2] = g_kills[victim]
		param[3] = g_hs[victim]
		param[4] = g_nade[victim]
		param[5] = g_knife[victim]
		set_task(g_fHUDDuration + 1.0, "showKillingStreakEndHud", 23456+victim, param, 6)
	}
	if(headshot && enemykill)
	{
		++g_hs[killer]
	}
	if((wpnindex == CSW_KNIFE) && enemykill) 
	{
		++g_knife[killer]
  }
	else if((wpnindex == CSW_HEGRENADE) && enemykill) 
	{
		++g_nade[killer]
	}
	if(enemykill)
	{
		g_kills[killer] += 1
		g_deaths[killer] = 0
	}
	else g_kills[killer] -= 1

	g_kills[victim] = 0
	g_deaths[victim] += 1
	g_hs[victim] = 0
	g_knife[victim] = 0
	g_nade[victim] = 0
	if(g_kills[killer] > g_longestKillStreak[killer]) 
	{
		g_longestKillStreak[killer] = g_kills[killer]
	}
	if(g_deaths[victim] > g_longestDeathStreak[victim])
	{
		g_longestDeathStreak[victim] = g_deaths[victim]
	}

	if (g_firstBlood)
	{
		g_firstBlood = 0
		if (FirstBloodSound)
			play_sound("misc/firstblood")
	}

	if ((KillingStreak || KillingStreakSound || KillingStreakHUD || KillingStreakChat) && !TK)
	{
		g_streakKills[victim][1]++
		g_streakKills[victim][0] = 0

		if (!selfkill)
		{
			g_streakKills[killer][0]++
			g_streakKills[killer][1] = 0
			++g_streakKills[victim][1]
			g_streakKills[victim][0] = 0

			new a = g_streakKills[killer][0] - 3

			if ((a > -1) && !(a % 2))
			{
				new name[32]
				get_user_name(killer, name, 31)
				
				if ((a >>= 1) > 6)
					a = 6

				if (KillingStreak)
				{
					set_hudmessage(0, 100, 255, 0.05, 0.49, 2, 0.02, 6.0, 0.01, 0.1, -1)
					for(new i = 0; i < plnum; ++i)
					{
						tempId = dm_ppl[i]
						if(g_DeathStats[tempId] > f_gametime)
							continue
						ShowSyncHudMsg(tempId, g_left_sync, g_KillingMsg[a], name)
					}
				}

				if (KillingStreakSound)
				{
					new file[32]

					format(file, 31, "misc/%s", g_Sounds[a])
					play_sound(file)
				}
			}
		}
	}

	if (MultiKill || MultiKillSound)
	{
		if (!selfkill && !TK && killer)
		{
			g_multiKills[killer][0]++ 
			g_multiKills[killer][1] += headshot

			new param[2]

			param[0] = killer
			param[1] = g_multiKills[killer][0]
			set_task(4.0 + float(param[1]), "checkKills", 0, param, 2)
		}
	}

	if ((EnemyRemaining) && is_user_connected(victim))
	{
		new ppl[32], pplnum = 0
		new epplnum = 0
		new CsTeams:team = cs_get_user_team(victim)
		new CsTeams:other_team
		new CsTeams:enemy_team = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T
		
		if (team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			for (new i=1; i<=g_maxplayers; i++)
			{
				if (!is_user_connected(i))
				{
					continue
				}
				if (i == victim)
				{
					continue
				}
				other_team = cs_get_user_team(i)
				if (other_team == team && is_user_alive(i))
				{
					epplnum++
				} else if (other_team == enemy_team) {
					ppl[pplnum++] = i
				}
			}
			
			if (pplnum && epplnum)
			{
				new message[128], team_name[32]

				set_hudmessage(255, 255, 255, 0.02, 0.85, 2, 0.05, 0.1, 0.02, 3.0, -1)
				
				/* This is a pretty stupid thing to translate, but whatever */
				new _teamname[32]
				if (team == CS_TEAM_T)
				{
					format(_teamname, 31, "TERRORIST%s", (epplnum == 1) ? "" : "S")
				} else if (team == CS_TEAM_CT) {
					format(_teamname, 31, "CT%s", (epplnum == 1) ? "" : "S")
				}

				for (new a = 0; a < pplnum; ++a)
				{
					format(team_name, 31, "%L", ppl[a], _teamname)
					format(message, 127, "%L", ppl[a], "REMAINING", epplnum, team_name)
					ShowSyncHudMsg(ppl[a], g_bottom_sync, "%s", message)
				}
			}
		}
	}

	if ((LastMan) || (LastManSound))
	{
		new cts[32], ts[32], ctsnum, tsnum
		new CsTeams:team

		for (new i=1; i<=g_maxplayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i))
			{
				continue
			}
			team = cs_get_user_team(i)
			if (team == CS_TEAM_T)
			{
				ts[tsnum++] = i
			} else if (team == CS_TEAM_CT) {
				cts[ctsnum++] = i
			}
		}
		
		if (ctsnum == 1 && tsnum == 1)
		{
			new ctname[32], tname[32]

			get_user_name(cts[0], ctname, 31)
			get_user_name(ts[0], tname, 31)

			if (LastMan)
			{
				set_hudmessage(0, 255, 255, -1.0, 0.36, 0, 6.0, 6.0, 0.5, 0.15, -1)
				for(new a = 0; a < plnum; ++a)
				{
					tempId = dm_ppl[a]
					if(g_DeathStats[tempId] > f_gametime)
						continue
					ShowSyncHudMsg(tempId, g_center1_sync, "%s vs. %s", ctname, tname)
				}
			}
			if(LastManSound) play_sound("misc/maytheforce")
		}
		else if (!g_LastAnnounce)
		{
			new oposite = 0, _team = 0

			if (ctsnum == 1 && tsnum > 1)
			{
				g_LastAnnounce = cts[0]
				oposite = tsnum
				_team = 0
			}
			else if (tsnum == 1 && ctsnum > 1)
			{
				g_LastAnnounce = ts[0]
				oposite = ctsnum
				_team = 1
			}

			if (g_LastAnnounce)
			{
				new name[32]
				get_user_name(g_LastAnnounce, name, 31)
				set_hudmessage(0, 255, 255, -1.0, 0.36, 0, 6.0, 6.0, 0.5, 0.15, -1)
				for(new a = 0; a < plnum; ++a)
				{
					tempId = dm_ppl[a]
					if(g_DeathStats[tempId] > f_gametime)
						continue
					ShowSyncHudMsg(tempId, g_center1_sync, "%s (%d HP) vs. %d %s%s: %L", name, get_user_health(g_LastAnnounce), oposite, g_teamsNames[_team], (oposite == 1) ? "" : "S", tempId, g_LastMessages[random_num(0, 3)])
				}
				if (!is_user_connecting(g_LastAnnounce))
				{
					client_cmd(g_LastAnnounce, "spk misc/oneandonly")
				}
			}
		}
	}

	if ((wpnindex == CSW_KNIFE) && (KnifeKill || KnifeKillSound))
	{
		if (KnifeKill)
		{
			new killer_name[32], victim_name[32]

			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)

			set_hudmessage(255, 100, 100, -1.0, 0.25, 1, 6.0, 6.0, 0.5, 0.15, -1)
			for(new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				ShowSyncHudMsg(tempId, g_he_sync, "%L", tempId, g_KinfeMsg[random_num(0, 3)], killer_name, victim_name)
			}
		}
		
		if (KnifeKillSound)
			play_sound("misc/humiliation")
	}

	if ((wpnindex == CSW_HEGRENADE) && (GrenadeKill || GrenadeSuicide))
	{
		new killer_name[32], victim_name[32]

		get_user_name(killer, killer_name, 31)
		get_user_name(victim, victim_name, 31)

		set_hudmessage(255, 100, 100, -1.0, 0.25, 1, 6.0, 6.0, 0.5, 0.15, -1)

		if (!selfkill)
		{
			if (GrenadeKill)
			{
				for(new a = 0; a < plnum; ++a)
				{
					tempId = dm_ppl[a]
					if(g_DeathStats[tempId] > f_gametime)
						continue
					ShowSyncHudMsg(0, g_he_sync, "%L", tempId, g_HeMessages[random_num(0, 3)], killer_name, victim_name)
				}
			}
		}
		else if (GrenadeSuicide)
		{
			for(new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				ShowSyncHudMsg(tempId, g_he_sync, "%L", tempId, g_SHeMessages[random_num(0, 3)], victim_name)
			}
		}
	}

	if (headshot && (HeadShotKill || HeadShotKillSound) && (wpnindex != CSW_KNIFE))
	{
		if (HeadShotKill && wpnindex)
		{
			new killer_name[32], victim_name[32], weapon_name[32], message[128]

			xmod_get_wpnname(wpnindex, weapon_name, 31)
			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)
			set_hudmessage(100, 100, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			for(new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue

				format(message, 127, "%L", tempId, g_HeadShots[random_num(0, 6)])
				replace(message, 127, "$vn", victim_name)
				replace(message, 127, "$wn", weapon_name)
				replace(message, 127, "$kn", killer_name)

				ShowSyncHudMsg(tempId, g_announce_sync, "%s", message)
			}
		}

		if (HeadShotKillSound)
		{
			client_cmd(killer, "spk misc/headshot")
			client_cmd(victim, "spk misc/headshot")
		}
	}

	if ((DoubleKill || DoubleKillSound) && !selfkill)
	{
		new Float:nowtime = get_gametime()

		if ((g_doubleKill == nowtime) && (g_doubleKillId == killer))
		{
			if (DoubleKill)
			{
				new name[32]
				get_user_name(killer, name, 31)
				set_hudmessage(255, 0, 255, -1.0, 0.36, 0, 6.0, 6.0, 0.5, 0.15, -1)
				for(new a = 0; a < plnum; ++a)
				{
					tempId = dm_ppl[a]
					if(g_DeathStats[tempId] > f_gametime)
						continue
					ShowSyncHudMsg(tempId, g_center1_sync, "%L", tempId, "DOUBLE_KILL", name)
				}
			}

			if (DoubleKillSound)
				play_sound("misc/doublekill")
		}
		
		g_doubleKill = nowtime
		g_doubleKillId = killer
	}

	if(g_FM_Running) {
		if(AirKill && !(pev(victim, pev_flags) & FL_ONGROUND) && !(pev(victim, pev_flags) & FL_PARTIALGROUND) && (killer != victim)) 
		{
			new killer_name[32], victim_name[32], message[128]
			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)
			set_hudmessage(100, 100, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			for (new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				format(message, 127, "%L", tempId, g_AirKillMessages[random_num(0,2)])
				replace(message, 127, "$vn", victim_name)
				replace(message, 127, "$kn", killer_name)
				ShowSyncHudMsg(tempId, g_announce_sync, "%s", message)
			}
		}
		if(WaterKill && ((pev(victim, pev_waterlevel) == 2) || (pev(victim, pev_waterlevel) == 3)) && killer != victim)
		{
			new killer_name[32], victim_name[32], message[128]
			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)
			set_hudmessage(100, 100, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			for (new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				format(message, 127, "%L", tempId, g_WaterKillMessages[random_num(0,2)])
				replace(message, 127, "$vn", victim_name)
				replace(message, 127, "$kn", killer_name)
				ShowSyncHudMsg(tempId, g_announce_sync, "%s", message)
			}
		}
		if(WallShot && (wpnindex != CSW_KNIFE) && (wpnindex != CSW_HEGRENADE) && (killer != victim) && !can_see_fm(killer, victim)) 
		{
			new killer_name[32], victim_name[32], message[128]
			get_user_name(killer, killer_name, 31)
			get_user_name(victim, victim_name, 31)
			set_hudmessage(100, 100, 255, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			for (new a = 0; a < plnum; ++a)
			{
				tempId = dm_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				format(message, 127, "%L", tempId, g_WallShotMessages[random_num(0,2)])
				replace(message, 127, "$vn", victim_name)
				replace(message, 127, "$kn", killer_name)
				ShowSyncHudMsg(tempId, g_announce_sync, "%s", message)
			}
		}
	}
}

public SuicideMsg()
{
	if(FallKill) 
	{
		new arg[64]
		read_logargv(0, arg, 63)
		new name[32]
		parse_loguser(arg, name, 31)
		new tempId
		new players[32], pnum
		get_players(players, pnum, "c")
		new Float:f_gametime = get_gametime()
		set_hudmessage(255, 100, 100, -1.0, 0.25, 1, 6.0, 6.0, 0.5, 0.15, -1)
		for(new i = 0; i < pnum; ++i) 
		{
			tempId = players[i]
			if(g_DeathStats[tempId] > f_gametime)
				continue
			ShowSyncHudMsg(tempId, g_he_sync, "%L", tempId, g_FallKillMessages[random_num(0,2)], name)
		}
	}
}

public client_kill(id) // need Engine... :(
{
	if(Suicide && is_user_alive(id)) 
	{
		new name[32]
		get_user_name(id, name, 31)
		new tempId
		new players[32], pnum
		get_players(players, pnum, "c")
		new Float:f_gametime = get_gametime()
		set_hudmessage(255, 100, 100, -1.0, 0.25, 1, 6.0, 6.0, 0.5, 0.15, -1)
		for(new i = 0; i < pnum; ++i) 
		{
			tempId = players[i]
			if(g_DeathStats[tempId] > f_gametime)
				continue
			ShowSyncHudMsg(tempId, g_he_sync, "%L", tempId, g_SuicideMessages[random_num(0,1)], name)
		}
	}
}

public hideStatus(id)
{
	if (PlayerName)
	{
		ClearSyncHud(id, g_status_sync)
	}
}

public setTeam(id)
	g_friend[id] = read_data(2)

public showStatus(id)
{
	if(!is_user_bot(id) && is_user_connected(id)) 
	{
		if (PlayerName)
		{
			new name[32], pid = read_data(2)
		
			get_user_name(pid, name, 31)
			new color1 = 0, color2 = 0
		
			if (get_user_team(pid) == 1)
				color1 = 255
			else
				color2 = 255
			
			if (g_friend[id] == 1)	// friend
			{
				new clip, ammo, wpnid = get_user_weapon(pid, clip, ammo)
				new wpnname[32]
			
				if (wpnid)
					xmod_get_wpnname(wpnid, wpnname, 31)
			
				set_hudmessage(color1, 50, color2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(id, g_status_sync, "%s -- %d HP / %d AP / %s", name, get_user_health(pid), get_user_armor(pid), wpnname)
			} else {
				set_hudmessage(color1, 50, color2, -1.0, 0.60, 1, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(id, g_status_sync, "%s", name)
			}
		}
	}
}

public eNewRound()
{
	if (read_data(1) == floatround(get_cvar_float("mp_roundtime") * 60.0,floatround_floor))
	{
		g_firstBlood = 1
		g_C4Timer = 0
		++g_roundCount
		
		if (RoundCounter)
		{
			set_hudmessage(200, 0, 0, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
			ShowSyncHudMsg(0, g_announce_sync, "%L", LANG_PLAYER, "PREPARE_FIGHT", g_roundCount)
		}
		
		if (RoundCounterSound)
			play_sound("misc/prepare")
		
		if (KillingStreakChat)
		{
			new appl[32], ppl, i
			get_players(appl, ppl, "ac")
			
			for (new a = 0; a < ppl; ++a)
			{
				i = appl[a]
				
				if (g_streakKills[i][0] >= 2)
					client_print(i, print_chat, "* %L", i, "KILLED_ROW", g_streakKills[i][0])
				else if (g_streakKills[i][1] >= 2)
					client_print(i, print_chat, "* %L", i, "DIED_ROUNDS", g_streakKills[i][1])
			}
		}
	}
}

public eRestart()
{
	eEndRound()
	g_roundCount = 0
	g_firstBlood = 1
	for(new a = 0; a < 33; ++a)
	{
		g_DeathStats[a] = 0.0
		g_kills[a] = 0
		g_deaths[a] = 0
		g_knife[a] = 0
		g_hs[a] = 0
		g_nade[a] = 0
		g_longestKillStreak[a] = 0
		g_longestDeathStreak[a] = 0
		g_multiKills[a] = {0, 0}
		g_streakKills[a] = {0, 0}
	}
}

public eEndRound()
{
//	g_C4Timer = -2
	g_LastOmg = 0.0
	remove_task(8038)
	g_LastAnnounce = 0
	set_task(0.3, "resetC4Timer", 978744)
}

public resetC4Timer()
{
	g_C4Timer = -2
}

public checkKills(param[])
{
	new id = param[0]
	new a = param[1]

	if (a == g_multiKills[id][0])
	{
		a -= 3
		if (a > 6)
		{
			a = 6
		}
		if (a > -1)
		{
			if (MultiKill)
			{
				new name[32]
				get_user_name(id, name, 31)
				new ck_ppl[32], plnum = 0
				get_players(ck_ppl, plnum, "c")
				new tempId
				new Float:f_gametime = get_gametime()
				set_hudmessage(255, 0, 100, 0.05, 0.50, 2, 0.02, 6.0, 0.01, 0.1, -1)
				for(new i = 0; i < plnum; ++i)
				{
					tempId = ck_ppl[i]
					if(g_DeathStats[tempId] > f_gametime)
					{
						continue
					}
					ShowSyncHudMsg(tempId, g_left_sync, g_MultiKillMsg[a], name, tempId, "WITH", g_multiKills[id][0], tempId, "KILLS", g_multiKills[id][1], tempId, "HS")
				}
			}
			
			if (MultiKillSound)
			{
				new sound[24]
				format(sound, 23, "misc/%s", g_Sounds[a])
				play_sound(sound)
			}
		}
		g_multiKills[id] = {0, 0}
	}
}

public chickenKill()
{
	if (ItalyBonusKill)
		announceEvent(0, "KILLED_CHICKEN")
}

public radioKill()
{
	if (ItalyBonusKill)
		announceEvent(0, "BLEW_RADIO")
}

announceEvent(id, message[])
{
	new name[32]
	new tempId
	new Float:f_gametime = get_gametime()
	get_user_name(id, name, 31)
	new players[32], pnum
	get_players(players, pnum, "c")
	set_hudmessage(255, 100, 50, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
	for(new i = 0; i < pnum; ++i)
	{
		tempId = players[i]
		if(g_DeathStats[tempId] > f_gametime)
      continue
		ShowSyncHudMsg(tempId, g_announce_sync, "%L", tempId, message, name)
	}
}

announceEventDef(id,message[],C4Timer)
{
	new name[32]
	new Float:f_gametime = get_gametime()
	get_user_name(id, name, 31)
	new players[32], pnum
	new tempId
	get_players(players, pnum, "c")
	set_hudmessage(255, 100, 50, -1.0, 0.30, 0, 6.0, 6.0, 0.5, 0.15, -1)
	for(new i = 0; i < pnum; ++i)
	{
		tempId = players[i]
		if(g_DeathStats[tempId] > f_gametime)
      continue
		ShowSyncHudMsg(tempId, g_announce_sync, "%L", tempId, message, name, C4Timer)
	}
}

public eBombPickUp(id)
{
	if (BombPickUp)
		announceEvent(id, "PICKED_BOMB")
}

public eBombDrop()
{
	if (BombDrop)
		announceEvent(g_Planter, "DROPPED_BOMB")
}

public eGotBomb(id)
{
	g_Planter = id
	if (BombReached && read_data(1) == 2 && g_LastOmg < get_gametime())
	{
		g_LastOmg = get_gametime() + 15.0
		announceEvent(g_Planter, "REACHED_TARGET")
	}
}

public bombTimer()
{
	if (--g_C4Timer > 0)
	{
		if (BombCountVoice)
		{
			if (g_C4Timer == 40 || g_C4Timer == 30 || g_C4Timer == 20)
			{
				new temp[64]
				
				num_to_word(g_C4Timer, temp, 63)
				format(temp, 63, "^"vox/%s seconds until explosion^"", temp)
				play_sound(temp)
			}
			else if (g_C4Timer < 11)
			{
				new temp[64]
				
				num_to_word(g_C4Timer, temp, 63)
				format(temp, 63, "^"vox/%s^"", temp)
				play_sound(temp)
			}
		}
		if (BombCountDef && g_Defusing)
			client_print(g_Defusing, print_center, "%d", g_C4Timer)
		if (BombCountHUD)
		{ 
			if(g_C4Timer < 7) set_hudmessage(150, 0, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1)
			if(g_C4Timer > 6) set_hudmessage(150, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1)
			if(g_C4Timer > 11) set_hudmessage(0, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1)
			new bt_ppl[32], plnum = 0
			get_players(bt_ppl, plnum, "c")
			new tempId
			new Float:f_gametime = get_gametime()
			for(new a = 0; a < plnum; ++a)
			{
				tempId = bt_ppl[a]
				if(g_DeathStats[tempId] > f_gametime)
					continue
				ShowSyncHudMsg(tempId, g_bomb_hud_sync,"C4: %d",g_C4Timer)
			}
		}
	}
	else
		remove_task(8038)
}

public bomb_planted(planter)
{
	g_Defusing = 0
	
	if (BombPlanted)
		announceEvent(planter, "SET_UP_BOMB")

	g_C4Timer = g_mp_c4timer
	set_task(1.0, "bombTimer", 8038, "", 0, "b")
}

public bomb_planting(planter)
{
	if (BombPlanting)
		announceEvent(planter, "PLANT_BOMB")
}

public bomb_defusing(defuser)
{
	if (BombDefusing)
		announceEvent(defuser, "DEFUSING_BOMB")
	g_Defusing = defuser
}

public bomb_defused(defuser)
{
	if (BombDefused)
		announceEventDef(defuser, "DEFUSED_BOMB", g_C4Timer)
}

public bomb_explode(planter, defuser)
{
	if (BombFailed && defuser)
		announceEvent(defuser, "FAILED_DEFU")
}

public play_sound(sound[])
{
	new players[32], pnum
	get_players(players, pnum, "c")
	new i
	
	for (i = 0; i < pnum; i++)
	{
		if (is_user_connecting(players[i]))
			continue
		
		client_cmd(players[i], "spk %s", sound)
	}
}

public eResetHud(id)
{
	remove_task(12345+id)

	if(g_kills[id] > 0) 
	{
		if(KillingStreakHUD) 
		{
			new param[8]
			param[0] = id
			param[1] = g_kills[id]
			param[2] = g_hs[id]
			param[3] = g_nade[id]
			param[4] = g_knife[id]
			param[5] = g_longestKillStreak[id]
			param[6] = g_longestDeathStreak[id]
			param[7] = 0
			set_task(g_mp_freezetime + 2.0, "showKillingStreakHud", 987654+id, param, 8)
		}
	}
	else 
	{
		if(KillingStreakHUD) 
		{
			new param[4]
			param[0] = id
			param[1] = g_deaths[id]
			param[2] = g_longestKillStreak[id]
			param[3] = g_longestDeathStreak[id]
			set_task(g_fHUDDuration + 2.0, "showDeathStreakHud", 876543+id, param, 4)
		}
	}
	return PLUGIN_CONTINUE
}

public cmdKillingStreak(id)
{
	if(!KillingStreakSay) {
		client_print(id, print_chat, "%L", id, "DISABLED_MSG")
		return PLUGIN_HANDLED
  }
	if(KillingStreakHUD)
	{
		if(g_kills[id] > 0)
		{
			new param[8]
			param[0] = id
			param[1] = g_kills[id]
			param[2] = g_hs[id]
			param[3] = g_nade[id]
			param[4] = g_knife[id]
			param[5] = g_longestKillStreak[id]
			param[6] = g_longestDeathStreak[id]
			param[7] = 0
			showKillingStreakHud(param)
		}
		else 
		{
			new param[4]
			param[0] = id
			param[1] = g_deaths[id]
			param[2] = g_longestKillStreak[id]
			param[3] = g_longestDeathStreak[id]
			showDeathStreakHud(param)
		}
	}
	return PLUGIN_HANDLED
}

public showKillingStreakHud(param[])
{
	new player = param[0]
	if(!is_user_connected(player))
		return PLUGIN_CONTINUE
	new l_kills = param[1]
	new l_hs = param[2]
	new l_nade = param[3]
	new l_knife = param[4]
	new l_longkstreak = param[5]
	new l_longdstreak = param[6]
	new l_end = param[7]
	set_hudmessage(0, 150, 0, 0.02, 0.80, 2, 0.05, 0.1, 0.01, 6.0, -1)
	new sBuffer[256]
	new iLen = 0
	new szTemp1[20], szTemp2[20], szTemp3[20], szTemp4[20]

	format(szTemp1, 19, "%L", player, (l_kills != 1) ? "KILLS" : "KILL")
	if (l_end)
	{
		iLen = format(sBuffer, 255, "%L", player, "LATEST_KILLSTREAK", l_kills, szTemp1)
	}
	else 
	{
		iLen = format(sBuffer, 255, "%L", player, "CURRENT_STREAK", l_kills, szTemp1)
	}
	if(l_hs || l_nade || l_knife) 
	{
		iLen += format(sBuffer[iLen], 255-iLen, " (")
		if(l_hs)
		{
			format(szTemp2, 19, "%L", player, "HS")
 			iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_hs, szTemp2)
		}
		if(l_nade)
		{
			format(szTemp3, 19, "%L", player, (l_nade>1) ? "NADES" : "NADE")
			iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_nade, szTemp3)
		}
		if(l_knife)
		{
			format(szTemp4, 19, "%L", player, (l_knife>1) ? "KNIVES" : "KNIFE")
			iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_knife, szTemp4)
		}
		iLen -= 1
		iLen += format(sBuffer[iLen], 255-iLen, ")")
	}
	iLen += format(sBuffer[iLen], 255-iLen, "^n%L", player, "LONGEST_STREAK", l_longkstreak, l_longdstreak)
	ShowSyncHudMsg(player, g_bottom_sync, "%s", sBuffer)
	return PLUGIN_CONTINUE
}

public showDeathStreakHud(param[])
{
	new player = param[0]
	if ((!is_user_connected(player)) || (player <= 0))
		return PLUGIN_CONTINUE
	new l_deaths = param[1]
	new l_longkstreak = param[2]
	new l_longdstreak = param[3]
	set_hudmessage(150, 150, 0, 0.02, 0.80, 2, 0.05, 0.1, 0.01, 6.0, -1)
	new sBuffer[256]
	new iLen = 0
	new szTemp1[20]

	format(szTemp1, 19, "%L", player, (l_deaths != 1) ? "DEATHS" : "DEATH")
	iLen = format(sBuffer, 255, "%L", player, "CURRENT_STREAK", l_deaths, szTemp1)
	iLen += format(sBuffer[iLen], 255-iLen, "^n%L", player, "LONGEST_STREAK", l_longkstreak, l_longdstreak)
	ShowSyncHudMsg(player, g_bottom_sync, "%s", sBuffer)
	return PLUGIN_CONTINUE
}

public showKillingStreakEndHud(param[])
{
	set_hudmessage(0, 150, 255, 0.73, 0.65, 2, 0.02, 8.0, 0.01, 6.0, -1)
	new l_victim = param[0]
	new l_killer = param[1]
	new l_kills = param[2]
	new l_hs = param[3]
	new l_nade = param[4]
	new l_knife = param[5]
	new l_vname[32]
	get_user_name(l_victim, l_vname, 31)
	new l_kname[32]
	get_user_name(l_killer, l_kname, 31)
	new sBuffer[256]
	new iLen = 0
	new szTemp2[20], szTemp3[20], szTemp4[20]
	new pl[32], plnum, tempId
	get_players(pl, plnum, "c")
	for(new a = 0; a < plnum; ++a)
	{
		tempId = pl[a]
		iLen = format(sBuffer, 255, "%L", tempId, "PLAYER_KILLING_SPREE", l_vname, l_kills)
		if(l_hs || l_nade || l_knife) 
		{
			iLen += format(sBuffer[iLen], 255-iLen, " (")
			if(l_hs)
			{
				format(szTemp2, 19, "%L", tempId, "HS")
 				iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_hs, szTemp2)
			}
			if(l_nade)
			{
				format(szTemp3, 19, "%L", tempId, (l_nade>1) ? "NADES" : "NADE")
				iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_nade, szTemp3)
			}
			if(l_knife)
			{
				format(szTemp4, 19, "%L", tempId, (l_knife>1) ? "KNIVES" : "KNIFE")
				iLen += format(sBuffer[iLen], 255-iLen, "%d %s,", l_knife, szTemp4)
			}
			iLen -= 1
			iLen += format(sBuffer[iLen], 255-iLen, ")")
		}
		iLen += format(sBuffer[iLen], 255-iLen, "%L", tempId, "ENDED_BY", l_kname)
		ShowSyncHudMsg(tempId, g_kill_end_sync, "%s", sBuffer)
	}
	return PLUGIN_CONTINUE
}
