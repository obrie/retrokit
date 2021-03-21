#!/bin/bash

##############
# System: Arcade
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="arcade"
DATA_DIR="$APP_DIR/data/arcade"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"
SYSTEM_TMP_DIR="$TMP_DIR/arcade"

mkdir -p "$SYSTEM_TMP_DIR"

usage() {
  echo "usage: $0"
  exit 1
}

setup() {
  # Emulators
  crudini --set /opt/retropie/configs/arcade/emulators.cfg '' 'default' '"lr-fbneo"'

  # Input Lag
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/arcade/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
}

# Clean the configuration key used for defining ROM-specific emulator options
# 
# Implementation pulled from retropie
clean_emulator_config_key() {
  local name="$1"
  name="${name//\//_}"
  name="${name//[^a-zA-Z0-9_\-]/}"
  echo "$name"
}

# Filters a source's file list down to something more manageable
# 
# TODO: Support both allowlists and blocklists
# 
# Identify ROMs allowed:
#   comm -23 "$names_all_file" "$names_blocklist_file" | xargs -d '\n' -I{} grep -A 1 "name=\"{}\"" "$DATA_DIR/$source_name/roms.dat" | grep description
#   comm -23 "$names_all_file" "$names_blocklist_file" | xargs -d '\n' -I{} grep "^{}=.*/" "$DATA_DIR/catver/catver.ini" | grep -oE "=.*" | sort | uniq -c
build_rom_list() {
  # Arguments
  system="$1"

  # Configurations
  names_file="$TMP_DIR/arcade/$system.csv"
  names_all_file="$TMP_DIR/arcade/$system.all.csv"
  names_blocklist_file="$TMP_DIR/arcade/$system.blocklist.csv"
  names_allowlist_file="$TMP_DIR/arcade/$system.allowlist.csv"
  names_mergelist_file="$TMP_DIR/arcade/$system.mergelist.csv"

  # Create full name set
  xmlstarlet sel -T -t -v "/*/game/@name" "$DATA_DIR/$system/roms.dat" | sort > "$names_all_file"

  # Build blocklist
  # - Categories
  categories=$(jq -r '.roms.blocklists.categories[]' "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  grep -oP "^.+(?==.*($categories))" "$DATA_DIR/catver/catver.ini" > "$names_blocklist_file"

  # - Keywords
  keyword_conditions=$(jq -r '.roms.blocklists.keywords[]' "$SETTINGS_FILE" | sed -e 's/.*/contains(description\/text(), "\0")/g' | sed ':a; N; $!ba; s/\n/ or /g')
  sed -e "s/<description>\(.*\)<\/description>/<description>\L\1<\/description>/" "$DATA_DIR/$system/roms.dat" | xmlstarlet sel -T -t -v """/*/game[
    @cloneof or
    @runnable = \"no\" or
    not(driver/@status = \"good\") or
    driver/@isbios = \"yes\" or
    $keyword_conditions
  ]/@name""" >> "$names_blocklist_file"

  # - Languages
  crudini --del --output=- "$DATA_DIR/languages/languages.ini" "English" >> "$names_blocklist_file"

  # Remove explicit ROMs from blocklist
  jq -r ".roms.root[]" "$SETTINGS_FILE" | sed -e 's/\.zip//g' | sort > "$names_allowlist_file"

  # Remove allowlist from blocklist
  sort -o "$names_blocklist_file" "$names_blocklist_file"
  comm -23 "$names_blocklist_file" "$names_allowlist_file" > "$names_mergelist_file"

  # Filter from blocklist
  comm -23 "$names_all_file" "$names_mergelist_file" > "$names_file"
}

# This is strongly customized due to the nature of Arcade ROMs
# 
# MAYBE it could be generalized, but I'm not convinced it's worth the effort.
download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$SYSTEM"
  roms_all_dir="$roms_dir/-ALL-"
  emulators_config="/opt/retropie/configs/all/emulators.cfg"
  mkdir -p "$roms_all_dir"

  # Remove existing *links* from -ALL-
  find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Current assumes HTTP downloads
  jq -r '.roms.sources | keys[]' "$SETTINGS_FILE" | while read source_name; do
    # Source
    source_url=$(jq -r ".sources.\"$source_name\".url" "$APP_SETTINGS_FILE")
    source_emulator=$(jq -r ".sources.\"$source_name\".emulator" "$APP_SETTINGS_FILE")
    source_system=$(jq -r ".sources.\"$source_name\".system" "$APP_SETTINGS_FILE")

    # Source: ROMs
    roms_source_url="$source_url$(jq -r ".sources.\"$source_name\".roms" "$APP_SETTINGS_FILE")"
    roms_source_dir="$roms_dir/.$source_system"
    mkdir -p "$roms_source_dir"

    # Source: Samples
    samples_source_url="$source_url$(jq -r ".sources.\"$source_name\".samples" "$APP_SETTINGS_FILE")"
    samples_target_dir="/home/pi/RetroPie/BIOS/$source_system/samples"

    # Build list of ROMs to install
    build_rom_list "$source_system"
    rom_list_file="$TMP_DIR/arcade/$source_system.csv"

    # Install ROMs
    cat "$rom_list_file" | while read rom_name; do
      rom_source_file="$roms_source_dir/$rom_name.zip"
      rom_target_file="$roms_all_dir/$rom_name.zip"

      if [ ! -f "$rom_target_file" ]; then
        rom_emulator_key=$(clean_emulator_config_key "arcade_${rom_name}")

        # Download ROM assets
        if [ ! -f "$rom_source_file" ]; then
          # Install ROM
          wget "$roms_source_url$rom_name.zip" -O "$rom_source_file"

          # Install disk (if applicable)
          xmlstarlet sel -T -t -v "/*/game[@name = \"$rom_name\"]/disk/@name" "$DATA_DIR/$source_system/roms.dat" | xargs -d '\n' -I{} echo '{}' | while read disk_name; do
            mkdir -p "$roms_source_dir/$rom_name"
            wget "$roms_source_url$rom_name/$disk_name" -O "$roms_source_dir/$rom_name/$disk_name"
          done

          # Install sample (if applicable)
          if [ "$(grep "$rom_name.zip" "$DATA_DIR/$source_system/samples.csv")" ]; then
            wget "$samples_source_url$rom_name.zip" -O "$samples_target_dir/$rom_name.zip"
          fi
        else
          echo "Already downloaded: $rom_source_file"
        fi

        # Link to -ALL- (including drive)
        ln -fs "$rom_source_file" "$rom_target_file"
        if [ -d "$roms_source_dir/$rom_name" ]; then
          ln -fs "$roms_source_dir/$rom_name" "$roms_all_dir/$rom_name"
        fi

        # Write emulator configuration
        crudini --set "$emulators_config" "" "$rom_emulator_key" "\"$source_emulator\""
      fi
    done
  done

  # Remove existing *links* from root
  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Add to root
  jq -r ".roms.root[]" "$SETTINGS_FILE" | while read rom; do
    ln -fs "$roms_all_dir/$rom" "$roms_dir/$rom"

    # Create link for drive as well (if applicable)
    rom_name=$(basename -s .zip "$rom")
    if [ -d "$roms_all_dir/$rom_name" ]; then
      ln -fs "$roms_all_dir/$rom_name" "$roms_dir/$rom_name"
    fi
  done

  scrape_system "$SYSTEM" "screenscraper"
  scrape_system "$SYSTEM" "arcadedb"
  theme_system "MAME"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
