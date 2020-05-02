/* AMX Mod script. 
*
* (c) 2003, OLO 
* This file is provided as is (no warranties).
*/

#include <amxmodx>
#include <amxmisc>

new const PLUGINNAME[] = "Welcome Message"
new const AUTHOR[] = "KWo" 

// Standard Contstants.
#define MAX_TEAMS               2
#define MAX_PLAYERS             32 + 1

#define MAX_NAME_LENGTH         31
#define MAX_WEAPON_LENGTH       31
#define MAX_TEXT_LENGTH         255
#define MAX_BUFFER_LENGTH       2047

// Settings (comment unwanted options)
#define SHOW_MODS
//#define READ_FROM_FILE
#define SHOW_TIME_AND_IP

new g_cstrikeRunning
new g_teamScore[2]
new g_sBuffer[MAX_BUFFER_LENGTH+1]                  = "" 
new t_sName[MAX_NAME_LENGTH+1]                      = ""

#if defined READ_FROM_FILE
new g_motdFile[64]
#endif

public plugin_init()
{
  register_plugin(PLUGINNAME,AMXX_VERSION_STR,AUTHOR) 
  g_cstrikeRunning = is_running("cstrike")
  if ( ( g_cstrikeRunning = is_running("cstrike") ) != 0 )  
    register_event("TeamScore", "team_score", "a")
  
#if defined READ_FROM_FILE
  get_configsdir(g_motdFile, 63)
  format(g_motdFile, 63, "%s/conmotd.txt", g_motdFile)
#endif  
}

// new g_Bar[] = "=============="

public client_putinserver(id) {
	if (!is_user_bot(id))	set_task(10.0,"dispwmess",id)  
}  

public dispwmess(id) {
  format_wmess( id, g_sBuffer )
  get_user_name( id, t_sName, MAX_NAME_LENGTH + 1 )
  show_motd( id, g_sBuffer, t_sName )
}

public format_wmess( id, sBuffer[MAX_BUFFER_LENGTH+1] ) {
  
  new name[32], hostname[64], nextmap[32], mapname[32]
  new iLen 
  get_cvar_string("hostname",hostname,63) 
  get_user_name(id,name,31)  
  get_mapname(mapname,31)
  get_cvar_string("amx_nextmap",nextmap,31)

#if defined NO_STEAM
  iLen = format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "Hello %s, welcome to %s^n^n",name,hostname )
#else
	iLen = format(sBuffer, MAX_BUFFER_LENGTH, "<body bgcolor=#000000><font color=#FFB000><pre>")
	iLen +=format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "Hello %s, welcome to %s^n^n",name,hostname )
#endif


#if defined SHOW_TIME_AND_IP  
  new stime[64],ip[32]
  get_time("%A %B %d, %Y - %H:%M:%S",stime,63)
  get_user_ip(id,ip,31)
  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Today is %s^n",stime )
  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   You are playing from: %s^n",ip )
#endif

  new maxplayers = get_cvar_num("sv_visiblemaxplayers")
  new players = get_playersnum()
  if ( maxplayers < 0 ) maxplayers = get_maxplayers()

  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Players on server: %d/%d^n",players,maxplayers)
  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Current map: %s, Next map: %s^n",mapname,nextmap)
  
  // Time limit , time remaining , maxrounds and winlimit
  new Float:mp_timelimit = get_cvar_float("mp_timelimit")
  new mp_maxrounds = get_cvar_num("mp_maxrounds")
  new mp_winlimit = get_cvar_num("mp_winlimit")
  if (mp_timelimit){
    new timeleft = get_timeleft()
    if (timeleft > 0) {
      iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Time Left: %d:%02d of %.0f minutes^n",  timeleft / 60, timeleft % 60, mp_timelimit )
    }
  }
  else{
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   No time limit^n")
  }
  if (mp_maxrounds && g_cstrikeRunning){
    new roundsleft = mp_maxrounds - ( g_teamScore[0] + g_teamScore[1] + 1 )
    if (roundsleft > 0){
      iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Rounds left: %d of total rounds %d^n",  roundsleft, mp_maxrounds )
      iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Current round: %d^n",  g_teamScore[0] + g_teamScore[1] + 1 )
    }
  }
  if (mp_winlimit && g_cstrikeRunning){    
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Winlimit is %d^"", mp_winlimit )
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Current round: %d^n",  g_teamScore[0] + g_teamScore[1] + 1 )
  }

  // C4 and FF
  if ( g_cstrikeRunning ){
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   Friendly fire is %s^n", get_cvar_float("mp_friendlyfire") ? "ON" : "OFF") 
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   C4 timer is set to %.0f sec.^n",get_cvar_float("mp_c4timer"))
  }


  // Server Mods
#if defined SHOW_MODS
  new mod_ver[32]
  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "^n   Server mods:^n")
  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o AMX Mod X %s^n",AMXX_VERSION_STR)    
  get_cvar_string("statsme_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o StatsMe %s^n",mod_ver)
  }
  get_cvar_string("clanmod_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o ClanMod %s^n",mod_ver)
  }
  get_cvar_string("admin_mod_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o AdminMod %s^n",mod_ver)
  }
  get_cvar_string("chicken_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o Chicken %s^n",mod_ver)
  }                  
  get_cvar_string("csguard_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o CSGuard %s^n",mod_ver)
  }  
  get_cvar_string("hlguard_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o HLGuard %s^n",mod_ver)
  }  
  get_cvar_string("plbot_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o PLBot %s^n",mod_ver)
  }  
  get_cvar_string("pb_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o PODBot %s^n",mod_ver)
  }  
  get_cvar_string("booster_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o HL-Booster %s^n",mod_ver)
  }  
  get_cvar_string("axn_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o AXN %s^n",mod_ver)
  }  
  get_cvar_string("bmx_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o BMX %s^n",mod_ver)
  }  
  get_cvar_string("cdversion",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o Cheating-Death %s in %s Mode^n",
                  mod_ver, get_cvar_num("cdrequired") ? "Required" : "Optional" )
  }  
  get_cvar_string("atac_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o ATAC %s%s^n" , mod_ver , get_cvar_num("atac_status") 
                  ? " (setinfo atac_status_off 1 disables Live Status)" : "" )
  }  
  get_cvar_string("statsx_version",mod_ver,31)
  if (mod_ver[0]) {
    iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "   o StatsX %s^n" , mod_ver )
  }  

  
#endif

  // Info. from custom file
#if defined READ_FROM_FILE
  if (file_exists(g_motdFile)) {
    new message[192], len, line = 0
    client_cmd(id, "echo %s%s%s%s",g_Bar,g_Bar,g_Bar,g_Bar)   
    while(read_file(g_motdFile,line++,message,191,len))
      iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
                  "%s^n",message)
  }
#endif
//  iLen += format( sBuffer[iLen], MAX_BUFFER_LENGTH - iLen,
//
//                  %s%s%s%s^n",g_Bar,g_Bar,g_Bar,g_Bar)

}

public team_score(){
  new team[2]
  read_data(1,team,1)
  g_teamScore[ (team[0]=='C') ? 0 : 1 ] = read_data(2)
}
