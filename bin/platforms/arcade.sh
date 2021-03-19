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

filter_source() {
  source_name="$1"

  names_all_file="$TMP_DIR/arcade/$source_name.all.csv"
  names_blocklist_file="$TMP_DIR/arcade/$source_name.blocklist.csv"
  names_allowlist_file="$TMP_DIR/arcade/$source_name.allowlist.csv"
  names_filtered_file="$TMP_DIR/arcade/$source_name.filtered.csv"
  names_file="$TMP_DIR/arcade/$source_name.csv"

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
  comm -23 "$names_all_file" "$names_blocklist_file" > "$names_file"

  # # Build allowlist
  # # - Languages
  # truncate -s0 "$names_allowlist_file"
  # jq -r '.roms.allowlists.languages[]' "$SETTINGS_FILE" | xargs -d'\n' -I{} crudini --get "$DATA_DIR/languages/languages.ini" "{}" >> "$names_allowlist_file"
  # sort -o "$names_allowlist_file" "$names_allowlist_file"

  # # Filter from allowlist
  # comm -12 "$names_filtered_file" "$names_allowlist_file" > "$names_file"

  # cat "$names_file" | xargs -d '\n' -I{} grep -A 1 "name=\"{}\"" "$DATA_DIR/$source_name/roms.dat" | grep description
  # cat "$names_file" | xargs -d '\n' -I{} grep "^{}=.*/" "$DATA_DIR/catver/catver.ini" # | grep -oE "=.*" | sort | uniq -c | sort
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

  # Move samples / cheaps for FBNeo
  cp samples/* /home/pi/RetroPie/BIOS/fbneo/samples/
  cp cheats/* /home/pi/RetroPie/fbneo/cheats/

  # Move samples / cheats for MAME
  scp samples/* pi@***REMOVED***:/home/pi/RetroPie/BIOS/mame2003-plus/samples/
  scp cheats/* pi@***REMOVED***:/home/pi/RetroPie/BIOS/mame2003-plus/cheats/

  # Move roms to hidden folders
  mkdir .fbneo .mame
  mv fbneo/roms/* .fbneo
  mv mame/roms/* .mame

  # Create symlinks in -ALL-
  ln -s .fbneo/* -ALL-/*
  ln -s .mame/* -ALL-/*

  # Filter symlinks
  mkdir -p "$TMP_DIR/arcade/"

  # # FBNeo filters
  # filter_source "fbneo"
  # filter_source "mame2003plus"
  # names_all_file="$TMP_DIR/arcade/names.all.csv"
  # names_ignored_file="$TMP_DIR/arcade/names.ignored.csv"
  # names_filtered_file="$TMP_DIR/arcade/names.filtered.csv"

  # xmlstarlet sel -T -t -v "/datafile/game/@name" "$DATA_DIR/fbneo/roms.dat" > "$names_all_file"

  # categories=$(jq -r '.roms.blocklists.categories[]' "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  # grep -oP "^.+(?==.*($categories))" "$DATA_DIR/catver/catver.ini" > "$names_ignored_file"

  # keyword_conditions=$(jq -r '.roms.blocklists.keywords[]' "$SETTINGS_FILE" | sed -e 's/.*/contains(description\/text(), "\0")/g' | sed ':a; N; $!ba; s/\n/ or /g')
  # sed -e "s/<description>\(.*\)<\/description>/<description>\L\1<\/description>/" "$DATA_DIR/fbneo/roms.dat" | xmlstarlet sel -T -t -v """/datafile/game[
  #   @cloneof or
  #   not(driver/@status = \"good\") or
  #   $keyword_conditions
  # ]/@name""" >> "$names_ignored_file"

  # grep -Fxv -f "$names_ignored_file" "$names_all_file" > "$names_filtered_file"

  cat "$names_filtered_file" | xargs -I{} grep "name=\"{}\"" ../../data/fbneo/roms.dat
  cat "$names_filtered_file" | xargs -I{} grep -oP "^({})=\K.*/.*" data/catver/catver.ini | sort | uniq -c

  organize_platform "$PLATFORM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
