#include <amxmodx>
#include <engine>

//custom flashlight
new flashlight[33];
new color[33];
new g_color[][] = { 
        {100,0,0},{0,100,0},{0,0,100},{0,100,100},{100,0,100},{100,100,0},
        {100,0,60},{100,60,0},{0,100,60},{60,100,0},{0,60,100},{60,0,100},
        {100,50,50},{50,100,50},{50,50,100},{0,50,50},{50,0,50},{50,50,0}
};
new flashlight_custom, flashlight_radius, flashlight_only_ct;
new gmsgFlashlight;

public client_putinserver(id) {
    random_num(0, sizeof( g_color ) - 1);
}

// Plugin initialization
public plugin_init()
{
  register_event("Flashlight","event_flashlight","b");
  flashlight_custom = register_cvar("flashlight_custom","1");
  flashlight_radius = register_cvar("flashlight_radius","20"); // 9 is like the real flashlight
  flashlight_only_ct = register_cvar("flashlight_only_ct","1"); // only CT have flashlight
  gmsgFlashlight = get_user_msgid("Flashlight");
  set_cvar_num("mp_flashlight",1);
}


public FlashedEvent( id )
{
    if(get_pcvar_num(amx_hs_flash))
        return PLUGIN_HANDLED;
    return PLUGIN_CONTINUE;
}

public event_flashlight(id) {
    if(!get_pcvar_num(flashlight_custom)) {
        return;
    }

    new CsTeams:team = cs_get_user_team(id)
    if( team != CS_TEAM_CT && get_pcvar_num(flashlight_only_ct))
    {
        flashlight[id] = 0;
    }
    else
    {
        if(flashlight[id]) {
            flashlight[id] = 0;
            color[id] = random_num(0, sizeof( g_color ) - 1);
        }
        else {
            flashlight[id] = 1;
        }
    }

    message_begin(MSG_ONE,gmsgFlashlight,_,id);
    write_byte(flashlight[id]);
    write_byte(100);
    message_end();

    entity_set_int(id,EV_INT_effects,entity_get_int(id,EV_INT_effects) & ~EF_DIMLIGHT);
}

public client_prethink(id) {
    if(!get_pcvar_num(flashlight_custom)) {
        return;
    }
    
    new a = color[id];

    if(flashlight[id]) {
        new origin[3];
        get_user_origin(id,origin,3);
        message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
        write_byte(TE_DLIGHT); // TE_DLIGHT
        write_coord(origin[0]); // X
        write_coord(origin[1]); // Y
        write_coord(origin[2]); // Z
        write_byte(get_pcvar_num(flashlight_radius)); // radius
        write_byte(g_color[a][0]); // R
        write_byte(g_color[a][1]); // G
        write_byte(g_color[a][2]); // B
        write_byte(1); // life
        write_byte(60); // decay rate
        message_end();
    }
}
