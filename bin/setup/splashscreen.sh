#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

splashscreen_config='/opt/retropie/configs/all/splashscreen.cfg'
splashscreen_list='/etc/splashscreen.list'
splashscreens_dir="$HOME/RetroPie/splashscreens"

install() {
  if [ "$(setting 'has("splashscreen")')" == 'true' ]; then
    # Media
    local media_file="$splashscreens_dir/splash.mp4"
    mkdir -pv "$splashscreens_dir"
    download "$(setting '.splashscreen')" "$media_file"

    configure
  else
    restore
  fi
}

configure() {
  backup_and_restore "$splashscreen_config"
  backup_and_restore "$splashscreen_list" as_sudo=true

  # Enable splashscreen
  local media_file="$splashscreens_dir/splash.mp4"
  echo "$media_file" | sudo tee "$splashscreen_list" >/dev/null

  # Ensure splashscreen doesn't get cut off based on video length
  local duration=$(ffprobe -i "$media_file" -show_entries format=duration -v quiet -of csv="p=0" | grep -oE "^[0-9]+")
  echo "Setting splashscreen duration to $duration seconds"
  .env -f "$splashscreen_config" set DURATION="\"$duration\""
}

restore() {
  restore_file "$splashscreen_list" as_sudo=true delete_src=true
  restore_file "$splashscreen_config" delete_src=true
}

uninstall() {
  rm -fv "$splashscreens_dir/splash.mp4"
  restore
}

"${@}"
