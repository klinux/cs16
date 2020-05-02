/* 
Plugin: Admin Show 
Version: 1.0a 
Author: StuD|MaN with Help Freecode 
Info: Type in amx_admin_me 1 and it will show on top of your head. Even If Your Dead it will still follow you. Sprite Needed. 
Commands: 

   amx_admin_me <1/on || 0/off>    -       Turn Admin Show On or Off. 

 - 1.0a - added different sprite when admin is spectacting

TODO:
- display sprites above all admins ( parameter @)
- force hide for rcon admin (parameter !)

- autohide after in example 15 seconds , given as second parameter
- display of sprites depend on level
	with ban/rcon or more - red
	with kick/slay/cvars/maps - yellow
	with any other except z (user)- green

*/    

#include <amxmodx> 
#include <amxmisc> 

#define TE_PLAYERATTACHMENT 124 
#define TE_KILLPLAYERATTACHMENTS 125 

new adminS 
new admin_spectS 
new bool:isAdmin[32] 
///////////////////////////////////////////////////////////////////////////////
public admin(id, level, cid) 
{ 
   if (!cmd_access(id,level,cid,1)) 
   { 
      return PLUGIN_HANDLED 
   } 
   new arg[32] 
   read_argv(1,arg,31) 
   if(arg[0] == '1') 
   { 
      new parm[1] 
      parm[0] = id
      client_print(id,1,"You are now represented as admin") 
      set_task(1.0,"showS",1,parm,1,"b") 
      isAdmin[id] = true 

   } 
   else if(arg[0] == '0') 
   { 
      message_begin(MSG_ALL,SVC_TEMPENTITY) 
      write_byte(125) 
      write_byte(id) 
      message_end() 
      remove_task(1,1) 
      isAdmin[id] = false 
      client_print(id,1,"You no longer represented as admin") 
   } 
   return PLUGIN_CONTINUE 
} 
///////////////////////////////////////////////////////////////////////////////
public showS(parm[]) 
{ 
//   new id = parm[0] 
   message_begin(MSG_ALL,SVC_TEMPENTITY) 
   write_byte(124) 
   write_byte(parm[0]) //id
   write_coord(65) 
   if(is_user_alive(parm[0]))
      write_short(adminS) //spritename
   else
      write_short(admin_spectS) //spritename
   write_short(65) 
   message_end() 
} 
///////////////////////////////////////////////////////////////////////////////
public client_disconnect(id) 
{ 
   if(isAdmin[id]) 
   { 
      message_begin(MSG_ALL,SVC_TEMPENTITY) 
      write_byte(125) 
      write_byte(id) 
      message_end() 
   } 
} 
///////////////////////////////////////////////////////////////////////////////
public plugin_precache() 
{ 
   adminS = precache_model("sprites/admin.spr") 
   admin_spectS = precache_model("sprites/admin_spect.spr") 
} 
///////////////////////////////////////////////////////////////////////////////
public plugin_init() 
{ 
    register_plugin("Admin Show","1.0a","StuD|MaN") 
    register_clcmd("amx_admin_me","admin",ADMIN_KICK," <1, 0> - sow the admin psrite on/off") 
}

