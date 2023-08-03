#!/bin/bash

set -ex

install_dir=/opt/retropie/supplementary/sinden

usage() {
  set +x

  echo "usage:"
  echo " $0 backgrounded <add_device|remove_device> <devpath> <devname>"
  echo " $0 add_device <devpath> <devname>"
  echo " $0 remove_device <devpath> <devname>"
  echo " $0 status <player_id>"
  echo " $0 start_all"
  echo " $0 start <player_id>"
  echo " $0 stop_all"
  echo " $0 stop <player_id>"
  echo " $0 restart <player_id>"
  echo " $0 calibrate <player_id>"
  echo " $0 edit_screen_height <height_in_inches> ..."
  echo " $0 edit_all key1=value1 key2=value2 ..."
  echo " $0 edit <player_id> key1=value1 key2=value2 ..."
  echo " $0 get_screen_height <player_id>"
  echo " $0 get <player_id> key"
  exit 1
}

# Runs an action in the background via a job in order to avoid blocking udev
backgrounded() {
  echo "$install_dir/sinden.sh" "${@}" | at now
}

# Adds a Sinden controller with the given tty devpath
add_device() {
  [ "$#" -eq 1 ] || usage

  __modify_device start "${@}"
}

# Removes a Sinden controller with the given tty devpath
remove_device() {
  [ "$#" -eq 1 ] || usage

  __modify_device stop "${@}"
}

# Modifies a Sinden controller state by running the given action
__modify_device() {
  local action=$1
  local tty_devpath=$2
  local serial_port=$(echo "$tty_devpath" | grep -oE "ttyACM[0-9]+")

  if [ -z "$serial_port" ]; then
    return
  fi

  local player_id=$(__lookup_player_id "$serial_port")
  if [ -z "$player_id" ]; then
    # No player associated with this serial port
    return
  fi

  "$action" "$player_id"
}

# Looks up which player number is associated with the given TTY devname
__lookup_player_id() {
  local serial_port=$1

  if grep -q "$serial_port" "$install_dir/Player1/LightgunMono.exe.config"; then
    echo 1
  elif grep -q "$serial_port" "$install_dir/Player2/LightgunMono2.exe.config"; then
    echo 2
  fi
}

# Starts all players
start_all() {
  [ "$#" -eq 0 ] || usage

  if ! __is_running 1; then
    start 1
  fi

  if ! __is_running 2; then
    start 2
  fi
}

# Starts the given player number in the background
start() {
  [ "$#" -eq 1 ] || usage

  local player_id=$1
  __run $player_id true
}

# Stops all players
stop_all() {
  [ "$#" -eq 0 ] || usage

  stop 1
  stop 2
}

# Stops the given player number
stop() {
  [ "$#" -eq 1 ] || usage

  local player_id=$1
  local bin_name=$(__player_bin_name "$player_id")
  local lockfile="/tmp/$bin_name.lock"

  if [ -f "$lockfile" ]; then
    local pid=$(sudo cat "$lockfile")
    sudo kill $pid || true
    sudo rm -f "$lockfile"
  fi

  # Just in case the lock file doesn't exist...
  sudo pkill -f "$bin_name"
}

# Stops / starts the given player number
restart() {
  [ "$#" -eq 1 ] || usage

  local player_id=$1

  stop $player_id
  start $player_id
}

status() {
  [ "$#" -eq 1 ] || usage

  local player_id=$1

  if ! __is_running "$player_id"; then
    exit 1
  fi
}

# Checks whether the sinden service is running for the given player id
__is_running() {
  local player_id=$1
  local bin_name=$(__player_bin_name "$player_id")

  pgrep -f "$bin_name" >/dev/null
}

# Runs the calibration test for the given player number
calibrate() {
  [ "$#" -eq 1 ] || usage

  local player_id=$1

  # Make sure the service is stopped before running the calibration
  # tool, otherwise it can cause problems
  stop $player_id

  # Start calibration
  __run $player_id false sdl 30

  # Start the main service back up
  start $player_id
}

# Runs the Sinden lightgun software for the given player number
__run() {
  local player_id=$1
  local background=$2

  cd "$install_dir/Player$player_id"

  local mono_bin=mono
  if [ "$background" == 'true' ]; then
    mono_bin=mono-service
  fi

  sudo $mono_bin $(__player_bin_name "$player_id") ${@:3}
}

__player_bin_name() {
  local player_id=$1
  if [ "$player_id" == '1' ]; then
    echo LightgunMono.exe
  else
    echo LightgunMono$player_id.exe
  fi
}

# Real guns and real gun sights don't 100% line up as the sight is a couple of cm's
# above the center of the barrel.  This is the same with lightguns.  However, when
# you calibrate the lightgun, Sinde will make an x/y pixel adjustment so that they
# *do* line up.
#
# Unfortunately, this only works if you remain the same distance from the screen.
# If you move closer or further away from the screen, that adjustment needs to be
# changed *unless* you know the height of the screen.  Once Sinden knows the height,
# it can update the x/y pixel adjustment based on how close / far away you are from
# the screen.
edit_screen_height() {
  [ "$#" -eq 1 ] || usage

  local height=$1
  local offset=$(bc -l <<< "x = (120 / $height); scale = 2; x / 1")
  edit_all "OffsetGunsightY=$offset"
}

# Modifies the configuration on all players
edit_all() {
  [ "$#" -gt 0 ] || usage

  edit 1 "${@}"
  edit 2 "${@}"
}

edit() {
  [ "$#" -gt 1 ] || usage

  local player_id=$1
  local config_file=$(__get_config_file "$1")

  for setting_config in "${@:2}"; do
    IFS='=' read setting_name setting_value <<< $setting_config
    sudo xmlstarlet edit --inplace --update "/*/*/*[@key=\"$setting_name\"]/@value" --value "$setting_value" "$config_file"
  done

  if __is_running "$player_id"; then
    restart "$player_id"
  fi
}

# Get the screen height currently configured
get_screen_height() {
  local offset_gunsight_y=$(get 1 OffsetGunsightY)
  if [ -n "$offset_gunsight_y" ]; then
    bc -l <<< "x = (120 / $offset_gunsight_y); scale = 2; x / 1"
  fi
}

# Get a setting for the given player number
get() {
  [ "$#" -eq 2 ] || usage

  local player_id=$1
  local setting_name=$2
  local config_file=$(__get_config_file "$1")

  xmlstarlet sel -t -v "/*/*/*[@key=\"$setting_name\"]/@value" "$config_file" || true
}

# Get the path to the given player's configuration file
__get_config_file() {
  local player_id=$1
  echo "$install_dir/Player$player_id/$(__player_bin_name "$player_id").config"
}

[ "$#" -gt 0 ] || usage

"${@}"
