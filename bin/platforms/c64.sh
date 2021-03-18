#!/bin/bash

##############
# Platform: Commodore 64
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

CONFIG_DIR="$APP_DIR/config/platforms/c64"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

setup() {
  # Install packages
  if [ ! -d "/opt/retropie/libretrocores/lr-vice/" ]; then
    sudo ~/RetroPie-Setup/retropie_packages.sh lr-vice _binary_
  fi

  # Enable fast startup
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

  # Default Start command
  crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_mapper_start' '"RETROK_F1"'

  # Set up configurations
  mkdir -p /opt/retropie/configs/all/retroarch/config/VICE\ x64/

  # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
  retropie_configs_dir="/opt/retropie/configs/all"
  find "$CONFIG_DIR/retroarch_opts" -iname "*.opt" | while read override_file; do
    opt_name=$(basename "$override_file")
    opt_file="$retropie_configs_dir/retroarch/config/VICE x64/$opt_name"
    touch "$opt_file"
    crudini --merge --output="$opt_file" "$retropie_configs_dir/retroarch-core-options.cfg" < "$override_file"
  done
}

after_download() {
  # Clean up
  # ls $roms_all_dir | grep -oE "^[^(]+" | uniq | while read -r game; do
  #   find "$roms_all_dir" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d'\n' -I{} mv "{}" "$roms_duplicates_dir/"
  # done
}

download() {
  download_platform "c64"
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
  printf "Commodore - 64 (20210216-232616).zip\nCommodore - 64 (Tapes) (20210216-231940).zip\n" > "$torrent_filter"
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
  jq -r ".roms.default[]" "$SETTINGS_FILE" | xargs -d'\n' -I{} ln -fs "$roms_all_dir/{}" "$roms_dir/{}"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
