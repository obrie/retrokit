#!/bin/bash

##############
# Platform: Arcade
##############

set -ex

DIR=$( dirname "$0" )
. $DIR/common.sh

PLATFORM="arcade"
DATA_DIR="$APP_DIR/data/arcade"
CONFIG_DIR="$APP_DIR/config/platforms/$PLATFORM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"
PLATFORM_TMP_DIR="$TMP_DIR/arcade"

mkdir -p "$PLATFORM_TMP_DIR"

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

function clean_name() {
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
filter_source() {
  # Arguments
  source_name="$1"

  # Configurations
  names_all_file="$TMP_DIR/arcade/$source_name.all.csv"
  names_blocklist_file="$TMP_DIR/arcade/$source_name.blocklist.csv"
  names_allowlist_file="$TMP_DIR/arcade/$source_name.allowlist.csv"
  names_filtered_file="$TMP_DIR/arcade/$source_name.filtered.csv"

  # Create full name set
  xmlstarlet sel -T -t -v "/*/game/@name" "$DATA_DIR/$source_name/roms.dat" | sort > "$names_all_file"

  # Build blocklist
  # - Categories
  categories=$(jq -r '.roms.blocklists.categories[]' "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  grep -oP "^.+(?==.*($categories))" "$DATA_DIR/catver/catver.ini" > "$names_blocklist_file"

  # - Keywords
  keyword_conditions=$(jq -r '.roms.blocklists.keywords[]' "$SETTINGS_FILE" | sed -e 's/.*/contains(description\/text(), "\0")/g' | sed ':a; N; $!ba; s/\n/ or /g')
  sed -e "s/<description>\(.*\)<\/description>/<description>\L\1<\/description>/" "$DATA_DIR/$source_name/roms.dat" | xmlstarlet sel -T -t -v """/*/game[
    @cloneof or
    (@romof and not(@romof = \"playch10\")) or
    not(driver/@status = \"good\") or
    driver/@isbios = \"yes\" or
    $keyword_conditions
  ]/@name""" >> "$names_blocklist_file"

  # - Languages
  crudini --del --output=- "$DATA_DIR/languages/languages.ini" "English" >> "$names_blocklist_file"

  # Filter from blocklist
  sort -o "$names_blocklist_file" "$names_blocklist_file"
  comm -23 "$names_all_file" "$names_blocklist_file"
}

download() {
  # Target
  roms_dir="/home/pi/RetroPie/roms/$PLATFORM"
  roms_all_dir="$roms_dir/-ALL-"
  mkdir -p "$roms_all_dir"

  if [ "$(ls -A $roms_all_dir | wc -l)" -eq 0 ]; then
    # Download according to settings file
    download_platform "$PLATFORM"
  else
    echo "$roms_all_dir is not empty: skipping download"
  fi

  # Handle FBNeo
  unzip 
  # Move samples / cheaps for FBNeo
  cp samples/* /home/pi/RetroPie/BIOS/fbneo/samples/

  # Move samples / cheats for MAME
  scp samples/* pi@***REMOVED***:/home/pi/RetroPie/BIOS/mame2003-plus/samples/

  # Move roms to hidden folders
  mkdir .fbneo .mame
  mv fbneo/roms/* .fbneo
  mv mame/roms/* .mame

  # Create symlinks in -ALL-
  ln -s .fbneo/* -ALL-/*
  ln -s .mame/* -ALL-/*

  # Filter symlinks
  mkdir -p "$TMP_DIR/arcade/"

  filter_source "fbneo" > "$PLATFORM_TMP_DIR/$source_name.csv"
  filter_source "mame2003plus" > "$PLATFORM_TMP_DIR/$source_name.csv"

  # First deal with FBNeo
  comm -2 "$PLATFORM_TMP_DIR/fbneo.csv" "$PLATFORM_TMP_DIR/mame2003plus.csv" | tr -d '\t'

  # For each file create roms/arcade/<rom name>.cfg with:
  # clean_name "lr-mame2003plus_$rom_name"

  # Then deal with Mame2003 PLUS
  comm -13 "$PLATFORM_TMP_DIR/fbneo.csv" "$PLATFORM_TMP_DIR/mame2003plus.csv"

  organize_platform "$PLATFORM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
