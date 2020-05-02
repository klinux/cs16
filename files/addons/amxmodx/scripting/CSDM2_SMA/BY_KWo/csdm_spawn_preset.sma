/**
 * csdm_spawn_preset.sma
 * Allows for Counter-Strike to be played as DeathMatch.

 * CSDM Spawn Method - Preset Spawning
 * by Freecode and BAILOPAN
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#define	MAX_SPAWNS	60

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <csdm>

//Tampering with the author and name lines will violate copyrights
new PLUGINNAME[] = "CSDM Spawns"
new VERSION[] = CSDM_VERSION
new AUTHORS[] = "CSDM Team"

//Menus
new g_MainMenu[] = "CSDM: Spawn Manager";
new g_MainMenuID = -1;				
new g_cMain;

new g_AddSpawnsMenu[] = "CSDM: Add Spawns Menu";
new g_AddSpawnsMenuID;
new g_cAddSpawns;

new g_SpawnVecs[MAX_SPAWNS][3];
new g_SpawnAngles[MAX_SPAWNS][3];
new g_SpawnVAngles[MAX_SPAWNS][3];
new g_SpawnTeam[MAX_SPAWNS];

new g_TotalSpawns = 0;
new g_MainPlugin = -1;

new g_Ents[MAX_SPAWNS];
new g_Ent[33];					// Current closest spawn

new Float:red[3] = {255.0,0.0,0.0};
new Float:yellow[3] = {255.0,200.0,20.0};

new g_iszInfoTarget;

public csdm_Init(const version[])
{
	if (version[0] == 0)
	{
		set_fail_state("CSDM failed to load.")
		return
	}

	csdm_addstyle("preset", "spawn_Preset")
}

public csdm_CfgInit()
{
	csdm_reg_cfg("settings", "read_cfg")
}

public plugin_init()
{
	register_plugin(PLUGINNAME,VERSION,AUTHORS)
	g_iszInfoTarget = engfunc(EngFunc_AllocString, "info_target");

	register_concmd("edit_spawns", "showmen", ADMIN_MAP, "Edits spawn configuration");

	g_MainPlugin = module_exists("csdm_main") ? true : false	
	if (g_MainPlugin)
	{
		new menu = csdm_main_menu();
		menu_additem(menu, "Spawn Editor", "edit_spawns", ADMIN_MAP)
	}
}

public read_cfg(action, line[], section[])
{
	if (action == CFG_RELOAD)
	{
		readSpawns()
		new Map[32], config[32],  MapFile[256]

		get_mapname(Map, 31)
		get_configsdir(config, 31)
		format(MapFile, 255, "%s\csdm\%s.spawns.cfg", config, Map)

		if (g_TotalSpawns)
			log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map)
		else
			log_amx("No spawn points file found (%s)", MapFile)
	}
}

readSpawns()
{
	//-617 2648 179 16 -22 0 0 -5 -22 0
	// Origin (x,y,z), Angles (x,y,z), Team (0 = ALL, 1 = T, 2 = CT), vAngles(x,y,z), 

	new Map[32], config[32],  MapFile[256]

	get_mapname(Map, 31)
	get_configsdir(config, 31)
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg", config, Map)
	g_TotalSpawns = 0;

	if (file_exists(MapFile)) 
	{
		new Data[124], len
		new line = 0
		new pos[12][8]

		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2 || Data[0] == '[')
				continue;

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);

			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_num(pos[1])
			g_SpawnVecs[g_TotalSpawns][1] = str_to_num(pos[2])
			g_SpawnVecs[g_TotalSpawns][2] = str_to_num(pos[3])

			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_num(pos[4])
			g_SpawnAngles[g_TotalSpawns][1] = str_to_num(pos[5])
			g_SpawnAngles[g_TotalSpawns][2] = str_to_num(pos[6])

			// Teams
			g_SpawnTeam[g_TotalSpawns]=str_to_num(pos[7])

			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_num(pos[8])
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_num(pos[9])
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_num(pos[10])

			g_TotalSpawns++;
		}
	}
	return 1;
}

public spawn_Preset(id, num)
{
	if (g_TotalSpawns < 2)
		return PLUGIN_CONTINUE

	new num = 0
	new final = -1
	new players[32], n, x = 0
	new Float:loc[32][3], locnum
	new Float:FSpawnVecs[3]
	new Float:FSpawnAngles[3]
	new Float:FSpawnVAngles[3]
	new team = get_user_team(id)
	new ffa = csdm_get_ffa()

	//cache locations
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		if ((is_user_alive(players[i])) && (players[i] != id) && ((get_user_team(players[i]) != team) || ffa))
		{
			pev(players[i], pev_origin, loc[locnum])
			locnum++
		}
	}

	num = 0

	//get a random spawn
	n = random_num(0, g_TotalSpawns-1)

	while (num <= g_TotalSpawns)
	{
		//have we visited all the spawns yet?
		if (num == g_TotalSpawns)
			break;
		
		if (n < g_TotalSpawns - 1)
			n++
		else
			n = 0

		// inc the number of spawns we've visited
		num++

		if (( (team == _TEAM_T) && (g_SpawnTeam[n]==2) ) 
				|| ( (team == _TEAM_CT) && (g_SpawnTeam[n]==1) ) )
			continue;

		final = n
		IVecFVec(g_SpawnVecs[n], FSpawnVecs)

		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(FSpawnVecs, loc[x]);
			if (distance < 500.0)
			{
				//invalidate
				final = -1
				break
			}
		}

		if (final == -1)
			continue

		new trace = csdm_trace_hull(FSpawnVecs, 1)

		if (trace)
			continue;

		if (locnum < 1)
		{
			break
		}

		if (final != -1)
			break
	}

	if (final != -1)
	{
		new Float:mins[3], Float:maxs[3]

		IVecFVec(g_SpawnVecs[final], FSpawnVecs)
		IVecFVec(g_SpawnAngles[final], FSpawnAngles)
		IVecFVec(g_SpawnVAngles[final], FSpawnVAngles)

		pev(id, pev_mins, mins)
		pev(id, pev_maxs, maxs)

		engfunc(EngFunc_SetSize, id, mins, maxs)
		engfunc(EngFunc_SetOrigin, id, FSpawnVecs)
		set_pev(id, pev_fixangle, 1)
		set_pev(id, pev_angles, FSpawnAngles)
		set_pev(id, pev_v_angle, FSpawnVAngles)
		set_pev(id, pev_fixangle, 1)

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

buildMenu()
{
// Create Menu
	g_MainMenuID = menu_create(g_MainMenu, "m_MainHandler");

//Menu Callbacks
	g_cMain = menu_makecallback("c_Main");

	menu_additem(g_MainMenuID, "Add current position to Spawn","1", 0, g_cMain);
	menu_additem(g_MainMenuID, "Edit closest spawn (yellow) to Current Position","2", 0, g_cMain);
	menu_additem(g_MainMenuID, "Delete closest Spawn","3", 0, g_cMain);
	menu_additem(g_MainMenuID, "Refresh Closest Spawn", "4", 0, g_cMain);
	menu_additem(g_MainMenuID, "Show statistics", "5", 0, -1);
	menu_additem(g_MainMenuID, "Back", "6", 0, -1);

//Add Spawns Menu
	g_AddSpawnsMenuID = menu_create(g_AddSpawnsMenu, "m_AddSpawnsHandler");
	g_cAddSpawns = menu_makecallback("c_AddSpawns");
	menu_additem(g_AddSpawnsMenuID, "Add Current Postion as a random spawn","1", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Add Current Postion as a T spawn","2", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Add Current Postion as a CT spawn","3", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Back","4", 0, -1);	
}

public m_MainHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		ent_remove(-1);
		menu_destroy(menu);	
		return PLUGIN_HANDLED;
	}

	// Get item info
	new cmd[6], iName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);

	new iChoice = str_to_num(cmd);

	switch(iChoice)
	{
		case 1:
		{
			menu_display(id, g_AddSpawnsMenuID, 0);
		}
		case 2:
		{
			new Float:vecs[3], vec[3];
			new Float:angles[3], angle[3];
			new Float:vangles[3], vangle[3];

			pev(id, pev_origin, vecs);
			pev(id, pev_angles, angles);
			pev(id, pev_v_angle, vangles);

			FVecIVec(vecs,vec);
			FVecIVec(angles,angle);
			FVecIVec(vangles,vangle);

			vec[2] += 15;
			edit_spawn(g_Ent[id],vec,angle,vangle);
			menu_display(id, g_MainMenuID, 0);
		}
		case 3:
		{
			ent_unglow(g_Ent[id]);
			delete_spawn(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			menu_display(id, g_MainMenuID, 0);				
		}
		case 4:
		{
			ent_unglow(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			ent_glow(g_Ent[id],yellow);
			menu_display(id, g_MainMenuID, 0);
			new szteam[16]

			switch(g_SpawnTeam[g_Ent[id]])
			{
				case	0:
					format(szteam,15,"random")
				case	1:
					format(szteam,15,"T")
				case	2:
					format(szteam,15,"CT")
			}
			client_print(id,print_chat,"The closest spawn: number %d , def: team = %s, org[%d,%d,%d], ang[%d,%d,%d], vang[%d,%d,%d]", 
				g_Ent[id] + 1, szteam, g_SpawnVecs[g_Ent[id]][0], g_SpawnVecs[g_Ent[id]][1], g_SpawnVecs[g_Ent[id]][2], 
				g_SpawnAngles[g_Ent[id]][0], g_SpawnAngles[g_Ent[id]][1], g_SpawnAngles[g_Ent[id]][2], 
				g_SpawnVAngles[g_Ent[id]][0], g_SpawnVAngles[g_Ent[id]][1], g_SpawnVAngles[g_Ent[id]][2])
		}
		case 5:
		{	
			new Float:Org[3];
			pev(id, pev_origin, Org);

			new RD_num=0, TR_num=0, CT_num=0;
			for (new x=0; x<g_TotalSpawns; x++)
			{
				if (g_SpawnTeam[x]==0) RD_num++
				if (g_SpawnTeam[x]==1) TR_num++
				if (g_SpawnTeam[x]==2) CT_num++
			}

			client_print(id,print_chat,"Total Spawns: %d; Random: %d; T: %d; CT: %d.^nCurrent Origin: X: %f  Y: %f  Z: %f",
				g_TotalSpawns, RD_num, TR_num, CT_num, Org[0], Org[1], Org[2]);
			 
			menu_display(id, g_MainMenuID, 0);
		}
		case 6:
		{
			ent_remove(-1);
			menu_display(id, csdm_main_menu(),0);
		}
	}

	return PLUGIN_HANDLED;
}

public c_Main(id, menu, item)
{
	if (item == MENU_EXIT) return PLUGIN_CONTINUE

	new cmd[6], fItem[326], iName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);

	new num = str_to_num(cmd);

	switch(num)
	{
		case	1:
		{
			if (g_TotalSpawns == MAX_SPAWNS)
			{
				format(fItem,325,"Add Spawns - Max Spawn Limit Reached");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Add current position to Spawn");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case	2:
		{
			if (g_TotalSpawns < 1)
			{
				format(fItem,325,"Edit Spawn - No spawns");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else if (g_Ents[g_Ent[id]]==0)
			{
				format(fItem,325,"Edit Spawn - No spawn marked");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Edit closest spawn (yellow) to Current Position");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case	3:
		{
			if (g_TotalSpawns < 1)
			{
				format(fItem,325,"Delete Spawn - No spawns");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else if (g_Ents[g_Ent[id]]==0)
			{
				format(fItem,325,"Delete Spawn - No spawn marked");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}			
			else
			{
				new iorg[3];
				get_user_origin(id, iorg);
				new distance = get_distance(iorg, g_SpawnVecs[g_Ent[id]]);
					
				if (distance > 200)
				{
					format(fItem,325,"Delete Spawn - Marked spawn far away");
					menu_item_setname(menu, item, fItem );
					return ITEM_DISABLED;
				}
				else
				{
					format(fItem,325,"Delete closest Spawn");
					menu_item_setname(menu, item, fItem );
					return ITEM_ENABLED;
				}
			}
		}
	}

	return PLUGIN_HANDLED;
}


public m_AddSpawnsHandler(id, menu, item)
{
	if (item < 0) {
		ent_remove(-1);		
		return PLUGIN_HANDLED;
	}

	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	new team

	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback);

	new iChoice = str_to_num(cmd);

	if (iChoice == 4) 
	{
		menu_display (id, g_MainMenuID, 0);
		return PLUGIN_HANDLED;
	}

	new Float:vecs[3], vec[3];
	new Float:angles[3], angle[3];
	new Float:vangles[3], vangle[3];

	switch(iChoice)
	{
		case 1:
		{
			team = 0
		}
		case 2:
		{
			team = 1
		}
		case 3:
		{
			team = 2
		}
	}	

	pev(id, pev_origin, vecs);
	pev(id, pev_angles, angles);
	pev(id, pev_v_angle, vangles);

	FVecIVec(vecs,vec);
	FVecIVec(angles,angle);
	FVecIVec(vangles,vangle);

	vec[2] += 15;
	add_spawn(vec,angle,vangle,team);

	menu_display (id, g_AddSpawnsMenuID, 0);

	return PLUGIN_HANDLED;
}

public c_AddSpawns(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE

	new cmd[6], fItem[326], iName[64];
	new access, callback;

	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);

	new num = str_to_num(cmd);

	switch (num)
  {
		case 1:
		{
			if (g_TotalSpawns == MAX_SPAWNS)
			{
				format(fItem,325,"Add a random spawn - Max Spawn Limit Reached");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Add Current Position as a random spawn");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case 2:
		{
			if (g_TotalSpawns == MAX_SPAWNS)
			{
				format(fItem,325,"Add a T spawn - Max Spawn Limit Reached");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Add Current Position as a T spawn");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
		case 3:
		{
			if (g_TotalSpawns == MAX_SPAWNS)
			{
				format(fItem,325,"Add a CT spawn - Max Spawn Limit Reached");
				menu_item_setname(menu, item, fItem );
				return ITEM_DISABLED;
			}
			else
			{
				format(fItem,325,"Add Current Position as a CT spawn");
				menu_item_setname(menu, item, fItem );
				return ITEM_ENABLED;
			}
		}
	}
	return PLUGIN_HANDLED;
}

add_spawn(vecs[3], angles[3], vangles[3], team)
{
	new Map[32], config[32],  MapFile[256];

	get_mapname(Map, 31)
	get_configsdir(config, 31 )
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);

	new line[128];
	format(line, 127, "%d %d %d %d %d %d %d %d %d %d",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], team, vangles[0], vangles[1], vangles[2]);
	write_file(MapFile, line, -1);

	// origin
	g_SpawnVecs[g_TotalSpawns][0] = vecs[0];
	g_SpawnVecs[g_TotalSpawns][1] = vecs[1];
	g_SpawnVecs[g_TotalSpawns][2] = vecs[2];
	// Angles
	g_SpawnAngles[g_TotalSpawns][0] = angles[0];
	g_SpawnAngles[g_TotalSpawns][1] = angles[1];
	g_SpawnAngles[g_TotalSpawns][2] = angles[2];

	// Teams
	g_SpawnTeam[g_TotalSpawns] = team;

	// v-Angles
	g_SpawnVAngles[g_TotalSpawns][0] = vangles[0];
	g_SpawnVAngles[g_TotalSpawns][1] = vangles[1];
	g_SpawnVAngles[g_TotalSpawns][2] = vangles[2];

	ent_make(g_TotalSpawns);
	g_TotalSpawns++;

}

edit_spawn(ent, vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[256];

	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);

	if (file_exists(MapFile)) 
	{
		new Data[124], len;
		new line = 0;
		new pos[11][8];
		new currentVec[3], newSpawn[128];
		new team;

		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 )
		{
			if (strlen(Data)<2) continue;

			parse(Data,pos[1],7,pos[2],7,pos[3],7,pos[4],7,pos[5],7,pos[6],7,pos[7],7,pos[8],7,pos[9],7,pos[10],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			team = str_to_num(pos[7]);

			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && ( (g_SpawnVecs[ent][2] - currentVec[2])<=15) )
			{	
				format(newSpawn, 127, "%d %d %d %d %d %d %d %d %d %d",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], team, 
					vangles[0], vangles[1], vangles[2]); 
				write_file(MapFile, newSpawn, line-1);

				ent_remove(ent);

				g_SpawnVecs[ent][0] = vecs[0];
				g_SpawnVecs[ent][1] = vecs[1];
				g_SpawnVecs[ent][2] = vecs[2];

				g_SpawnAngles[ent][0] = angles[0];
				g_SpawnAngles[ent][1] = angles[1];
				g_SpawnAngles[ent][2] = angles[2];

				g_SpawnVAngles[ent][0] = vangles[0];
				g_SpawnVAngles[ent][1] = vangles[1];
				g_SpawnVAngles[ent][2] = vangles[2];

				ent_make(ent);
				ent_glow(ent,red);

				break;
			}
		}
	}
}

delete_spawn(ent)
{
	new Map[32], config[32],  MapFile[256];
	
	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 255, "%s\csdm\%s.spawns.cfg",config, Map);
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[11][8];
    		new currentVec[3];
    		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			
			parse(Data,pos[1],7,pos[2],7,pos[3],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			
			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && ( (g_SpawnVecs[ent][2] - currentVec[2])<=15) )
			{
				write_file(MapFile, "", line-1);
				
				ent_remove(-1);
				readSpawns();
				ent_make(-1);
				
				break
			}
		}
	}
}

closest_spawn(id)
{
	new origin[3];
	new lastDist = 999999;
	new closest;
	
	get_user_origin(id, origin);
	for (new x = 0; x < g_TotalSpawns; x++)
	{
		new distance = get_distance(origin, g_SpawnVecs[x]);
		
		if (distance < lastDist)
		{
			lastDist = distance;
			closest = x;
		}
	}
	return closest;
}

ent_make(id)
{
	new iEnt;

	if(id < 0)
	{
		for (new x = 0; x < g_TotalSpawns; x++)
		{
	
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");
			switch(g_SpawnTeam[x])
			{
				case 0:
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
				}
				case 1:
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/terror/terror.mdl");
				}
				case 2:
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/urban/urban.mdl");
				}
			}

			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND)
			set_pev(iEnt, pev_sequence, 1);
			if (g_Ents[x])
			{
				engfunc(EngFunc_RemoveEntity, g_Ents[x])
			}

			g_Ents[x] = iEnt;
			ent_unglow(x);
		}
	}
	else
	{
		if ((g_SpawnTeam[id]>=0) && (g_SpawnTeam[id]<3))
		{
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");
			switch (g_SpawnTeam[id]) 
			{
				case 0: /* CSDM random spawn point */	
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
				}
				case 1: /* CSDM terrorist spawn point */
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/terror/terror.mdl");
				}
				case 2: /* CSDM CT spawn point */
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/urban/urban.mdl");
				}
			}
			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_sequence, 1);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND)

			if (g_Ents[id])
			{
				engfunc(EngFunc_RemoveEntity, g_Ents[id])
			}

			g_Ents[id] = iEnt;			
			ent_unglow(id);
		}
	}
}

ent_remove(ent)
{
	if( ent < 0 )
	{
		for( new i = 0; i < g_TotalSpawns; i++)
		{
			if(pev_valid(g_Ents[i]))
			{
				engfunc(EngFunc_RemoveEntity, g_Ents[i]);
				g_Ents[i] = 0
			}
		}
	} else {
		if(pev_valid(g_Ents[ent]))
		{
			engfunc(EngFunc_RemoveEntity, g_Ents[ent]); //remove_entity(ent)
			g_Ents[ent] = 0
		}
	}
}

ent_glow(ent,Float:color[3])
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		set_ent_pos(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell);
		set_pev(iEnt, pev_renderamt, 127.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);
		set_pev(iEnt, pev_rendercolor, color) ;
	}
}

ent_unglow(ent)
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		set_ent_pos(ent);
		
		set_pev(iEnt, pev_renderfx, kRenderFxNone); 
		set_pev(iEnt, pev_renderamt, 127.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);		
	}
}

set_ent_pos(ent)
{
	new iEnt = g_Ents[ent];
	
	new Float:org[3];
	IVecFVec(g_SpawnVecs[ent],org);
	set_pev( iEnt, pev_origin, org);
		
	new Float:ang[3];																
	IVecFVec(g_SpawnAngles[ent],ang);
	set_pev(iEnt, pev_angles, ang);

	new Float:vang[3];
	IVecFVec(g_SpawnVAngles[ent],vang);
	set_pev(iEnt, pev_v_angle, vang);
	
	set_pev(iEnt, pev_fixangle, 1)
}

public showmen(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	buildMenu();
	ent_make(-1);
	menu_display ( id, g_MainMenuID, 0);
	
	return PLUGIN_HANDLED;
}
