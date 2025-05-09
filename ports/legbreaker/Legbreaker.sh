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
source $controlfolder/device_info.txt

[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

GAMEDIR=/$directory/ports/legbreaker/
CONFDIR="$GAMEDIR/conf/"

# ensure the conf directory exists
mkdir -p "$GAMEDIR/conf"

# set the xdg environment variables for config & savefiles
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"

cd $GAMEDIR

# patch game
if [ -f "gamedata/Legbreaker.pck" ]; then
    $controlfolder/xdelta3 -d -s "gamedata/Legbreaker.pck" "gamedata/Legbreaker_patch.xdelta" "gamedata/Legbreaker_patched.pck" && rm "gamedata/Legbreaker.pck"
fi

runtime="frt_3.2.3"
if [ ! -f "$controlfolder/libs/${runtime}.squashfs" ]; then
  # check for runtime if not downloaded via pm
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    echo "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info." > /dev/tty0
    sleep 5
    exit 1
  fi

  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${runtime}.squashfs"
fi

# setup godot
godot_dir="$HOME/godot"
godot_file="$controlfolder/libs/${runtime}.squashfs"
$ESUDO mkdir -p "$godot_dir"
$ESUDO umount "$godot_file" || true
$ESUDO mount "$godot_file" "$godot_dir"
PATH="$godot_dir:$PATH"

export FRT_NO_EXIT_SHORTCUTS=FRT_NO_EXIT_SHORTCUTS

$ESUDO chmod 666 /dev/uinput
$GPTOKEYB "$runtime" -c "./legbreaker.gptk" &
SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" "$runtime" $GODOT_OPTS --main-pack "gamedata/Legbreaker_patched.pck"

$ESUDO umount "$godot_dir"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0

