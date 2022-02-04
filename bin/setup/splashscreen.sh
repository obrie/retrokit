#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

splashscreen_config='/opt/retropie/configs/all/splashscreen.cfg'
splashscreen_list='/etc/splashscreen.list'
splashscreens_dir="$HOME/RetroPie/splashscreens"

install() {
  if [ "$(setting 'has("splashscreen")')" == 'true' ]; then
    local media_file="$splashscreens_dir/splash.mp4"
    local media_url=$(setting '.splashscreen')

    # Track a version number for the splashscreen in case the source changes
    local version_file="$splashscreens_dir/splash.version"
    local version=($(echo "$media_url" | md5sum))

    mkdir -pv "$splashscreens_dir"

    # Download media
    if [ ! -f "$version_file" ] || [ "$(cat "$version_file")" != "$version" ]; then
      download "$(setting '.splashscreen')" "$media_file" force=true
      echo "$version" > "$version_file"
    fi

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
  rm -fv "$splashscreens_dir/splash.mp4" "$splashscreens_dir/splash.versino"
  restore
}

"${@}"
