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

  # Multiple emulators
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame2003-plus _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame2010 _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame2015 _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame2016 _binary_

  # Compile lr-mame for a specific rev (or use mame2016)
  lr_mame_branch=$(jq -r ".emulators.\"lr-mame\".branch" "$SETTINGS_FILE")
  sed -i "s/mame.git master/mame.git $lr_mame_branch/g" ~/RetroPie-Setup/scriptmodules/libretrocores/lr-mame.sh
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame _source_
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
  # Configurations
  dat_file="$SYSTEM_TMP_DIR/roms.dat"
  dat_dir="$SYSTEM_TMP_DIR/dat"
  rom_xml_file="$SYSTEM_TMP_DIR/rom.xml"
  compatibility_file="$DATA_DIR/emulators/compatibility.tsv"
  categories_file="$DATA_DIR/catver/catver.ini"
  languages_file="$SYSTEM_TMP_DIR/languages.ini"
  names_file="$TMP_DIR/arcade/filtered.csv"

  # Download dat file
  wget -nc "$(jq -r ".support_files.dat" "$SETTINGS_FILE")" -O "$dat_file.7z"
  7z e -so "$dat_file.7z" "$(jq -r ".support_files.dat_file" "$SETTINGS_FILE")" > "$dat_file"

  # Split dat file
  if [ "$(ls -A "$dat_dir" | wc -l)" -eq 0 ]; then
    csplit -n 6 --prefix "$dat_dir/" "$dat_file" '/<machine/' '{*}'
    find "$dat_dir/" -type f | while read rom_dat_file; do
      rom_dat_filename=$(basename "$rom_dat_file")
      rom_name=$(grep -oP "machine name=\"\K[^\"]+" "$rom_dat_file")
      if [ -n "$rom_name" ]; then
        mv "$dat_dir/$rom_dat_filename" "$dat_dir/$rom_name"
      fi
    done
  fi

  # Download languages file
  wget -nc "$(jq -r ".support_files.languages" "$SETTINGS_FILE")" -O "$languages_file.zip"
  unzip -p "$languages_file.zip" "$(jq -r ".support_files.languages_file" "$SETTINGS_FILE")" > "$languages_file"
  crudini --get --format=lines "$languages_file" > "$languages_file.split"

  # Download categories file
  wget -nc "$(jq -r ".support_files.categories" "$SETTINGS_FILE")" -O "$categories_file.zip"
  unzip -p "$categories_file.zip" "$(jq -r ".support_files.categories_file" "$SETTINGS_FILE")" > "$categories_file"

  # Download compatibility file
  wget -nc "$(jq -r ".support_files.compatibility" "$SETTINGS_FILE")" -O "$compatibility_file"

  # Compatible / Runnable roms
  # See https://www.waste.org/~winkles/ROMLister/ for list of possible fitler ideas
  grep -v $'\t[x!]\t' "$compatibility_file" | cut -d $'\t' -f 1 | while read rom_name; do
    # Filter: Emulator
    emulator=$(grep "^$rom_name" "$compatibility_file" | cut -d $'\t' -f 3)
    if [ emulator = "lr-mame" ]; then
      emulator="lr-mame2016"
    fi

    # Filter: Category
    category=$(grep -oP "^$rom_name=\K(.*)$" "$categories_file" | head -n 1)

    # Filter: Language
    language=$(grep -oP "^\[\K.*(?= \] $rom_name)$" "$languages_file.split")

    LC_ALL=C grep -A 1000 -E "^ +<machine name=\"$rom_name\"" "$dat_file" | grep -oPz "(?s)<machine name=\"$rom_name\".*?machine" > "$rom_xml_file"
    # Filter: Clone
    "$rom_xml_file"
  keyword_conditions=$(jq -r '.roms.blocklists.keywords[]' "$SETTINGS_FILE" | sed -e 's/.*/contains(description\/text(), "\0")/g' | sed ':a; N; $!ba; s/\n/ or /g')
  sed -e "s/<description>\(.*\)<\/description>/<description>\L\1<\/description>/" "$DATA_DIR/$system/roms.dat" | xmlstarlet sel -T -t -v """/*/game[
    @cloneof or
    @romof or
    @sampleof or
    $keyword_conditions
  ]/@name""" >> "$names_blocklist_file"
  
    # Filter: Sample
    "$rom_xml_file"

    # Filter: Control
    "$rom_xml_file"

    # Filter: Flag
    "$rom_xml_file"

    # Filter: Name
    "$rom_xml_file"

    # Download
  done

  # # Build blocklist
  # # - Categories
  # categories=$(jq -r '.roms.blocklists.categories[]' "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  # grep -oP "^.+(?==.*($categories))" "$DATA_DIR/catver/catver.ini" > "$names_blocklist_file"

  # # - Keywords


  # # - Languages
  # crudini --del --output=- "$DATA_DIR/languages/languages.ini" "English" >> "$names_blocklist_file"

  # # Remove explicit ROMs from blocklist
  # jq -r ".roms.root[]" "$SETTINGS_FILE" | sed -e 's/\.zip//g' | sort > "$names_allowlist_file"

  # # Remove allowlist from blocklist
  # sort -o "$names_blocklist_file" "$names_blocklist_file"
  # comm -23 "$names_blocklist_file" "$names_allowlist_file" > "$names_mergelist_file"

  # # Filter from blocklist
  # comm -23 "$names_all_file" "$names_mergelist_file" > "$names_file"
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

  build_rom_list

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
          # TODO: Just check for the sample config?
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
