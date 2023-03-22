#!/bin/bash

# This script shows the launch image in the background while allowing
# RetroPie to start the game in the foreground.  It improves the load time
# by a few seconds.
# 
# It also proactively clears the screen so that when you exit the game,
# the transition is smooth from game -> black screen -> emulation station.
# Without this, there's a hard transition from game -> launch image ->
# black screen -> emulation station, which is a bit jarring.

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# The maximum amount of time that we'll show the launch image
MAX_LOADING_TIME=10

show() {
  local system=$1
  local emulator=$2
  local rom_path=$3

  __blank_screen

  local rom_filename=$(basename "$rom_path")
  local rom_name=${rom_filename%.*}

  # Find a matching launch image
  local launch_image_paths=(
    "/opt/retropie/configs/$system/images/$rom_name-launching-extended"
    "/opt/retropie/configs/$system/launching-extended"
    "/opt/retropie/configs/all/launching-extended"
  )
  local launch_image_path
  local launch_image
  local image_ext
  for launch_image_path in "${launch_image_paths[@]}"; do
    for image_ext in png jpg; do
      if [ -f "$launch_image_path.$image_ext" ]; then
        launch_image="$launch_image_path.$image_ext"
        break 2
      fi
    done
  done

  if [ -n "$launch_image" ]; then
    # Change tty to graphics mode
    python "$dir/tty.py" /dev/tty graphics

    # Determine the size of the screen we're working with
    local screen_dimensions=$(fbset -s | grep -E "^mode" | grep -oE "[0-9]+x[0-9]+")
    IFS=x read -r screen_width screen_height <<< "$screen_dimensions"

    # Show launching screen.  We use ffmpeg instead of fbi since it will
    # draw to the screen and then exit, leaving the image there.  fbi has
    # a lot else going on with responding to keyboard inputs and changing
    # the virtual terminal when exiting, causing emulators to fail.
    #
    # In order to have the best viewer experience, the launching image
    # fills the screen without changing the aspect ratio.  Any space not
    # filled will be padded with black bars.
    ffmpeg \
      -i "$launch_image" \
      -vf scale="w=$screen_width:h=$screen_height:force_original_aspect_ratio=decrease,pad=$screen_width:$screen_height:(ow-iw)/2:(oh-ih)/2" \
      -f fbdev \
      -pix_fmt rgb565le \
      -y /dev/fb0

    # Monitor launching screen
    __watch_screen &
  fi
}

__blank_screen() {
  dd if=/dev/zero of=/dev/fb0 &>/dev/null
}

# Watches for interrupts to the launching screen
__watch_screen() {
  while true; do
    # User has opened runcommand dialog or we're no longer running the game, abort
    if pgrep dialog || ! kill -0 $PPID; then
      break
    fi

    # Maximum time reached for showing the launching screen
    if [ $SECONDS -ge $MAX_LOADING_TIME ]; then
      clear_screen
      break
    fi

    sleep 1
  done
}

clear() {
  # Clear the screen as quickly as we can
  __blank_screen

  # Restore text mode for the console
  python "$dir/tty.py" /dev/tty text
}

"${@}"
