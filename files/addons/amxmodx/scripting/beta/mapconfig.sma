/* AMX Mod X script.
*
* Custom Map Configs 0.8
*  Set map-specific variables and commands
*
* by JustinHoMi (justin@justinmitchell.net)
*  http://www.modkillers.com
*  #modkillers in irc.gamesnet.net
*
* Place your custom configs in the designated folder
*  (addons/amx/map_configs by default)
* Configs should be in the format "mapname.cfg"
* Insert any cvar or cmd to be executed at map change
*
* Changelog:
*  1.0.0 - Ported to AMX MOD X (without translations)
*  0.9.9 - Added translations support for AMX Mod 0.9.9
*  0.61  - Changes load delay to 6s (to work better with SQL ServerCfg)
*  0.6   - Execs configs rather than loading file
*        - Delays execution for 5s after map changes
*  0.5   - Initial release
*
*/

#include <amxmodx>
#include <amxmisc>

new currentmap[32]

public plugin_init(){
	register_plugin("Custom Map Configs","0.9.9","JustinHoMi")

	new filename[128], filepath[64]        
	get_configsdir( filepath, 63 )
	format(filepath, 63, "%s/maps", filepath)
	get_mapname(currentmap,31)
	new len = format(filename,127,"%s/%s.cfg",filepath,currentmap)

	if (file_exists(filename))
	{
		set_task(6.1,"delayed_load",0,filename,len+1)
	}
}

public delayed_load(filename[])
{
	server_print("Loading custom map config for %s", currentmap)
	server_cmd("exec %s",filename)
}