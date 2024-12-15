#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/rott"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

[ ! -f "$GAMEDIR/conf/.rott/darkwar/config.rot" ] && $ESUDO cp -f -v "$GAMEDIR/conf/.rott/darkwar/config_bak.rot" "$GAMEDIR/conf/.rott/darkwar/config.rot"
[[ "$CFW_NAME" != *"ArkOS"* ]] && $ESUDO cp -f -v $GAMEDIR/timidity_cfg.bak $GAMEDIR/timidity.cfg

cd $GAMEDIR

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [[ $CFW_NAME == *"ArkOS"* ]] || [[ $CFW_NAME == *"ODROID"* ]]; then
	  pm_message "Preparing Swap File, please wait..."
    [ -f /swapfile ] && $ESUDO swapoff -v /swapfile
    [ -f /swapfile ] && $ESUDO rm -f /swapfile
    $ESUDO fallocate -l 384M /swapfile
    $ESUDO chmod 600 /swapfile
    $ESUDO mkswap /swapfile
    $ESUDO swapon /swapfile
    [ -f $GAMEDIR/timidity.cfg ] && $ESUDO rm -f $GAMEDIR/timidity.cfg
elif [[ "${CFW_NAME^^}" == "KNULLI" ]]; then
	  pm_message "Preparing Swap File, please wait..."
    [ -f /userdata/swapfile ] && $ESUDO swapoff -v /userdata/swapfile
    [ -f /userdata/swapfile ] && $ESUDO rm -f /userdata/swapfile
    $ESUDO fallocate -l 384M /userdata/swapfile
    $ESUDO chmod 600 /userdata/swapfile
    $ESUDO mkswap /userdata/swapfile
    $ESUDO swapon /userdata/swapfile
    [ -f $GAMEDIR/timidity.cfg ] && $ESUDO rm -f $GAMEDIR/timidity.cfg
fi

bind_directories ~/.rott $GAMEDIR/conf/.rott

if [[ "$ANALOG_STICKS" == '1' ]]; then
    GPTOKEYB_CONFIG="$GAMEDIR/rott1joy.gptk"  
elif [[ "$DEVICE_NAME" == "x55" ]] || [[ "$DEVICE_NAME" == "RG353P" ]] || [[ "$DEVICE_NAME" == "RG40XX-H" ]]; then
    GPTOKEYB_CONFIG="$GAMEDIR/rott_triggers.gptk"
else
    GPTOKEYB_CONFIG="$GAMEDIR/rott.gptk"
fi

[ ! -f "$GAMEDIR/DARKWAR.WAD" ] && ./text_viewer -f 25 -w -t "Missing gamedata" -m "Please place your DARKWAR.WAD, DARKWAR.RTC, and DARKWAR.RTL files into the /ports/rott/ directory! \n\nPress 'Select' to exit this Text Viewer"

$GPTOKEYB "rott_dw" -c "$GPTOKEYB_CONFIG" &
pm_platform_helper "$GAMEDIR/rott_dw"
./rott_dw

pm_finish
