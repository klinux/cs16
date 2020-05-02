/*
Ever Felt like flashing one specifiic idiot on the server just as he rushed into the fire zone... 
Of course you have...  And now you can...  

Just use the easy command amx_flash <nick> 
to make him see notin a short while (about 1,5 secs) 

Credits: 
Some Credit for this plugin goes to my idea supplier Blunted1  

To Do:: 
Make so you can decide how long to flash 



*/
#include <amxmodx> 
#include <amxmisc> 

new gMsgScreenFade 

public admin_flash(id,level,cid) { 
   if (!cmd_access(id,level,cid,2)) { 
      return PLUGIN_HANDLED 
   } 

   new victim[32] 
   read_argv(1,victim,31) 
//   new arg2[32] 
//   read_argv(2,arg2,31) 
//   new number=strtonum(arg2) 
//   if (number==0) number=1 

   if (victim[0]=='@') { 
      new team[32], inum 
      get_players(team,inum,"e",victim[1]) 
      if (inum==0) { 
         console_print(id,"[AMXX] No clients found on such team.") 
         return PLUGIN_HANDLED 
      } 
      for (new i=0;i<inum;++i) { 
         Flash(team[i]) 
         client_print(id,print_chat,"[AMXX] You Flashed all %s's.",victim[1]) 
         //client_print(id,print_chat,"[AMX] You Flashed all %s's for %i secs.",victim[1],number) 
      } 
   } 
   else if (victim[0]=='*') { 
      new all[32], inum 
      get_players(all,inum) 
      for (new i=0;i<inum;++i) { 
         Flash(all[i]) 
         client_print(id,print_chat,"[AMXX] You Flashed everyone.") 
         //client_print(id,print_chat,"[AMX] You Flashed everyone for %i secs.",number) 
      } 
   } 
   else { 
      new player = cmd_target(id,victim,0) 
      new playername[32] 
      get_user_name(player,playername,31) 

      if (!player) {  
         return PLUGIN_HANDLED 
      } 
      Flash(player) 
      client_print(id,print_chat,"[AMXX] You Flashed %s.",playername) 
      //client_print(id,print_chat,"[AMX] You Flashed %s for %i secs.",playername,number) 
   } 

   return PLUGIN_HANDLED 
} 

public Flash(id) { 

/*
//original one form the old release

   message_begin(MSG_ONE,gMsgScreenFade,{0,0,0},id) 
   write_short( 1<<15 ) //
   write_short( 1<<10 ) //
   write_short( 1<<12 ) //
   write_byte( 255 ) //
   write_byte( 255 ) //
   write_byte( 255 ) //
   write_byte( 255 ) //
   message_end() 
   emit_sound(id,CHAN_BODY, "weapons/flashbang-2.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH) 
*/
/*
//fom hldsdk src 2.3 dlls/util.cpp 
	MESSAGE_BEGIN( MSG_ONE, gmsgFade, NULL, pEntity->edict() );		// use the magic #1 for "one client"
		
		WRITE_SHORT( fade.duration );		// fade lasts this long
		WRITE_SHORT( fade.holdTime );		// fade lasts this long
		WRITE_SHORT( fade.fadeFlags );		// fade type (in / out)
		WRITE_BYTE( fade.r );				// fade red
		WRITE_BYTE( fade.g );				// fade green
		WRITE_BYTE( fade.b );				// fade blue
		WRITE_BYTE( fade.a );				// fade alpha

	MESSAGE_END();

//fade.duration = FixedUnsigned16( fadeTime, 1<<12 );		// 4.12 fixed
//fade.holdTime = FixedUnsigned16( fadeHold, 1<<12 );		// 4.12 fixed


*/
//new version
   message_begin(MSG_ONE,gMsgScreenFade,{0,0,0},id) 
   write_short( 1<<15 ) //duration
   write_short( 1<<10 ) //holdtime
   write_short( 1<<12 ) //fadeout set
   write_byte( 255 ) //r
   write_byte( 255 ) //g
   write_byte( 255 ) //b
   write_byte( 255 ) //a
   message_end() 

} 

public plugin_init() { 
   register_plugin("Admin Flash","1.0","AssKicR") 
   register_concmd("amx_flash","admin_flash",ADMIN_LEVEL_A,"< Nick, UniqueID, #userid, @TEAM, * > - flashes selected client(s)") 
   gMsgScreenFade = get_user_msgid("ScreenFade") 
   return PLUGIN_CONTINUE 
} 

public plugin_precache() 
{ 
    // FLASHBANG SOUND 
    precache_sound( "weapons/flashbang-2.wav" ) 
}

