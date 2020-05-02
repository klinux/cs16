/***********************************************************************
* amx_ejl_cmdlistgenerator.sma     version 1.0      July 19/2003
*  By:  Eric Lidman    Alias: Ludwig van      ejlmozart@hotmail.com
*  Upgrade: <a href='http://lidmanmusic.com/cs/plugins.html' target='_blank'>http://lidmanmusic.com/cs/plugins.html</a>  
*
*  This is basically amx_help with a twist. Use amx_help in game, 
*   but use this plugin to create command lists for your admins in an
*   html page format. I wrote this plugin because my admins are always
*   asking me to send them a command list by email. But since my server 
*   constantly changes as I write and add/subtract stuff, its hard to 
*   keep a list up to date. Now I can with ease and I can taylor the
*   list to the admin's access level. An html file is created in your
*   amx folder when you execute this command with all the commands that
*   are currently on your server.
*
* Commands:
*
*   amx_writehelp <flags>  --Writes a list of all the commands that an
*                            admin with the flags you enter has access to.
*                            If no flags are given, all flags are used.
*
*************************************************************************/

#include <amxmodx>
#include <amxmisc>

public admin_writehelp(id,level,cid){
	if (!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED

	new szSmall[32],filename[128],sflags[32],info[128],szBig[256]
	new flags,eflags
	read_argv(1,szSmall,31)
	if(!szSmall[0]) flags = read_flags("abcdefghijklmnopqrstuvwxyz")
	else flags = read_flags(szSmall)

	new cmdsnum = get_concmdsnum(flags)
	get_flags(flags,sflags,31)
	get_basedir(filename, 127)
	format(filename, 127, "%s/AMX_Command_List_for_access_%s.html", filename, sflags) 

	if(file_exists(filename)) delete_file(filename)

	console_print(id,"[AMXX] Creating html help file in amxmodx folder.")

	write_file(filename,"<html><head><title>AMX Command List</title></head><body>",-1)
	format (szBig,255,"AMXX COMMAND LIST FOR FLAGS: %s",sflags)   
	write_file(filename,szBig,-1)
	write_file(filename,"<table width=^"100%^" border=^"1^" cellpadding=^"0^" cellspacing=^"0^">",-1)    
	write_file(filename,"<tr bgcolor=gray><td>Nr</td><td>Command</td><td>Usage / description</td><td>Access flag required</td></tr>",-1) 

	for (new i = 0; i < cmdsnum; i++){
		get_concmd(i,szSmall,31,eflags,info,127,flags)

//		if(!((i+1)%10)) console_print(id,"[AMXX] Creating html help file. Progress: %d / %d",i+1,cmdsnum)

		get_flags(eflags,sflags,31)
		format(szBig,255,"%d %s %s %s ",i+1,szSmall,info,sflags) 
//		console_print(id,szBig)

		new ch = 0
		while (info[ch]){
			replace(info,127,"<","[")
			replace(info,127,">","]")
			ch++
		}
		format(szBig,255,"<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td></tr>",i+1,szSmall,info,sflags) 

		write_file(filename,szBig,-1)
	}
	write_file(filename,"</table></body></html>",-1)
	console_print(id,"[AMXX] Creating html help file - Done. Written: %d / %d lines",cmdsnum,cmdsnum)
	return PLUGIN_HANDLED 
}

public plugin_init() {
    register_plugin("Write help to html file","0.20","EJL") 
    register_concmd("amx_writehelp","admin_writehelp",ADMIN_RCON,"[flags] prints help for commands with this access level. If no flags all will be used.")
    return PLUGIN_CONTINUE
}
