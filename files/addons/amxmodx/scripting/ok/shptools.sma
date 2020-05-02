/*	Copyright © 2006, Space Headed Productions

	SHP Tools is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with SHP Tools; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hlsdk_const>

new const PLUGIN[] = "SHP Tools"
new const VERSION[] = "1.0"
new const AUTHOR[] = "Space Headed"

#define HOOK_NONE		0
#define HOOK_SPAWN		(1<<0)
#define HOOK_THINK		(1<<1)
#define HOOK_USE		(1<<2)
#define HOOK_TOUCH		(1<<3)
#define HOOK_BLOCKED	(1<<4)
#define HOOK_KEYVALUE	(1<<5)
#define HOOK_SETABSBOX	(1<<6)
#define HOOK_ALERT		(1<<7)

new cvar_api
new cvar_msg
new cvar_log

new bool:hook_this_message
new logfile[128]
new Tracer[33]
new Float:TracerTime[33]
new beam_texture

public plugin_precache()
{
	cvar_api = register_cvar("hook_api", "", FCVAR_EXTDLL)
	cvar_msg = register_cvar("hook_msg", "", FCVAR_EXTDLL)
	cvar_log = register_cvar("logfile", "0", FCVAR_EXTDLL)
	beam_texture = precache_model("sprites/lgtning.spr")

	new mapname[32]
	get_mapname(mapname, 31)
	UTIL_ServerConsole_Printf("-------- %s Loaded --------", PLUGIN)

	register_forward(FM_Spawn, "Spawn")
	register_forward(FM_Think, "Think")
	register_forward(FM_Use, "Use", 1)
	register_forward(FM_Touch, "Touch")
	register_forward(FM_Blocked, "Blocked")
	register_forward(FM_KeyValue, "KeyValue")
	register_forward(FM_SetAbsBox, "SetAbsBox")
	
	register_forward(FM_AlertMessage, "AlertMessage")
	register_forward(FM_MessageBegin, "MessageBegin")
	register_forward(FM_MessageEnd, "MessageEnd")
	register_forward(FM_WriteByte, "WriteByte")
	register_forward(FM_WriteChar, "WriteChar")
	register_forward(FM_WriteShort, "WriteShort")
	register_forward(FM_WriteLong, "WriteLong")
	register_forward(FM_WriteAngle, "WriteAngle")
	register_forward(FM_WriteCoord, "WriteCoord")
	register_forward(FM_WriteString, "WriteString")
	register_forward(FM_WriteEntity, "WriteEntity")
	
	register_forward(FM_TraceLine, "TraceLine_Post", 1)
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("drawent", "ClientCommand_DrawEnt", ADMIN_RCON, "- draws a box around an entity")
	register_clcmd("traceent", "ClientCommand_EntTracer", ADMIN_RCON, "- traces what entity your viewing")
	register_srvcmd("listapi", "ServerCommand_ListApi")
	register_srvcmd("printapi", "ServerCommand_PrintApi")
	register_srvcmd("listent", "ServerCommand_ListEnt")
	register_srvcmd("printent", "ServerCommand_PrintEnt")
	register_srvcmd("listmsg", "ServerCommand_ListMsg")
	register_srvcmd("printmsg", "ServerCommand_PrintMsg")
	register_srvcmd("printlog", "ServerCommand_PrintLog")
}

public plugin_pause()
{
	UTIL_ServerConsole_Printf("-------- %s Paused --------", PLUGIN)
}

public plugin_unpause()
{
	UTIL_ServerConsole_Printf("-------- %s Unpaused --------", PLUGIN)
}

// Api Hooks
public TraceLine_Post(Float:v1[3], Float:v2[3], noMonsters, pEnt)
{
	if(is_user_connected(pEnt))
	{
		static Float:g_time
		global_get(glb_time, g_time)
		if(Tracer[pEnt] && g_time > TracerTime[pEnt])
		{
			TracerTime[pEnt] = g_time + 1.0

			static entity
			entity = get_tr(TR_pHit)
			if(pev_valid(entity))
			{
				static classname[32]
				pev(entity, pev_classname, classname, 31)
				client_print(pEnt, print_chat, "Entity Index: %i", entity)
				client_print(pEnt, print_chat, "Classname: %s", classname)
				client_print(pEnt, print_chat, " ")	
			}
		}
	}
}

public Spawn(id)
{
	if(pev_valid(id))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_SPAWN))
		{
			static classname[32]
			pev(id, pev_classname, classname, 31)

			static netname[32]
			pev(id, pev_netname, netname, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") SPAWNS", id, (netname[0] != 0) ? netname : classname)
		}
	}
}

public Think(id)
{
	if(pev_valid(id))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_THINK))
		{
			static classname[32]
			pev(id, pev_classname, classname, 31)

			static netname[32]
			pev(id, pev_netname, netname, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") THINKS", id, (netname[0] != 0) ? netname : classname)
		}
	}
}

public Use(pUsed, pOther)
{
	if(pev_valid(pUsed) && pev_valid(pOther))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_USE))
		{
			static classname1[32], classname2[32]
			pev(pUsed, pev_classname, classname1, 31)
			pev(pOther, pev_classname, classname2, 31)

			static netname1[32], netname2[32]
			pev(pUsed, pev_netname, netname1, 31)
			pev(pOther, pev_netname, netname2, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") USES Entity %d (^"%s^")", pUsed, (netname1[0] != 0) ? netname1 : classname1, pOther, (netname2[0] != 0) ? netname2 : classname2)
		}
	}
}

public Touch(pTouched, pOther)
{
	if(pev_valid(pTouched) && pev_valid(pOther))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_TOUCH))
		{
			static classname1[32], classname2[32]
			pev(pTouched, pev_classname, classname1, 31)
			pev(pOther, pev_classname, classname2, 31)

			static netname1[32], netname2[32]
			pev(pTouched, pev_netname, netname1, 31)
			pev(pOther, pev_netname, netname2, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") TOUCHES Entity %d (^"%s^")", pTouched, (netname1[0] != 0) ? netname1 : classname1, pOther, (netname2[0] != 0) ? netname2 : classname2)
		}
	}
}

public Blocked(pBlocked, pOther)
{
	if(pev_valid(pBlocked) && pev_valid(pOther))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_BLOCKED))
		{
			static classname1[32], classname2[32]
			pev(pBlocked, pev_classname, classname1, 31)
			pev(pOther, pev_classname, classname2, 31)

			static netname1[32], netname2[32]
			pev(pBlocked, pev_netname, netname1, 31)
			pev(pOther, pev_netname, netname2, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") BLOCKS Entity %d (^"%s^")", pBlocked, (netname1[0] != 0) ? netname1 : classname1, pOther, (netname2[0] != 0) ? netname2 : classname2)
		}
	}
}

public KeyValue(pKeyvalue, kvd_handle)
{
	if(pev_valid(pKeyvalue))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_KEYVALUE))
		{
			static classname[32]
			pev(pKeyvalue, pev_classname, classname, 31)

			static netname[32]
			pev(pKeyvalue, pev_netname, netname, 31)

			static szClassName[32], szKeyName[32], szValue[32]
			get_kvd(kvd_handle, KV_ClassName, szClassName, 31)
			get_kvd(kvd_handle, KV_KeyName, szKeyName, 31)
			get_kvd(kvd_handle, KV_Value, szValue, 31)
		
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") SETS KEY ^"%s^" TO VALUE ^"%s^" FOR Classname ^"%s^"", pKeyvalue, (netname[0] != 0) ? netname : classname, szKeyName, szValue, szClassName)
		}
	}
}

public SetAbsBox(id)
{
	if(pev_valid(id))
	{
		if(UTIL_ReadCvar(cvar_api, HOOK_SETABSBOX))
		{
			static classname[32]
			pev(id, pev_classname, classname, 31)

			static netname[32]
			pev(id, pev_netname, netname, 31)
			UTIL_ServerConsole_Printf("Entity %d (^"%s^") SETS OBJECT COLLISION BOX", id, (netname[0] != 0) ? netname : classname)
		}
	}
}

// Engine Hooks
public AlertMessage(atype, const fmt[])
{
	if(UTIL_ReadCvar(cvar_api, HOOK_ALERT))
	{
		static buffer[1024]
		formatex(buffer, 1023, fmt)
		buffer[strlen(buffer)-1] = 0
		UTIL_ServerConsole_Printf("ALERT MESSAGE (%s): %s", UTIL_atype(atype), buffer)
	}
}

public MessageBegin(msg_dest, msg_type, Float:pOrigin[3], ed)
{
	static cmessage[128]
	get_pcvar_string(cvar_msg, cmessage, 127)

	if(cmessage[0] != 0)
	{
		static msg1[16], msg2[16], msg3[16], msg4[16], msg5[16]
		parse(cmessage, msg1, 15, msg2, 15, msg3, 15, msg4, 15, msg5, 15)

		static bmessage[16]
		get_user_msgname(msg_type, bmessage, 15)

		if(equali(msg1, "All") || equali(msg1, bmessage) || equali(msg2, bmessage) || equali(msg3, bmessage) || equali(msg4, bmessage) || equali(msg5, bmessage))
		{
			static msgdest[32]
			if(msg_dest == MSG_BROADCAST) msgdest = "MSG_BROADCAST"
			else if(msg_dest == MSG_ONE) msgdest = "MSG_ONE"
			else if(msg_dest == MSG_ALL) msgdest = "MSG_ALL"
			else if(msg_dest == MSG_INIT) msgdest = "MSG_INIT"
			else if(msg_dest == MSG_PVS) msgdest = "MSG_PVS"
			else if(msg_dest == MSG_PAS) msgdest = "MSG_PAS"
			else if(msg_dest == MSG_PVS_R) msgdest = "MSG_PVS_R"
			else if(msg_dest == MSG_PAS_R) msgdest = "MSG_PAS_R"
			else if(msg_dest == MSG_ONE_UNRELIABLE) msgdest = "MSG_ONE_UNRELIABLE"
			else if(msg_dest == MSG_SPEC) msgdest = "MSG_SPEC"
			else msgdest = "UNKNOWN"
			
			UTIL_ServerConsole_Printf("message_begin(%s, get_user_msgid(^"%s^"), {%i,%i,%i}, %i)", msgdest, bmessage, floatround(pOrigin[0]), floatround(pOrigin[1]), floatround(pOrigin[2]), ed)
			hook_this_message = true
		}
	}
}

public MessageEnd()
{
	if(hook_this_message) UTIL_ServerConsole_Printf("message_end()")
	hook_this_message = false
}

public WriteByte(iValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_byte(%d)", iValue)
}

public WriteChar(iValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_char(%d)", iValue)
}

public WriteShort(iValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_short(%d)", iValue)
}

public WriteLong(iValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_long(%d)", iValue)
}

public WriteAngle(Float:flValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_angle(%.2f)", flValue)
}

public WriteCoord(Float:flValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_coord(%.2f)", flValue)
}

public WriteString(szValue[])
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_string(^"%s^")", szValue)
}

public WriteEntity(iValue)
{
	if(hook_this_message) UTIL_ServerConsole_Printf("write_entity(%d)", iValue)
}

// Commands
public ClientCommand_EntTracer(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_CONTINUE
	
	new temp[8]
	read_argv(1, temp, 7)
	new cmd = str_to_num(temp)
	
	if(cmd == 1 && Tracer[id] == 0)
	{
		Tracer[id] = 1
		client_print(id, print_chat, "Entity Tracer Enabled: Go look at something")
	}
	else if(cmd == 0 && Tracer[id] == 1)
	{
		Tracer[id] = 0
		client_print(id, print_chat, "Entity Tracer Disabled")
	}
	return PLUGIN_HANDLED
}

public ClientCommand_DrawEnt(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2)) return PLUGIN_CONTINUE
	
	new temp[8]
	read_argv(1, temp, 7)
	new ent = str_to_num(temp)

	if(pev_valid(ent))
	{
		new Float:absmin[3], Float:absmax[3], Float:size[3]
		pev(ent, pev_absmin, absmin)
		pev(ent, pev_absmax, absmax)
		size[0] = absmax[0] - absmin[0]
		size[1] = absmax[1] - absmin[1]
		size[2] = absmax[2] - absmin[2]
	
		UTIL_DrawBeam(id, absmin[0], absmin[1], absmin[2], absmin[0] + size[0], absmin[1], absmin[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1], absmin[2], absmin[0], absmin[1] + size[1], absmin[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1], absmin[2], absmin[0], absmin[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0] + size[0], absmin[1] + size[1], absmin[2] + size[2], absmin[0], absmin[1] + size[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0] + size[0], absmin[1] + size[1], absmin[2] + size[2], absmin[0] + size[0], absmin[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0] + size[0], absmin[1] + size[1], absmin[2] + size[2], absmin[0] + size[0], absmin[1] + size[1], absmin[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0] + size[0], absmin[1], absmin[2], absmin[0] + size[0], absmin[1] + size[1], absmin[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0] + size[0], absmin[1], absmin[2], absmin[0] + size[0], absmin[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1] + size[1], absmin[2], absmin[0] + size[0], absmin[1] + size[1], absmin[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1] + size[1], absmin[2], absmin[0], absmin[1] + size[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1], absmin[2] + size[2], absmin[0] + size[0], absmin[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
		UTIL_DrawBeam(id, absmin[0], absmin[1], absmin[2] + size[2], absmin[0], absmin[1] + size[1], absmin[2] + size[2], 2000, 10, 0, 0, 255, 0, 255, 0)
	}
	return PLUGIN_HANDLED
}

public ServerCommand_ListApi()
{
	server_print("Available APIs...")
	server_print("none (Flag: ^"^")")
	server_print("pfnSpawn (Flag: ^"a^")")
	server_print("pfnThink (Flag: ^"b^")")
	server_print("pfnUse (Flag: ^"c^")")
	server_print("pfnTouch (Flag: ^"d^")")
	server_print("pfnBlocked (Flag: ^"e^")")
	server_print("pfnKeyValue (Flag: ^"f^")")
	server_print("pfnSetAbsBox (Flag: ^"g^")")
	server_print("pfnAlertMessage (Flag: ^"h^")")
	server_print("^nUsage: hook_api ^"afh^"")
}

public ServerCommand_PrintApi()
{
	new flags[31]
	get_pcvar_string(cvar_api, flags, 31)

	new hooks[128], len
	if(read_flags(flags) == HOOK_NONE) len += formatex(hooks[len], 128-len, "HOOK_NONE | ")
	if(read_flags(flags) & HOOK_SPAWN) len += formatex(hooks[len], 128-len, "HOOK_SPAWN | ")
	if(read_flags(flags) & HOOK_THINK) len += formatex(hooks[len], 128-len, "HOOK_THINK | ")
	if(read_flags(flags) & HOOK_USE) len += formatex(hooks[len], 128-len, "HOOK_USE | ")
	if(read_flags(flags) & HOOK_TOUCH) len += formatex(hooks[len], 128-len, "HOOK_TOUCH | ")
	if(read_flags(flags) & HOOK_BLOCKED) len += formatex(hooks[len], 128-len, "HOOK_BLOCKED | ")
	if(read_flags(flags) & HOOK_KEYVALUE) len += formatex(hooks[len], 128-len, "HOOK_KEYVALUE | ")
	if(read_flags(flags) & HOOK_SETABSBOX) len += formatex(hooks[len], 128-len, "HOOK_SETABSBOX | ")
	if(read_flags(flags) & HOOK_ALERT) len += formatex(hooks[len], 128-len, "HOOK_ALERT | ")
	hooks[strlen(hooks)-3] = 0
	server_print("Currently Hooking: ^"%s^" (%s)", flags, hooks)
}

public ServerCommand_ListEnt()
{
	UTIL_ServerConsole_Printf("Printing out ALL entities in game...")
	UTIL_ServerConsole_Printf("index CLASSNAME [^"netname^"] (model): absmin (x, y, z); size (x, y, z);")
	
	new maxentities = global_get(glb_maxEntities)
	new bool:is_player, classname[32], index
	for(index = 0; index < maxentities; ++index)
	{
		if(!pev_valid(index)) continue
		is_player = false
		pev(index, pev_classname, classname, 31)
		
		new netname[32], model[64], Float:absmin[3], Float:size[3]
		pev(index, pev_netname, netname, 31)
		pev(index, pev_model, model, 63)
		pev(index, pev_absmin, absmin)
		pev(index, pev_size, size)
		if(equal(classname, "player")) is_player = true

		if(is_player) server_print("%d %s ^"%s^" (%s): min (%.0f, %.0f, %.0f); siz (%.0f, %.0f, %.0f);", index, classname, netname, model, absmin[0], absmin[1], absmin[2], size[0], size[1], size[2])
		else server_print("%d %s (%s): min (%.0f, %.0f, %.0f); siz (%.0f, %.0f, %.0f);", index, classname, model, absmin[0], absmin[1], absmin[2], size[0], size[1], size[2])
	}
	server_print("End of list - %d entities found.", maxentities)
}

public ServerCommand_PrintEnt()
{
	new arg0[128], arg1[128]
	read_argv(0, arg0, 127)
	read_argv(1, arg1, 127)
	if(arg1[0] == 0)
	{
		server_print("Usage: ^"%s INDEX_OF_ENTITY^"", arg0)
		return
	}
	new index = str_to_num(arg1)
	if(index != 0 && !pev_valid(index))
	{
		server_print("%s: entity #%d is unregistered", arg0, index)
		return	
	}
	new temp[128], temp2[128], temp3, Float:fValue, Float:vValue[3], Float:vValue2[3]
	server_print("Printing out entity #%d variable information...", index)
	server_print("(variable name = value (meaning))")
	pev(index, pev_classname, temp3, temp, 127)
	server_print("pev_classname = %d (^"%s^")", temp3, temp)
	pev(index, pev_globalname,  temp3, temp, 127)
	server_print("pev_globalname = %d (^"%s^")", temp3, temp)
	pev(index, pev_origin, vValue)
	server_print("pev_origin = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_oldorigin, vValue)
	server_print("pev_oldorigin = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_velocity , vValue)
	vValue2 = vValue; vValue2[2] = 0.0
	server_print("pev_velocity = Vector (%.1f, %.1f, %.1f) - Length %.3f - Length2D %.3f", vValue[0], vValue[1], vValue[2], vector_length(vValue), vector_length(vValue2))
	pev(index, pev_basevelocity, vValue)
	vValue2 = vValue; vValue2[2] = 0.0
	server_print("pev_basevelocity = Vector (%.1f, %.1f, %.1f) - Length %.3f - Length2D %.3f", vValue[0], vValue[1], vValue[2], vector_length(vValue), vector_length(vValue2))
	pev(index, pev_clbasevelocity, vValue)
	vValue2 = vValue; vValue2[2] = 0.0
	server_print("pev_clbasevelocity = Vector (%.1f, %.1f, %.1f) - Length %.3f - Length2D %.3f", vValue[0], vValue[1], vValue[2], vector_length(vValue), vector_length(vValue2))
	pev(index, pev_movedir, vValue)
	server_print("pev_movedir = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_angles, vValue)
	server_print("pev_angles = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_avelocity, vValue)
	vValue2 = vValue; vValue2[2] = 0.0
	server_print("pev_avelocity = Vector (%.1f, %.1f, %.1f) - Length %.3f - Length2D %.3f", vValue[0], vValue[1], vValue[2], vector_length(vValue), vector_length(vValue2))
	pev(index, pev_punchangle, vValue)
	server_print("pev_punchangle = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_v_angle, vValue)
	server_print("pev_v_angle = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_endpos, vValue)
	server_print("pev_endpos = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_startpos, vValue)
	server_print("pev_startpos = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_impacttime, fValue)
	server_print("pev_impacttime = %.3f", fValue)
	pev(index, pev_starttime, fValue)
	server_print("pev_starttime = %.3f", fValue)
	server_print("pev_fixangle = %d (%s)", pev(index, pev_fixangle), UTIL_fixangle(pev(index, pev_fixangle)))
	pev(index, pev_idealpitch, fValue)
	server_print("pev_idealpitch = %.3f", fValue)
	pev(index, pev_pitch_speed, fValue)
	server_print("pev_pitch_speed = %.3f", fValue)
	pev(index, pev_ideal_yaw, fValue)
	server_print("pev_ideal_yaw = %.3f", fValue)
	pev(index, pev_yaw_speed, fValue)
	server_print("pev_yaw_speed = %.3f", fValue)
	server_print("pev_modelindex = %d", pev(index, pev_modelindex))
	pev(index, pev_model, temp3, temp, 127)
	server_print("pev_model = %d (^"%s^")", temp3, temp)
	temp3 = pev(index, pev_viewmodel)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_viewmodel = %d (^"%s^")", temp3, temp)
	temp3 = pev(index, pev_weaponmodel)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_weaponmodel = %d (^"%s^")", temp3, temp)
	pev(index, pev_absmin, vValue)
	server_print("pev_absmin = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_absmax, vValue)
	server_print("pev_absmax = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_mins, vValue)
	server_print("pev_mins = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_maxs, vValue)
	server_print("pev_maxs = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_size, vValue)
	server_print("pev_size = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_ltime, fValue)
	server_print("pev_ltime = %.3f (current time is %.3f)", fValue, get_gametime())
	pev(index, pev_nextthink, fValue)
	server_print("pev_nextthink = %.3f (current time is %.3f)", fValue, get_gametime())
	server_print("pev_movetype = %d (%s)", pev(index, pev_movetype), UTIL_movetype(pev(index, pev_movetype)))
	server_print("pev_solid = %d (%s)", pev(index, pev_solid), UTIL_solid(pev(index, pev_solid)))
	temp3 = pev(index, pev_skin)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_skin = %d (^"%s^")", pev(index, pev_skin), temp)
	temp3 = pev(index, pev_body)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_body = %d (^"%s^")", pev(index, pev_body), temp)
	server_print("pev_effects = %d (%s)", pev(index, pev_effects), UTIL_effects(pev(index, pev_effects)))
	pev(index, pev_gravity, fValue)
	server_print("pev_gravity = %.3f (fraction /1 of normal)", fValue)
	pev(index, pev_friction, fValue)
	server_print("pev_friction = %.3f", fValue)
	server_print("pev_light_level = %d", pev(index, pev_light_level))
	temp3 = pev(index, pev_sequence)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_sequence = %d (^"%s^")", temp3, temp)
	temp3 = pev(index, pev_gaitsequence, temp, 127)
	global_get(glb_pStringBase, temp3, temp, 127)
	server_print("pev_gaitsequence = %d (^"%s^")", temp3, temp)
	pev(index, pev_frame, fValue)
	server_print("pev_frame = %.3f (position /255 of total in sequence)", fValue)
	pev(index, pev_animtime, fValue)
	server_print("pev_animtime = %.3f (current time is %.3f)", fValue, get_gametime())
	pev(index, pev_framerate, fValue)
	server_print("pev_framerate = %.3f (times normal speed)", fValue)
	server_print("pev_controller = {%d, %d, %d, %d}", pev(index, pev_controller_0), pev(index, pev_controller_1), pev(index, pev_controller_2), pev(index, pev_controller_3))
	server_print("pev_blending = {%d, %d}", pev(index, pev_blending_0), pev(index, pev_blending_1))
	pev(index, pev_scale, fValue)
	server_print("pev_scale = %.3f", fValue)
	server_print("pev_rendermode = %d (%s)", pev(index, pev_rendermode), UTIL_rendermode(pev(index, pev_rendermode)))
	pev(index, pev_renderamt, fValue)
	server_print("pev_renderamt = %.3f", fValue)
	pev(index, pev_rendercolor, vValue)
	server_print("pev_rendercolor = Vector (%.1f, %.1f, %.1f) (RGB)", vValue[0], vValue[1], vValue[2])
	server_print("pev_renderfx = %d (%s)", pev(index, pev_renderfx), UTIL_renderfx(pev(index, pev_renderfx)))
	pev(index, pev_health, fValue)
	server_print("pev_health = %.3f", fValue)
	pev(index, pev_frags, fValue)
	server_print("pev_frags = %.3f", fValue)
	temp = "00000000000000000000000000000000"
	temp3 = pev(index, pev_weapons)
	for(new i = 1; i <= 32; i++) if(temp3 & (1<<i)) temp[i-1] = '1'
	server_print("pev_weapons = %u (%s)", temp3, temp)
	pev(index, pev_takedamage, fValue)
	server_print("pev_takedamage = %.1f (%s)", fValue, UTIL_takedamage(floatround(fValue)))
	server_print("pev_deadflag = %d (%s)", pev(index, pev_deadflag), UTIL_deadflag(pev(index, pev_deadflag)))
	pev(index, pev_view_ofs, vValue)
	server_print("pev_view_ofs = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	server_print("pev_button = %d (%s)", pev(index, pev_button), UTIL_buttons(pev(index, pev_button)))
	server_print("pev_impulse = %d", pev(index, pev_impulse))
	if(pev_valid(pev(index, pev_chain)))
	{
		pev(pev(index, pev_chain), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_chain), temp2)
	}
	else temp = "NULL"
	server_print("pev_chain = %s", temp)
	if(pev_valid(pev(index, pev_dmg_inflictor)))
	{
		pev(pev(index, pev_dmg_inflictor), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_dmg_inflictor), temp2)
	}
	else temp = "NULL"
	server_print("pev_dmg_inflictor = %s", temp)
	if(pev_valid(pev(index, pev_enemy)))
	{
		pev(pev(index, pev_enemy), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_enemy), temp2)
	}
	else temp = "NULL"
	server_print("pev_enemy = %s", temp)
	if(pev_valid(pev(index, pev_aiment)))
	{
		pev(pev(index, pev_aiment), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_aiment), temp2)
	}
	else temp = "NULL"
	server_print("pev_aiment = %s", temp)
	if(pev_valid(pev(index, pev_owner)))
	{
		pev(pev(index, pev_owner), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_owner), temp2)
	}
	else temp = "NULL"
	server_print("pev_owner = %s", temp)
	if(pev_valid(pev(index, pev_owner)))
	{
		pev(pev(index, pev_groundentity), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_groundentity), temp2)
	}
	else temp = "NULL"
	server_print("pev_groundentity = %s", temp)
	temp = "00000000000000000000000000000000"
	temp3 = pev(index, pev_spawnflags)
	for(new i = 0; i < 32; i++) if(temp3 & (1<<i)) temp[i] = '1'
	server_print("pev_spawnflags = %u (%s)", temp3, temp)
	server_print("pev_flags = %d (%s)", pev(index, pev_flags), UTIL_flags(pev(index, pev_flags)))
	server_print("pev_colormap = %d (0x%d)", pev(index, pev_colormap), pev(index, pev_colormap))
	server_print("pev_team = %d", pev(index, pev_team))
	pev(index, pev_max_health, fValue)
	server_print("pev_max_health = %.3f", fValue)
	pev(index, pev_teleport_time, fValue)
	server_print("pev_teleport_time = %.3f", fValue)
	pev(index, pev_armortype, fValue)
	server_print("pev_armortype = %.3f", fValue)
	pev(index, pev_armorvalue, fValue)
	server_print("pev_armorvalue = %.3f", fValue)
	server_print("pev_waterlevel = %d (%s)", pev(index, pev_waterlevel), UTIL_waterlevel(pev(index, pev_waterlevel)))
	server_print("pev_watertype = %d", pev(index, pev_watertype))
	pev(index, pev_target, temp3, temp, 127)
	server_print("pev_target = %d (^"%s^")", temp3, temp)
	pev(index, pev_targetname, temp3, temp, 127)
	server_print("pev_targetname = %d (^"%s^")", temp3, temp)
	pev(index, pev_netname, temp3, temp, 127)
	server_print("pev_netname = %d (^"%s^")", temp3, temp)
	pev(index, pev_message, temp3, temp, 127)
	server_print("pev_message = %d (^"%s^")", temp3, temp)
	pev(index, pev_dmg_take, fValue)
	server_print("pev_dmg_take = %.3f", fValue)
	pev(index, pev_dmg_save, fValue)
	server_print("pev_dmg_save = %.3f", fValue)
	pev(index, pev_dmg, fValue)
	server_print("pev_dmg = %.3f", fValue)
	pev(index, pev_dmgtime, fValue)
	server_print("pev_dmgtime = %.3f (current time is %.3f)", fValue, get_gametime())
	pev(index, pev_noise, temp3, temp, 127)
	server_print("pev_noise = %d (^"%s^")", temp3, temp)
	pev(index, pev_noise1, temp3, temp, 127)
	server_print("pev_noise1 = %d (^"%s^")", temp3, temp)
	pev(index, pev_noise2, temp3, temp, 127)
	server_print("pev_noise2 = %d (^"%s^")", temp3, temp)
	pev(index, pev_noise3, temp3, temp, 127)
	server_print("pev_noise3 = %d (^"%s^")", temp3, temp)
	pev(index, pev_speed, fValue)
	server_print("pev_speed = %.3f", fValue)
	pev(index, pev_air_finished, fValue)
	server_print("pev_air_finished = %.3f", fValue)
	pev(index, pev_pain_finished, fValue)
	server_print("pev_pain_finished = %.3f", fValue)
	pev(index, pev_radsuit_finished, fValue)
	server_print("pev_radsuit_finished = %.3f", fValue)
	if(pev_valid(pev(index, pev_pContainingEntity)))
	{
		pev(pev(index, pev_pContainingEntity), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_pContainingEntity), temp2)
	}
	else temp = "NULL"
	server_print("pev_pContainingEntity = %s", temp)
	server_print("pev_playerclass = %d", pev(index, pev_playerclass))
	pev(index, pev_maxspeed, fValue)
	server_print("pev_maxspeed = %.3f", fValue)
	pev(index, pev_fov, fValue)
	server_print("pev_fov = %.3f", fValue)
	server_print("pev_weaponanim = %d", pev(index, pev_weaponanim))
	server_print("pev_pushmsec = %d", pev(index, pev_pushmsec))
	server_print("pev_bInDuck = %d (%s)", pev(index, pev_bInDuck), (pev(index, pev_bInDuck) > 0 ? "TRUE" : "FALSE"))
	server_print("pev_flTimeStepSound = %d (current time is %.3f)", pev(index, pev_flTimeStepSound), get_gametime())
	server_print("pev_flSwimTime = %d (current time is %.3f)", pev(index, pev_flSwimTime), get_gametime())
	server_print("pev_flDuckTime = %d (current time is %.3f)", pev(index, pev_flDuckTime), get_gametime())
	server_print("pev_iStepLeft = %d", pev(index, pev_iStepLeft))
	pev(index, pev_flFallVelocity, fValue)
	server_print("pev_flFallVelocity = %.3f", fValue)
	server_print("pev_gamestate = %d", pev(index, pev_gamestate))
	server_print("pev_oldbuttons = %d (%s)", pev(index, pev_oldbuttons), UTIL_buttons(pev(index, pev_oldbuttons)))
	server_print("pev_groupinfo = %d", pev(index, pev_groupinfo))
	server_print("pev_iuser1 = %d", pev(index, pev_iuser1))
	server_print("pev_iuser2 = %d", pev(index, pev_iuser2))
	server_print("pev_iuser3 = %d", pev(index, pev_iuser3))
	server_print("pev_iuser4 = %d", pev(index, pev_iuser4))
	pev(index, pev_fuser1, fValue)
	server_print("pev_fuser1 = %.3f", fValue)
	pev(index, pev_fuser2, fValue)
	server_print("pev_fuser2 = %.3f", fValue)
	pev(index, pev_fuser3, fValue)
	server_print("pev_fuser3 = %.3f", fValue)
	pev(index, pev_fuser4, fValue)
	server_print("pev_fuser4 = %.3f", fValue)
	pev(index, pev_vuser1, vValue)
	server_print("pev_vuser1 = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_vuser2, vValue)
	server_print("pev_vuser2 = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_vuser3, vValue)
	server_print("pev_vuser3 = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	pev(index, pev_vuser4, vValue)
	server_print("pev_vuser4 = Vector (%.1f, %.1f, %.1f)", vValue[0], vValue[1], vValue[2])
	if(pev_valid(pev(index, pev_euser1)))
	{
		pev(pev(index, pev_euser1), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_euser1), temp2)
	}
	else temp = "NULL"
	server_print("pev_euser1 = %s", temp)
	if(pev_valid(pev(index, pev_euser2)))
	{
		pev(pev(index, pev_euser2), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_euser2), temp2)
	}
	else temp = "NULL"
	server_print("pev_euser2 = %s", temp)
	if(pev_valid(pev(index, pev_euser3)))
	{
   		pev(pev(index, pev_euser3), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_euser3), temp2)
	}
	else temp = "NULL"
	server_print("pev_euser3 = %s", temp)
	if(pev_valid(pev(index, pev_euser4)))
	{
   		pev(pev(index, pev_euser4), pev_classname, temp2, 127)
		formatex(temp, 127, "Entity #%d (^"%s^")", pev(index, pev_euser4), temp2)
	}
	else temp = "NULL"
	server_print("pev_euser4 = %s", temp)
	server_print("End of dump.")
}

public ServerCommand_ListMsg()
{
	server_print("Available Messages...")
	new msg[64]
	for(new i = 0; i < 256; ++i)
	{
		msg[0] = 0
		get_user_msgname(i, msg, 63)
		if(msg[0] != 0) server_print("MSG_ID = %d - %s",i, msg)
	}
	server_print("^nUsage: hook_msg ^"tempentity? ResetHUD SendAudio^"")
}

public ServerCommand_PrintMsg()
{
	new string[128]
	get_pcvar_string(cvar_msg, string, 127)
	new msg1[16], msg2[16], msg3[16], msg4[16], msg5[16], i
	parse(string, msg1, 15, msg2, 15, msg3, 15, msg4, 15, msg5, 15)
	if(msg1[0] != 0)
	{
		i++
		formatex(msg1[strlen(msg1)], 16-strlen(msg1), " | ")
	}
	if(msg2[0] != 0)
	{
		i++
		formatex(msg2[strlen(msg2)], 16-strlen(msg2), " | ")
	}
	if(msg3[0] != 0)
	{
		i++
		formatex(msg3[strlen(msg3)], 16-strlen(msg3), " | ")
	}
	if(msg4[0] != 0)
	{
		i++
		formatex(msg4[strlen(msg4)], 16-strlen(msg4), " | ")
	}
	if(msg5[0] != 0)
	{
		i++
		formatex(msg5[strlen(msg5)], 16-strlen(msg5), " | ")
	}
	if(i == 0) formatex(string, 127, "Currently Hooking: NO MESSAGES")
	else
	{
		formatex(string, 127, "Currently Hooking: %i/5 MESSAGES (%s%s%s%s%s)", i, msg1, msg2, msg3, msg4, msg5)
		string[strlen(string)-3] = 0
		string[strlen(string)-1] = ')'
	}
	server_print(string)
}

public ServerCommand_PrintLog()
{
	server_print("Currently Logging: %s (^"%s^")", (get_pcvar_num(cvar_log) != 0) ? "ENABLED" : "DISABLED", (logfile[0] != 0) ? logfile : "NONE")
}

// Utils
UTIL_ReadCvar(pCvar, flag)
{
	new flags[31]
	get_pcvar_string(pCvar, flags, 31)

	if(read_flags(flags) & flag) return 1
	return 0
}

UTIL_ServerConsole_Printf(const fmt[], {Float,_}:...)
{
	static string[512]
	vformat(string, 511, fmt, 2)
	server_print(string)

	if(get_pcvar_num(cvar_log))
	{
		static basedir[64], date[16], time[16], fp
		get_basedir(basedir, 63)
		get_time("%H:%M:%S", time, 15)

		if(logfile[0] == 0)
		{
			get_time("%m%d", date, 15)
			formatex(logfile, 127, "%s/logs/shptools_%s.log", basedir, date)
		}

		get_time("%m/%d/%Y", date, 15)
		fp = fopen(logfile, "a")
		fprintf(fp, "L %s - %s: %s^n", date, time, string)
		fclose(fp)
	}
}

UTIL_atype(atype)
{
	static str[16]
	switch(atype)
	{
		case 0: str = "at_notice"
		case 1: str = "at_console"
		case 2: str = "at_aiconsole"
		case 3: str = "at_warning"
		case 4: str = "at_error"
		case 5: str = "at_logged"
		default: str = "???"
	}
	return str
}

UTIL_fixangle(fixangle)
{
	new str[32]
	switch(fixangle)
	{
		case 0: str = "nothing"
		case 1: str = "force view angles"
		case 2: str = "add velocity"
		default: str = "???"
	}
	return str
}

UTIL_movetype(movetype)
{
	new str[32]
	switch(movetype)
	{
		case 0: str = "MOVETYPE_NONE"
		case 3: str = "MOVETYPE_WALK"
		case 4: str = "MOVETYPE_STEP"
		case 5: str = "MOVETYPE_FLY"
		case 6: str = "MOVETYPE_TOSS"
		case 7: str = "MOVETYPE_PUSH"
		case 8: str = "MOVETYPE_NOCLIP"
		case 9: str = "MOVETYPE_FLYMISSILE"
		case 10: str = "MOVETYPE_BOUNCE"
		case 11: str = "MOVETYPE_BOUNCEMISSILE"
		case 12: str = "MOVETYPE_FOLLOW"
		case 13: str = "MOVETYPE_PUSHSTEP"
		default: str = "???"
	}
	return str
}

UTIL_solid(solid)
{
	new str[16]
	switch(solid)
	{
		case 0: str = "SOLID_NOT"
		case 1: str = "SOLID_TRIGGER"
		case 2: str = "SOLID_BBOX"
		case 3: str = "SOLID_SLIDEBOX"
		case 4: str = "SOLID_BSP" 
		default: str = "???"
	}
	return str
}

UTIL_effects(effects)
{
	new str[128], len
	if(effects & EF_BRIGHTFIELD) len += formatex(str[len], 128-len, "EF_BRIGHTFIELD | ")
	if(effects & EF_MUZZLEFLASH) len += formatex(str[len], 128-len, "EF_MUZZLEFLASH | ")
	if(effects & EF_BRIGHTLIGHT) len += formatex(str[len], 128-len, "EF_BRIGHTLIGHT | ")
	if(effects & EF_DIMLIGHT) len += formatex(str[len], 128-len, "EF_DIMLIGHT | ")
	if(effects & EF_INVLIGHT) len += formatex(str[len], 128-len, "EF_INVLIGHT | ")
	if(effects & EF_NOINTERP) len += formatex(str[len], 128-len, "EF_NOINTERP | ")
	if(effects & EF_LIGHT) len += formatex(str[len], 128-len, "EF_LIGHT | ")
	if(effects & EF_NODRAW) len += formatex(str[len], 128-len, "EF_NODRAW | ")
	if(strlen(str) > 2) str[strlen(str)-3] = 0
	return str
}

UTIL_rendermode(rendermode)
{
	new str[32]
	switch(rendermode)
	{
		case 0: str = "kRenderNormal"
		case 1: str = "kRenderTransColor"
		case 2: str = "kRenderTransTexture"
		case 3: str = "kRenderGlow"
		case 4: str = "kRenderTransAlpha"
		case 5: str = "kRenderTransAdd"
		default: str = "???"
	}
	return str
}

UTIL_renderfx(renderfx)
{
	new str[32]
	switch(renderfx)
	{
		case 0: str = "kRenderFxNone"
		case 1: str = "kRenderFxPulseSlow"
		case 2: str = "kRenderFxPulseFast"
		case 3: str = "kRenderFxPulseSlowWide"
		case 4: str = "kRenderFxPulseFastWide"
		case 5: str = "kRenderFxFadeSlow"
		case 6: str = "kRenderFxFadeFast"
		case 7: str = "kRenderFxSolidSlow"
		case 8: str = "kRenderFxSolidFast"
		case 9: str = "kRenderFxStrobeSlow"
		case 10: str = "kRenderFxStrobeFast"
		case 11: str = "kRenderFxStrobeFaster"
		case 12: str = "kRenderFxFlickerSlow"
		case 13: str = "kRenderFxFlickerFast"
		case 14: str = "kRenderFxNoDissipation"
		case 15: str = "kRenderFxDistort"
		case 16: str = "kRenderFxHologram"
		case 17: str = "kRenderFxDeadPlayer"
		case 18: str = "kRenderFxExplode"
		case 19: str = "kRenderFxGlowShell"
		case 20: str = "kRenderFxClampMinScale"
		default: str = "???"
	}
	return str
}

UTIL_takedamage(takedamage)
{
	new str[16]
	switch(takedamage)
	{
		case 0: str = "DAMAGE_NO"
		case 1: str = "DAMAGE_YES"
		case 2: str = "DAMAGE_AIM"
		default: str = "???"
	}
	return str
}

UTIL_deadflag(deadflag)
{
	new str[32]
	switch(deadflag)
	{
		case 0: str = "DEAD_NO"
		case 1: str = "DEAD_DYING"
		case 2: str = "DEAD_DEAD"
		case 3: str = "DEAD_RESPAWNABLE"
		case 4: str = "DEAD_DISCARDBODY"
		case 5: str = "???"
	}
	return str
}

UTIL_flags(flags)
{
	new str[128], len
	if(flags & FL_FLY) len += formatex(str[len], 128-len, "FL_FLY | ")
	if(flags & FL_SWIM) len += formatex(str[len], 128-len, "FL_SWIM | ")
	if(flags & FL_CONVEYOR) len += formatex(str[len], 128-len, "FL_CONVEYOR | ")
	if(flags & FL_CLIENT) len += formatex(str[len], 128-len, "FL_CLIENT | ")
	if(flags & FL_INWATER) len += formatex(str[len], 128-len, "FL_INWATER | ")
	if(flags & FL_MONSTER) len += formatex(str[len], 128-len, "FL_MONSTER | ")
	if(flags & FL_GODMODE) len += formatex(str[len], 128-len, "FL_GODMODE | ")
	if(flags & FL_NOTARGET) len += formatex(str[len], 128-len, "FL_NOTARGET | ")
	if(flags & FL_SKIPLOCALHOST) len += formatex(str[len], 128-len, "FL_SKIPLOCALHOST | ")
	if(flags & FL_ONGROUND) len += formatex(str[len], 128-len, "FL_ONGROUND | ")
	if(flags & FL_PARTIALGROUND) len += formatex(str[len], 128-len, "FL_PARTIALGROUND | ")
	if(flags & FL_WATERJUMP) len += formatex(str[len], 128-len, "FL_WATERJUMP | ")
	if(flags & FL_FROZEN) len += formatex(str[len], 128-len, "FL_FROZEN | ")
	if(flags & FL_FAKECLIENT) len += formatex(str[len], 128-len, "FL_FAKECLIENT | ")
	if(flags & FL_DUCKING) len += formatex(str[len], 128-len, "FL_DUCKING | ")
	if(flags & FL_FLOAT) len += formatex(str[len], 128-len, "FL_FLOAT | ")
	if(flags & FL_GRAPHED) len += formatex(str[len], 128-len, "FL_GRAPHED | ")
	if(flags & FL_IMMUNE_WATER) len += formatex(str[len], 128-len, "FL_IMMUNE_WATER | ")
	if(flags & FL_IMMUNE_SLIME) len += formatex(str[len], 128-len, "FL_IMMUNE_SLIME | ")
	if(flags & FL_IMMUNE_LAVA) len += formatex(str[len], 128-len, "FL_IMMUNE_LAVA | ")
	if(flags & FL_PROXY) len += formatex(str[len], 128-len, "FL_PROXY | ")
	if(flags & FL_ALWAYSTHINK) len += formatex(str[len], 128-len, "FL_ALWAYSTHINK | ")
	if(flags & FL_BASEVELOCITY) len += formatex(str[len], 128-len, "FL_BASEVELOCITY | ")
	if(flags & FL_MONSTERCLIP) len += formatex(str[len], 128-len, "FL_MONSTERCLIP | ")
	if(flags & FL_ONTRAIN) len += formatex(str[len], 128-len, "FL_ONTRAIN | ")
	if(flags & FL_WORLDBRUSH) len += formatex(str[len], 128-len, "FL_WORLDBRUSH | ")
	if(flags & FL_SPECTATOR) len += formatex(str[len], 128-len, "FL_SPECTATOR | ")
	if(flags & (1<<27)) len += formatex(str[len], 128-len, "UNKNOWN (1<<27) | ")
	if(flags & (1<<28)) len += formatex(str[len], 128-len, "UNKNOWN (1<<28) | ")
	if(flags & FL_CUSTOMENTITY) len += formatex(str[len], 128-len, "FL_CUSTOMENTITY | ")
	if(flags & FL_KILLME) len += formatex(str[len], 128-len, "FL_KILLME | ")
	if(flags & FL_DORMANT) len += formatex(str[len], 128-len, "FL_DORMANT | ")
	if(strlen(str) > 2) str[strlen(str)-3] = 0
	return str
}

UTIL_waterlevel(waterlevel)
{
	new str[32]
	switch(waterlevel)
	{
		case 0: str = "not in water"
		case 2: str = "walking in water"
		case 3: str = "swimming in water"
		default: str = "???"
	}
	return str
}

UTIL_buttons(button)
{
	new str[128], len
	if(button & IN_ATTACK) len += formatex(str[len], 128-len, "IN_ATTACK | ")
	if(button & IN_JUMP) len += formatex(str[len], 128-len, "IN_JUMP | ")
	if(button & IN_DUCK) len += formatex(str[len], 128-len, "IN_DUCK | ")
	if(button & IN_FORWARD) len += formatex(str[len], 128-len, "IN_FORWARD | ")
	if(button & IN_BACK) len += formatex(str[len], 128-len, "IN_BACK | ")
	if(button & IN_USE) len += formatex(str[len], 128-len, "IN_USE | ")
	if(button & IN_CANCEL) len += formatex(str[len], 128-len, "IN_CANCEL | ")
	if(button & IN_LEFT) len += formatex(str[len], 128-len, "IN_LEFT | ")
	if(button & IN_RIGHT) len += formatex(str[len], 128-len, "IN_RIGHT | ")
	if(button & IN_MOVELEFT) len += formatex(str[len], 128-len, "IN_MOVELEFT | ")
	if(button & IN_MOVERIGHT) len += formatex(str[len], 128-len, "IN_MOVERIGHT | ")
	if(button & IN_ATTACK2) len += formatex(str[len], 128-len, "IN_ATTACK2 | ")
	if(button & IN_RUN) len += formatex(str[len], 128-len, "IN_RUN | ")
	if(button & IN_RELOAD) len += formatex(str[len], 128-len, "IN_RELOAD | ")
	if(button & IN_ALT1) len += formatex(str[len], 128-len, "IN_ALT1 | ")
	if(button & IN_SCORE) len += formatex(str[len], 128-len, "IN_SCORE | ")
	if(strlen(str) > 2) str[strlen(str)-3] = 0
	return str
}

UTIL_DrawBeam(id, Float:start0, Float:start1, Float:start2, Float:end0, Float:end1, Float:end2, life, width, noise, red, green, blue, brightness, speed)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
	write_byte(TE_BEAMPOINTS)
	write_coord(floatround(start0))
	write_coord(floatround(start1))
	write_coord(floatround(start2))
	write_coord(floatround(end0))
	write_coord(floatround(end1))
	write_coord(floatround(end2))
	write_short(beam_texture)
	write_byte(1) // framestart
	write_byte(10) // framerate
	write_byte(life) // life in 0.1's
	write_byte(width) // width
	write_byte(noise) // noise
	write_byte(red) // r, g, b
	write_byte(green) // r, g, b
	write_byte(blue) // r, g, b
	write_byte(brightness) // brightness
	write_byte(speed) // speed
	message_end()
}