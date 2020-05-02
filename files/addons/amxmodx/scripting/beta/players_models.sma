/*	Formatright © 2009, ConnorMcLeod

	Players Models is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Players Models; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

// #define SET_MODELINDEX

#include <amxmodx>
#include <fakemeta>

#define VERSION "1.3.1"

#define SetUserModeled(%1)		g_bModeled |= 1<<(%1 & 31)
#define SetUserNotModeled(%1)		g_bModeled &= ~( 1<<(%1 & 31) )
#define IsUserModeled(%1)		( g_bModeled &  1<<(%1 & 31) )

#define SetUserConnected(%1)		g_bConnected |= 1<<(%1 & 31)
#define SetUserNotConnected(%1)		g_bConnected &= ~( 1<<(%1 & 31) )
#define IsUserConnected(%1)		( g_bConnected &  1<<(%1 & 31) )

#define MAX_MODEL_LENGTH	16
#define MAX_AUTHID_LENGTH 25

#define MAX_PLAYERS	32

#define ClCorpse_ModelName 1
#define ClCorpse_PlayerID 12

#define m_iTeam 114
#define g_ulModelIndexPlayer 491
#define fm_cs_get_user_team_index(%1)	get_pdata_int(%1, m_iTeam)

new const MODEL[] = "model";
new g_bModeled;
new g_szCurrentModel[MAX_PLAYERS+1][MAX_MODEL_LENGTH];

new Trie:g_tTeamModels[2];
new Trie:g_tModelIndexes;
new Trie:g_tDefaultModels;

new g_szAuthid[MAX_PLAYERS+1][MAX_AUTHID_LENGTH];
new g_bPersonalModel[MAX_PLAYERS+1];

new g_bConnected;

public plugin_init()
{
	register_plugin("Players Models", VERSION, "ConnorMcLeod");

	register_forward(FM_SetClientKeyValue, "SetClientKeyValue");
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse");
}

public plugin_precache()
{
	new szConfigFile[128];
	get_localinfo("amxx_configsdir", szConfigFile, charsmax(szConfigFile));
	format(szConfigFile, charsmax(szConfigFile), "%s/players_models.ini", szConfigFile);

	new iFile = fopen(szConfigFile, "rt");
	if( iFile )
	{
		new const szDefaultModels[][] = {"", "urban", "terror", "leet", "arctic", "gsg9", 
					"gign", "sas", "guerilla", "vip", "militia", "spetsnaz" };
		g_tDefaultModels = TrieCreate();
		for(new i=1; i<sizeof(szDefaultModels); i++)
		{
			TrieSetCell(g_tDefaultModels, szDefaultModels[i], i);
		}

		g_tModelIndexes = TrieCreate();

		g_tTeamModels[0] = TrieCreate();
		g_tTeamModels[1] = TrieCreate();

		new szDatas[70], szRest[40], szKey[MAX_AUTHID_LENGTH], szModel1[MAX_MODEL_LENGTH], szModel2[MAX_MODEL_LENGTH];
		while( !feof(iFile) )
		{
			fgets(iFile, szDatas, charsmax(szDatas));
			trim(szDatas);
			if(!szDatas[0] || szDatas[0] == ';' || szDatas[0] == '#' || (szDatas[0] == '/' && szDatas[1] == '/'))
			{
				continue;
			}

			parse(szDatas, szKey, charsmax(szKey), szModel1, charsmax(szModel1), szModel2, charsmax(szModel2));

			if( TrieKeyExists(g_tDefaultModels, szKey) )
			{
				if( szModel1[0] && !equal(szModel1, szKey) && PrecachePlayerModel(szModel1) )
				{
					TrieSetString(g_tDefaultModels, szKey, szModel1);
				}
			}
			else if( equal(szKey, "STEAM_", 6) || equal(szKey, "BOT") )
			{
				parse(szRest, szModel1, charsmax(szModel1), szModel2, charsmax(szModel2));
				if( szModel1[0] && PrecachePlayerModel(szModel1) )
				{
					TrieSetString(g_tTeamModels[1], szKey, szModel1);
				}
				if( szModel2[0] && PrecachePlayerModel(szModel2) )
				{
					TrieSetString(g_tTeamModels[0], szKey, szModel2);
				}
			}
		}
		fclose( iFile );
	}
}

PrecachePlayerModel( const szModel[] )
{
	if( TrieKeyExists(g_tModelIndexes, szModel) )
	{
		return 1;
	}

	new szFileToPrecache[64];
	formatex(szFileToPrecache, charsmax(szFileToPrecache), "models/player/%s/%s.mdl", szModel, szModel);
	if( !file_exists( szFileToPrecache ) && !TrieKeyExists(g_tDefaultModels, szModel) )
	{
		return 0;
	}

	TrieSetCell(g_tModelIndexes, szModel, precache_model(szFileToPrecache));

	formatex(szFileToPrecache, charsmax(szFileToPrecache), "models/player/%s/%st.mdl", szModel, szModel);
	if( file_exists( szFileToPrecache ) )
	{
		precache_model(szFileToPrecache);
		return 1;
	}
	formatex(szFileToPrecache, charsmax(szFileToPrecache), "models/player/%s/%sT.mdl", szModel, szModel);
	if( file_exists( szFileToPrecache ) )
	{
		precache_model(szFileToPrecache);
		return 1;
	}

	return 1;
}

public plugin_end()
{
	TrieDestroy(g_tTeamModels[0]);
	TrieDestroy(g_tTeamModels[1]);
	TrieDestroy(g_tModelIndexes);
	TrieDestroy(g_tDefaultModels);
}

public client_authorized( id )
{
	get_user_authid(id, g_szAuthid[id], MAX_AUTHID_LENGTH-1);

	for(new i=1; i<=2; i++)
	{
		if( TrieKeyExists(g_tTeamModels[2-i], g_szAuthid[id]) )
		{
			g_bPersonalModel[id] |= i;
		}
		else
		{
			g_bPersonalModel[id] &= ~i;
		}
	}
}

public client_putinserver(id)
{
	if( !is_user_hltv(id) )
	{
		SetUserConnected(id);
	}
}

public client_disconnect(id)
{
	g_bPersonalModel[id] = 0;
	SetUserNotModeled(id);
	SetUserNotConnected(id);
}

public SetClientKeyValue(id, const szInfoBuffer[], const szKey[], const szValue[])
{
	if( equal(szKey, MODEL) && IsUserConnected(id) )
	{
		new iTeam = fm_cs_get_user_team_index(id);
		if( 1 <= iTeam <= 2 )
		{
			new szSupposedModel[MAX_MODEL_LENGTH];

			if( g_bPersonalModel[id] & iTeam )
			{
				TrieGetString(g_tTeamModels[2-iTeam], g_szAuthid[id], szSupposedModel, charsmax(szSupposedModel));
			}
			else
			{
				TrieGetString(g_tDefaultModels, szValue, szSupposedModel, charsmax(szSupposedModel));
			}

			if( szSupposedModel[0] )
			{
				if(	!IsUserModeled(id)
				||	!equal(g_szCurrentModel[id], szSupposedModel)
				||	!equal(szValue, szSupposedModel)	)
				{
					copy(g_szCurrentModel[id], MAX_MODEL_LENGTH-1, szSupposedModel);
					SetUserModeled(id);
					set_user_info(id, MODEL, szSupposedModel);
				#if defined SET_MODELINDEX
					new iModelIndex;
					TrieGetCell(g_tModelIndexes, szSupposedModel, iModelIndex);
				//	set_pev(id, pev_modelindex, iModelIndex); // is this needed ?
					set_pdata_int(id, g_ulModelIndexPlayer, iModelIndex);
				#endif
					return FMRES_SUPERCEDE;
				}
			}

			if( IsUserModeled(id) )
			{
				SetUserNotModeled(id);
				g_szCurrentModel[id][0] = 0;
			}
		}
	}
	return FMRES_IGNORED;
}

public Message_ClCorpse()
{
	new id = get_msg_arg_int(ClCorpse_PlayerID);
	if( IsUserModeled(id) )
	{
		set_msg_arg_string(ClCorpse_ModelName, g_szCurrentModel[id]);
	}
}