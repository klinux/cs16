/* AMXMOD script. 
* 
* (c) Copyright 2000-2002, Rich - This file is provided as is (no warranties). 
* 
* AdminBeams 1.0 - Deadpeople see a laserbeam showing aiming of alive people. 
* 
* Thanks to: 
* 
* - Spacedude for 'Death Info Beams' code 
* - Hullu for concept from original metamod version 

An amx version of the metamod plugin. Laser beams show where players are aiming, but the lasers are only visible to deadplayers / spectators. Cvar amx_adminbeams 0/1 turns it on or off. 

The lasers are thin, and team coloured ( orange and cyan so not to be confused with ninjarope ) 

The point of this plugin is to show where people are aiming if you are third person or floating, as you will see the model only ever roughly points to where people are actually aiming ( bots seem to fake the model direction completely while they scan the area ) 



*/ 

#include <amxmodx> 

#define TE_BEAMPOINTS 0 

new icheck 
new m_spriteTexture 

public plugin_init() 
{ 
  register_plugin("AdminBeams", "0.1", "Rich") 
  register_cvar("amx_adminbeams","1") 
  set_task(0.1,"drawbeams",0,"",0,"b") 
  set_task(5.0,"check_cvar",0,"",0,"b") 
} 

public plugin_precache() 
{ 
  m_spriteTexture = precache_model("sprites/dot.spr") 
} 

public check_cvar() 
{ 
  if (get_cvar_num("amx_adminbeams")) 
  { 
    icheck = true 
  } 
  else 
  { 
    icheck = false 
  } 
  return PLUGIN_CONTINUE 
} 

public drawbeams() 
{ 
  if (!(icheck)) 
  { 
    return PLUGIN_CONTINUE 
  } 

  for(new a = 1; a <= get_maxplayers(); ++a) 
  { 
    if (!(is_user_alive(a)) && get_user_time(a) != 0) 
    { 
      for(new b = 1; b <= get_maxplayers(); ++b) 
      { 
        if (is_user_alive(b)) 
        { 
          new s_origin[3], f_origin[3] 
          get_user_origin(b,s_origin,1) 
          get_user_origin(b,f_origin,3) 

          message_begin(MSG_ONE, SVC_TEMPENTITY,{0,0,0},a) 
          write_byte( TE_BEAMPOINTS ) 
          write_coord(s_origin[0]) 
          write_coord(s_origin[1]) 
          write_coord(s_origin[2]) 
          write_coord(f_origin[0]) 
          write_coord(f_origin[1]) 
          write_coord(f_origin[2]) 
          write_short( m_spriteTexture ) 
          write_byte( 1 )  // framestart 
          write_byte( 1 )  // framerate 
          write_byte( 1 )  // life in 0.1's 
          write_byte( 2 )  // width 
          write_byte( 0 )  // noise 

          if (get_user_team(b) == 1) 
          { //team one
            write_byte( 255 )   // red 
            write_byte( 100 )   // green 
            write_byte( 0 )     // blue 
          } 
          else 
          { //team two
            write_byte( 0 )     // red 
            write_byte( 255 )   // green 
            write_byte( 255 )   // blue 
          } 
          write_byte( 200 )     // brightness 
          write_byte( 0 )       // speed 
          message_end() 
        } 
      } 
    } 
  } 
  return PLUGIN_CONTINUE 
} 


