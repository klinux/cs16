/* Admin Gag Command
About:
This plugin allows you to gag players from using say_team,say or voicecomm. It also echos admin acctions 
based on amx_show_activity. The plugin can also block gagged clients from changing their nick. 
Admins with immunity will not be executed on, unless their executing on themself

Usage:
amx_gag <nick/userid> <flags (a/b/c)> <time in seconds> // lets you control what you want to gag
amx_gag <nick/userid>  <time in seconds> // Will automaticly add the abc flag.
amx_gag <nick/userid>	// Will add abc flags, and 600 secounds gag.
amx_gag <nick/userid> <flags>
amx_ungag <nick/userid> // Will remove all "gags"

Modules required:
engine

FAQ)
Q) Can i mute voicecomm?
A) Yes, that should be on by defualt. But you can make sure "#define VoiceCommMute 1"

Q) Is there any way i can disable the engine module and still run the plugin?
A) yes, "#define VoiceCommMute 0".

Plugin forum thread: http://www.amxmodx.org/forums/viewtopic.php?t=463


Credits:
Ops in #AMXmod @ Quakenet for alot of help ( + AssKicker & CheesyPeteza ) 
This plugin is heavly based on the work of tcquest78 in his gag plugin http://djeyl.net/forum/index.php?showtopic=4962
Code for Namechange block code was taken from Olo`s one_name plugin.

Changelog:
    1.7.5 ( 06.07.2004 )
	- Changed: #define MaxPlayers to be 32 instead of 33 (Should save a few byte of mem )

    1.7.4 ( 06.07.2004 )
	- Changed: Once amx_gag/amx_ungag is used admins will no longer see "command not found" in console anymore ( Thx to Downtown1)
	- Added: #define for MaxPlayers

    1.7.3 ( 06.07.2004 )
	- Fixed: Fixed possible issue with steamids being to long (Would just be text cut on in logs/text)

    1.7.2 ( 03.07.2004 )
	- Fixed: Spelling Errors ( Thx to Mr. Satan )

    1.7.1 ( 20.06.2004 ) 
	- Added: Plugin now logs the gag reason

    1.7.0 ( 20.06.2004 )
	- Changed: Plugin has gotten a rewrite/cleanup
	- Changed: Plugin is now properbly format
	- Added: Ability to play a to gagged clients when their trying to talk ( Idea by Girthesniper )
	- Added: Ability to show the reason for the gag.
	- Fixed: Error where the command line would not read out more then 3 bytes of eatch var.

    1.6.2 ( 28.05.2004 )
	- Hack: UnGagPlayer echoing that unconnected clients had been ungagged when time ran out
    
    1.6.1 ( 25.05.2004 )
	- Changed: task is now registered with the same id as player index
	- Added: a define to change the default gag time

    1.6.0
	- Changed: Name change blocking enabled by default.
	- Added: Plugin now logs amx_ungag actions
	- Added: amx_ungag now echos target nick even if #userid was used
	- Added: amx_gag <nick/userid> <seconds or minuts> ( amx_gag EKS 120 / amx_gag EKS 2m )

    1.5.0
	- Added: Ability to block namechange on clients that are gagged ( Disabled by default, just change #define BlockNameChange )

    1.4.3
	- No update to the plugin, just added comments to help new admins.

    1.4.2
	- Fixed oversight that would allow none admins to use the plugin

    1.4.1 ( 01.03.2004 )
	- Now user log_amx style loggin
	- Now use AMXX engine to mute/unmute voicecomm

    1.4.0 ( 01.03.2004 )
	- Now only umutes voicecomm if player was muted by this plugin
	- Now echos what what the admin has muted.
	- To mute voicecomm you either need D2Tools or vexd. You can change what module to use in the define section.( look for: VoiceCommMute )
	- You can set #define VoiceCommMute to 0, and you dont need any extra modules anymore. But loose the ability to mute voicecomm. 

    1.3.1 ( 17.02.2004 )
	- Fixed muting voicecomm not working ( Info needed extracted from this plugin: http://djeyl.net/forum/index.php?showtopic=16533 | Proerrenrg )

    1.3.0 ( 17.02.2004 )
	- Now print nick and authid when a player disconnects
	- Now only one place in the code that can ungag a player ( ungag )
	- Added admin log
	- Fixed not gag flags not working
	- Changed plugin file name to: admin_gag.XXX
	- Minor code cleanup. More comments, Code cleaner & UnGagPlayer should be "faster"

    1.2.1 ( 06.02.2004 )
	- Fixed support for #userid again
	- Now use console_print to echo when player is not gagged ( in amx_ungag )

    1.2
	- Now supports muting voicecomm ( the flag c )
        - REQUIRES Vexd module, use 1.1 if you dont want to run this module
	
    1.1
	- Now supports amx_gag <nick> <time> ( Adds ab as flag if no other flag is entered.)
	- Now supports amx_gag <nick/auth>
	- Fixed echoing with amx_show_activity 1 not showing the secounds

    1.0  (Changes are from the orinal plugin to this one)
	- Now echos admin acctions based on amx_show_activity
	- Now echos when a player is ungagged by admin
	- Now echos when a player is ungagged becuse the "time" has run out.
	- Now echos when a gagged player disconnects
	- Admins with immunity flag can do actions on themself.
	- If you try to ungag a player thats not gagged, you get a "error" message
	- Changed the "your gagged" message so its simpler to spot in Steam.
	- Somehow the compiled file is smaller then with the orignal
*/
#define VoiceCommMute 1		// 0 = Disabled ( no extra module required ) | 1 = Voicecomm muteing enabled. ( requires engine module)
#define BlockNameChange 1	// 0 = Disabled | 1 = Block namechange on gagged clients
#define LogAdminActions 1	// 0 = Disabled | 1 = Admin actions will be logged
#define DefaultGagTime 600.0	// The std gag time if no other time was entered. ( this is 10 min ), Remember the value MUST contain a .0
#define PlaySound 1		// 0 = Disabled | 1 = Play a sound to gagged clients when their trying to talk
#define GagReason 1		// 0 = Disabled | 1 = Gagged clients can see why there where gagged when they try to talk
#define MaxPlayers 32

#include <amxmodx>
#include <amxmisc>
#include <engine>

new g_GagPlayers[MaxPlayers+1]	// Used to check if a player is gagged

#if GagReason == 1
new gs_GagReason[MaxPlayers+1][48]
#endif

public plugin_init() 
{ 
	register_plugin("Admin Gag","1.7.5","EKS") 
	register_clcmd("say","block_gagged") 
	register_clcmd("say_team","block_gagged") 
	register_concmd("amx_gag","CMD_GagPlayer",ADMIN_KICK,"<nick or #userid> <a|b|c> <time>") 
	register_concmd("amx_ungag","CMD_UnGagPlayer",ADMIN_KICK,"<nick or #userid>") 	
} 

public block_gagged(id){  // This function is what check the say / team_say messages & block them if the client is blocked.
	if(!g_GagPlayers[id]) return PLUGIN_CONTINUE // Is true if the client is NOT blocked.
	new cmd[5] 
	read_argv(0,cmd,4) 
	if ( cmd[3] == '_' )
		{ 
		if (g_GagPlayers[id] & 2){ 
#if GagReason == 1
			client_print(id,print_chat,"* You Are Gagged For The Following Reason: %s",gs_GagReason[id]) 
#else
			client_print(id,print_chat,"* You Have Been Gagged") 
#endif

#if PlaySound == 1
			client_cmd(id,"spk barney/youtalkmuch")
#endif
			return PLUGIN_HANDLED 
			} 
		} 
	else if (g_GagPlayers[id] & 1)   { 
#if GagReason == 1
			client_print(id,print_chat,"* You Are Gagged For The Following Reason: %s",gs_GagReason[id]) 
#else
			client_print(id,print_chat,"* You Have Been Gagged") 
#endif
#if PlaySound == 1
			client_cmd(id,"spk barney/youtalkmuch")
#endif
		return PLUGIN_HANDLED 
		} 
	return PLUGIN_CONTINUE 
	} 
public CMD_GagPlayer(id,level,cid) 
{ 
	if(!cmd_access (id,level,cid,1)) return PLUGIN_HANDLED
	new arg[32],VictimID
	
	read_argv(1,arg,31)  			// Arg contains Targets nick or Userid
	VictimID = cmd_target(id,arg,8)		// This code here tryes to find out the player index. Either from a nick or #userid
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id || !cmd_access (id,level,cid,2) ) { return PLUGIN_HANDLED; } // This code is kind of "long", its job is to. Stop actions against admins with immunity, Stop actions action if the user lacks access, or is a bot/hltv
	new s_Flags[4],VictimName[32],AdminName[32],flags,ShowFlags[32],CountFlags,s_GagTime[8],Float:f_GagTime

	read_argv(2,arg,31) 
	if (!arg[0]) // This means amx_gag <nick / userid> and no other flag or time was used.
	{
		f_GagTime = DefaultGagTime
		format(s_Flags,7,"abc")
	}
	else
	{
		if(contain(arg,"m")!=-1 && contain(arg,"!")==-1) // This means the time was entered in minuts and not seconds
		{
			copyc(s_GagTime,7,arg, 'm')
			f_GagTime = floatstr(s_GagTime) * 60
		}
		else if(isdigit(arg[0])&& contain(arg,"!")==-1) // The value was entered in seconds
		{
			format(s_GagTime,7,arg)
			f_GagTime = floatstr(s_GagTime)
		}
		read_argv(3,arg,8)
		if (!arg[0])	// No flag has been entered
			format(s_Flags,7,"abc")
		else if(contain(arg,"!")==-1)		// This means that arg did NOT contain the ! symbot
			format(s_Flags,7,arg)
		else if(contain(arg,"!")!=-1)		// This means that arg did DOES contain the ! symbot
			format(s_Flags,7,"abc")
		if (f_GagTime == 0.0)
		{
			read_argv(2,arg,8)
			if(contain(arg,"!")!=-1)
				format(s_Flags,3,"abc") // Flag was entered.
			else
				format(s_Flags,3,arg) // Flag was entered.
			f_GagTime = DefaultGagTime
		}
#if GagReason == 1
		for(new i=2;i<=4;i++)
		{
			read_argv(i,arg,31)
			if(contain(arg,"!")!=-1)
			{	
				read_args(arg,31)
				new tmp[32]
				copyc(tmp,32,arg,33)
				copy(gs_GagReason[VictimID],47,arg[strlen(tmp)+1])
			}
		}
		if(!gs_GagReason[VictimID][0])	// If no reason was entered, add the std reason.
			format(gs_GagReason[VictimID],47,"You Were Gagged For Not Following The Rules")
#endif
	}

	flags = read_flags(s_Flags) // Converts the string flags ( a,b or c ) into a int
	g_GagPlayers[VictimID] = flags 
#if VoiceCommMute == 1
	if(flags & 4) // This code checks if the c flag was used ( reprisented by the number 4 ), If pressent it mutes his voicecomm.
		set_speak(VictimID, SPEAK_MUTED)
#endif
	new TaskParm[1]		// For some reason set_task requires a array. So i make a array :)
	TaskParm[0] = VictimID
	set_task( f_GagTime,"task_UnGagPlayer",VictimID,TaskParm,1) 

	CountFlags = 0
	if (flags & 1)
	{
		format(ShowFlags,31,"say")
		CountFlags++
	}
	if (flags & 2)
	{
		if(CountFlags)
			format(ShowFlags,31,"%s / say_team",ShowFlags)
		if(!CountFlags)
			format(ShowFlags,31,"say_team")
	}
#if VoiceCommMute != 0
	if(flags & 4)
	{
		if(CountFlags)
			format(ShowFlags,31,"%s / voicecomm",ShowFlags)
		if(!CountFlags)
			format(ShowFlags,31,"voicecomm")		
	}
#endif
	get_user_name(id,AdminName,31)
	get_user_name(VictimID,VictimName,31)
	switch(get_cvar_num("amx_show_activity"))   
	{ 
#if GagReason == 1
		case 2:   client_print(0,print_chat,"ADMIN %s: Has Gagged %s From Speaking For %0.0f Minutes, For: %s ( %s )",AdminName,VictimName,(f_GagTime / 60),gs_GagReason[VictimID],ShowFlags) // debug added
   		case 1:   client_print(0,print_chat,"ADMIN: Has Gagged %s From Speaking For %0.0f Minutes, For: %s ( %s )",VictimName,(f_GagTime / 60),gs_GagReason[VictimID],ShowFlags) 
#else
		case 2:   client_print(0,print_chat,"ADMIN %s: Has Gagged %s From Speaking For %0.0f Minutes ( %s )",AdminName,VictimName,(f_GagTime / 60),ShowFlags) // debug added
   		case 1:   client_print(0,print_chat,"ADMIN: Has Gagged %s From Speaking For %0.0f Minutes ( %s )",VictimName,(f_GagTime / 60),ShowFlags) 
#endif
	 
	 }	
#if LogAdminActions == 1
	new parm[5] /*0 = Victim id | 1 = Admin id | 2 = Used to control if its a gag or Ungag | 3 = The gag flags | 4  = Length of the gag */
	parm[0] = VictimID
	parm[1] = id
	parm[2] = 0
	parm[3] = flags
	parm[4] = floatround(Float:f_GagTime)
	LogAdminAction(parm)
#endif
	return PLUGIN_HANDLED
} 

public CMD_UnGagPlayer(id,level,cid)   /// Removed gagged player ( done via console command )
{
	new arg[32],VictimID
	read_argv(1,arg,31)  			// Arg contains Targets nick
	
	VictimID = cmd_target(id,arg,8)		// This code here tryes to find out the player index. Either from a nick or #userid
	if ((get_user_flags(VictimID) & ADMIN_IMMUNITY) && VictimID != id || !cmd_access (id,level,cid,2) ) { return PLUGIN_HANDLED; } // This code is kind of "long", its job is to. Stop actions against admins with immunity, Stop actions action if the user lacks access, or is a bot/hltv

	new AdminName[32],VictimName[32] 

	get_user_name(id,AdminName,31)		// Gets Admin name
	get_user_name(VictimID,VictimName,31)

	if(!g_GagPlayers[VictimID])		// Checks if player has gagged flag
	{
		console_print(id,"%s Is Not Gagged & Cannot Be Ungagged.",arg)
		return PLUGIN_HANDLED
	}
	switch(get_cvar_num("amx_show_activity"))   
	{ 
   		case 2:   client_print(0,print_chat,"ADMIN %s: Has Ungagged %s",AdminName,VictimName) 
   		case 1:   client_print(0,print_chat,"ADMIN: Has Ungagged %s",VictimName) 
  	}

#if LogAdminActions == 1
	new parm[3] /*0 = Victim id | 1 = Admin id | 2 = Used to control if its a gag or Ungag | 3 = The gag flags | 4  = Length of the gag */
	parm[0] = VictimID
	parm[1] = id
	parm[2] = 1
	LogAdminAction(parm)
#endif
	remove_task(VictimID)		// Removes the set_task set to ungag the player
	UnGagPlayer(VictimID)		// This is the function that does the actual removal of the gag info
	return PLUGIN_HANDLED
} 

public client_disconnect(id) 
{ 
	if(g_GagPlayers[id]) // Checks if disconnected player is gagged, and removes flags from his id.
	{
		new Nick[32],Authid[35]
		get_user_name(id,Nick,31)
		get_user_authid(id,Authid,34)
		client_print(0,print_chat,"[AMXX] Gagged Player Has Disconnected ( %s <%s> )",Nick,Authid)
		remove_task(id)		// Removes the set_task set to ungag the player
		UnGagPlayer(id)		// This is the function that does the actual removal of the gag info
	}
}
#if BlockNameChange == 1
public client_infochanged(id)
{
	if(g_GagPlayers[id])
	{
		new newname[32], oldname[32]
		get_user_info(id, "name", newname,31)
		get_user_name(id,oldname,31)
	
		if (!equal(oldname,newname))
		{
			client_print(id,print_chat,"* Gagged Clients Cannot Change Their Name")
			set_user_info(id,"name",oldname)
		}
	}
}
#endif
public task_UnGagPlayer(TaskParm[])	// This function is called when the task expires
{
	new VictimName[32]
	get_user_name(TaskParm[0],VictimName,31)
	client_print(0,print_chat,"ADMIN: %s Is No Longer Gagged",VictimName)
	UnGagPlayer(TaskParm[0])
}
#if LogAdminActions == 1
stock LogAdminAction(parm[]) // This code is what logs the admin actions.
{ 
	new VictimName[32],AdminName[32],AdminAuth[35],VictimAuth[35]
	get_user_name(parm[1],AdminName,31)
	get_user_name(parm[0],VictimName,31)
	get_user_authid(parm[1],AdminAuth,34)
	get_user_authid(parm[0],VictimAuth,34)

#if GagReason == 1
	if(parm[2] == 0)
		log_amx("Gag: ^"%s<%s>^" Has Gagged %s <%s> for %d ( %d ) Reason: %s",AdminName,AdminAuth,VictimName,VictimAuth,parm[4],parm[3],gs_GagReason[parm[0]])
#else
	if(parm[2] == 0)
		log_amx("Gag: ^"%s<%s>^" Has Gagged %s <%s> for %d ( %d )",AdminName,AdminAuth,VictimName,VictimAuth,parm[4],parm[3])
#endif
	if(parm[2] == 1)
		log_amx("UnGag: ^"%s<%s>^" Has Ungagged %s<%s>",AdminName,AdminAuth,VictimName,VictimAuth)
}
#endif
stock UnGagPlayer(id) // This code is what removes the gag.
{ 
#if VoiceCommMute == 1
	if(g_GagPlayers[id] & 4)	// Unmutes the player if he had voicecomm muted.
		set_speak(id, SPEAK_NORMAL)
#endif
	g_GagPlayers[id] = 0
#if GagReason == 1
	setc(gs_GagReason[id],31,0)
#endif
} 
