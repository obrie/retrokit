#!/bin/bash

##############
# Platform: NES
##############

set -ex

APP_DIR=$(cd "$( dirname "$0" )/../.." && pwd)
CONFIG_DIR="$APP_DIR/platforms/config/c64"

setup() {
  # Input Lag
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/nes/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
}

download() {
  roms_dir="/home/pi/RetroPie/roms/c64"
  roms_all_dir="$roms_dir/-ALL-"
  roms_duplicates_dir="$roms_dir/.duplicates"
  roms_blocked_dir="$roms_dir/.blocked"
  torrent_url=$(jq -r '.sources.nointro.url' "$APP_SETTINGS_FILE")
  torrent_file="$TMP_DIR/c64.torrent"
  torrent_filter="$TMP_DIR/c64.filter"
  rom_source_dir="/var/lib/transmission-daemon/downloads/$(jq -r '.sources.nointro.root_dir' "$APP_SETTINGS_FILE")"
  mkdir -p "$roms_duplicates_dir" "$roms_blocked_dir"

  # Download torrent
  wget -nc "$torrent_url" -O "$torrent_file" || true
  printf "Nintendo - Nintendo Entertainment System (20210317-123123) [headered] (MIA 1).zip\n" > "$torrent_filter"
  "$APP_DIR/bin/tools/torrent.sh" "$torrent_file" "$torrent_filter"

  # Extract files
  unzip -o "$rom_source_dir/*.zip" -d "$roms_all_dir/"
  sudo rm "$rom_source_dir/*.zip"

  # Clean up
  ls $roms_all_dir | grep -oE "^[^(]+" | uniq | while read -r game; do
    find "$roms_all_dir" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d'\n' -I{} mv "{}" "$roms_duplicates_dir/"
  done

  # Block games
  keywords=$(jq -r '.roms.keyword_blacklist | join("|")' "$APP_SETTINGS_FILE")
  find "$roms_all_dir/" -regextype posix-extended -regex ".*($keywords).*" -exec mv "{}" "$roms_blocked_dir/" \;

  # Add defaults
  jq -r ".roms.default[]" "$PLATFORM_SETTINGS_FILE" | xargs -d'\n' -I{} ln -fs "$roms_all_dir/{}" "$roms_dir/{}"
}
