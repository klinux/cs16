POD-bot 2.6 metamod.

This version of POD-bot MUST be used with metamod. You MUST have metamod
installed in order to run it. Forget about editing the liblist.gam, it simply
won't work.

The "podbot" directory contained in this archive MUST be extracted in the
"addons" directory of Counter-Strike. If this directory doesn't exist yet,
create it. You have then:

C:\SIERRA\Half-Life\cstrike\addons\podbot
(Counter-Strike 1.5 MOD version)

or

C:\SIERRA\Counter-Strike\cstrike\addons\podbot
(Counter-Strike 1.5 retail)

or

C:\Program Files\Steam\SteamApps\[EMAIL]\counter-strike\cstrike\addons\podbot
(Counter-Strike 1.6 / STEAM)

Get metamod from http://www.metamod.org, or install AdminMod (since AdminMod
installs metamod automatically during the setup).

Then edit metamod's plugins.ini file and add a line like this one:

   win32 addons/podbot/podbot_mm.dll

or

   linux addons/podbot/podbot_mm_i386.so

depending on whether you run Windows or Linux. Once you do that the bot is
installed and ready to work.

If it doesn't, TRIPLE CHECK your installation before complaining. It's most
likely your fault. First ensure that metamod is installed and working. Then,
bring down the server console and type "meta list". If metamod reports "BADF"
then most likely you placed the POD-bot folder in the wrong directory. The
"podbot" folder MUST be in the "addons" directory, which one MUST be in the
"cstrike" directory.

This version of POD-bot works with Counter-Strike 1.6 (STEAM), and 1.5.

We advise you to delete any previous .pxp files that you may have used with
former versions of this bot.

Since the bot now supports the new CS 1.6 weapons, you MUST use the included
bot_weapons.cfg file which takes them into account. If you attempt to use an
older weapon configuration file from POD-bot 2.5 or 2.6, the bot will crash.


A Bots United production.
http://forums.bots-united.com/

This bot is copyright Markus "Count Floyd" Klinge and no one else. He stopped
working on it and released his source to the public so don't annoy him with
help requests. Post your requests in the Bots United forums instead or use
one of the other POD-bot clones featured at Bots United (IvPBot, E[POD]Bot,
YaPB...)
