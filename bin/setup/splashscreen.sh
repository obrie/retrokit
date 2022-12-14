#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='splashscreen'
setup_module_desc='Splashscreen configuration'

splashscreen_config='/opt/retropie/configs/all/splashscreen.cfg'
splashscreen_list='/etc/splashscreen.list'
splashscreens_dir="$HOME/RetroPie/splashscreens"
splashscreen_media_file="$splashscreens_dir/splash.mp4"

build() {
  local media_url=$(setting '.splashscreen')
  if [ -z "$media_url" ]; then
    return
  fi

  # Track a version number for the splashscreen in case the source changes
  local version_file="$splashscreens_dir/splash.version"
  local version=$(echo "$media_url" | md5sum | cut -d' ' -f 1)

  mkdir -pv "$splashscreens_dir"

  # Download media
  if [ ! -f "$version_file" ] || [ "$(cat "$version_file")" != "$version" ]; then
    download "$media_url" "$splashscreen_media_file" force=true
    echo "$version" > "$version_file"
  fi
}

configure() {
  if [ "$(setting 'has("splashscreen")')" == 'false' ]; then
    # There's no longer a splashscreen -- restore the original settings
    restore
    return
  fi

  backup_and_restore "$splashscreen_config"
  backup_and_restore "$splashscreen_list" as_sudo=true

  # Enable splashscreen
  echo "$splashscreen_media_file" | sudo tee "$splashscreen_list" >/dev/null

  # Ensure splashscreen doesn't get cut off based on video length
  local duration=$(ffprobe -i "$splashscreen_media_file" -show_entries format=duration -v quiet -of csv="p=0" | grep -oE "^[0-9]+")
  echo "Setting splashscreen duration to $duration seconds"
  dotenv -f "$splashscreen_config" set DURATION="\"$duration\""
}

restore() {
  restore_file "$splashscreen_list" as_sudo=true delete_src=true
  restore_file "$splashscreen_config" delete_src=true
}

remove() {
  rm -fv "$splashscreen_media_file" "$splashscreens_dir/splash.version"
}

setup "${@}"
