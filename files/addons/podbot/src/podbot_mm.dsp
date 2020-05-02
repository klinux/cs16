# Microsoft Developer Studio Project File - Name="podbot_mm" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=podbot_mm - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "podbot_mm.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "podbot_mm.mak" CFG="podbot_mm - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "podbot_mm - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""$/SDKSrc/Public/dlls", NVGBAAAA"
# PROP Scc_LocalPath "."
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe
# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir ".\Release"
# PROP BASE Intermediate_Dir ".\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir ".\Release"
# PROP Intermediate_Dir ".\Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /G5 /MT /W3 /WX /GX /O2 /I "../metamod" /I "../../devtools/hlsdk-2.3/singleplayer/dlls" /I "../../devtools/hlsdk-2.3/singleplayer/engine" /I "../../devtools/hlsdk-2.3/singleplayer/pm_shared" /I "../../devtools/hlsdk-2.3/singleplayer/common" /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /Fr /c
# SUBTRACT CPP /Z<none> /YX
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386 /def:".\podbot_mm.def"
# SUBTRACT LINK32 /pdb:none /incremental:yes /map /debug
# Begin Special Build Tool
SOURCE="$(InputPath)"
PreLink_Desc=Updating resources...
PreLink_Cmds=makeres -d"metamod plugin" podbot_mm.rc	rc podbot_mm.rc 	move podbot_mm.RES Release
# End Special Build Tool
# Begin Target

# Name "podbot_mm - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat;for;f90"
# Begin Source File

SOURCE=.\bot.cpp
DEP_CPP_BOT_C=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\bot_chat.cpp
DEP_CPP_BOT_CH=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\bot_client.cpp
DEP_CPP_BOT_CL=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\bot_combat.cpp
DEP_CPP_BOT_CO=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\bot_globals.cpp
DEP_CPP_BOT_G=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\bot_sounds.cpp
DEP_CPP_BOT_S=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\compress.cpp
# End Source File
# Begin Source File

SOURCE=.\dll.cpp
DEP_CPP_DLL_C=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\engine.cpp
DEP_CPP_ENGIN=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\podbot_mm.rc
# End Source File
# Begin Source File

SOURCE=.\util.cpp
DEP_CPP_UTIL_=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# Begin Source File

SOURCE=.\waypoint.cpp
DEP_CPP_WAYPO=\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\const.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\crc.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\cvardef.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\entity_state.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\event_flags.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\in_buttons.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\common\weaponinfo.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\cdll_dll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\enginecallback.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\extdll.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\dlls\vector.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\archtypes.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\custom.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\edict.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\eiface.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\progdefs.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\engine\Sequence.h"\
	"..\..\devtools\hlsdk-2.3\singleplayer\pm_shared\pm_info.h"\
	"..\metamod\dllapi.h"\
	"..\metamod\engine_api.h"\
	"..\metamod\h_export.h"\
	"..\metamod\log_meta.h"\
	"..\metamod\meta_api.h"\
	"..\metamod\mhook.h"\
	"..\metamod\mreg.h"\
	"..\metamod\mutil.h"\
	"..\metamod\osdep.h"\
	"..\metamod\plinfo.h"\
	"..\metamod\sdk_util.h"\
	"..\metamod\types_meta.h"\
	".\bot.h"\
	".\bot_globals.h"\
	".\bot_weapons.h"\
	".\waypoint.h"\
	
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl;fi;fd"
# Begin Source File

SOURCE=.\bot.h
# End Source File
# Begin Source File

SOURCE=.\bot_globals.h
# End Source File
# Begin Source File

SOURCE=.\bot_weapons.h
# End Source File
# Begin Source File

SOURCE=.\waypoint.h
# End Source File
# End Group
# End Target
# End Project
