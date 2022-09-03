#!/bin/bash

set -ex

install_path=/opt/retropie/supplementary/sinden

# Runs an action in the background via a job in order to avoid blocking udev
backgrounded() {
  echo "$install_path/sinden.sh" "${@}" | at now
}

# Adds a Sinden controller with the given video devpath / devname
add_device() {
  __modify_device start "${@}"
}

# Removes a Sinden controller with the given video devpath / devname
remove_device() {
  __modify_device stop "${@}"
}

# Modifies a Sinden controller state by running the given action
__modify_device() {
  local action=$1
  local video_devpath=$2
  local video_devname=$3

  local video_index=$(__lookup_video_index "$video_devname")
  local serial_port=$(__lookup_serial_port "$video_devpath")

  if [ "$video_index" != '0' ] || [ -z "$serial_port" ]; then
    return
  fi

  local player_id=$(__lookup_player_id "$serial_port")
  if [ -z "$player_id" ]; then
    # No player associated with this serial port
    return
  fi

  "$action" "$player_id"
}

# Looks up which video device we're dealing with (index 0 or 1)
__lookup_video_index() {
  if udevadm info --query=all --name="$video_devname" | grep -q index0; then
    echo 0
  else
    echo 1
  fi
}

# Looks up the Sinden serial port for the given video device
__lookup_serial_port() {
  local video_devpath=$1

  # Get the root USB devpath
  local filesystem_path="/sys$video_devpath"
  local root_usb_devpath=$(realpath "$filesystem_path/../../../..")

  # Look for a serial port, starting at the root
  local serial_port=$(find "$root_usb_devpath" -name dev | grep -oE "ttyACM[0-9]+")

  echo "$serial_port"
}

# Looks up which player number is associated with the given TTY devname
__lookup_player_id() {
  local serial_port=$1

  if grep -q "$serial_port" "$install_path/Player1/LightgunMono.exe.config"; then
    echo 1
  elif grep -q "$serial_port" "$install_path/Player2/LightgunMono2.exe.config"; then
    echo 2
  fi
}

# Starts all players
start_all() {
  start 1
  start 2
}

# Starts the given player number in the background
start() {
  local player_id=$1
  __run $player_id true
}

# Stops all players
stop_all() {
  stop 1
  stop 2
}

# Stops the given player number
stop() {
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
  local player_id=$1

  stop $player_id
  start $player_id
}

# Checks whether the sinden service is running for the given player id
__is_running() {
  local player_id=$1
  local bin_name=$(__player_bin_name "$player_id")

  pgrep -f "$bin_name" >/dev/null
}

# Runs the calibration test for the given player number
calibrate() {
  local player_id=$1
  __run $player_id false sdl 30
}

# Runs the Sinden lightgun software for the given player number
__run() {
  local player_id=$1
  local background=$2

  cd "$install_path/Player$player_id"

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

# Modifies the configuration on all players
edit_all() {
  edit 1 "${@}"
  edit 2 "${@}"
}

edit() {
  local player_id=$1

  local config_path="$install_path/Player$player_id/$(__player_bin_name "$player_id").config"

  for setting_config in "${@:2}"; do
    IFS='=' read setting_name setting_value <<< $setting_config
    sudo xmlstarlet edit --inplace --update "/*/*/*[@key=\"$setting_name\"]/@value" --value "$setting_value" "$config_path"
  done

  if __is_running "$player_id"; then
    restart "$player_id"
  fi
}

"${@}"
