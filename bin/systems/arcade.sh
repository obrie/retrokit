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
  crudini --set /opt/retropie/configs/$SYSTEM/emulators.cfg '' 'default' "\"$(jq -r ".emulators[0]" "$SETTINGS_FILE")\""

  # Input Lag
  if [ $(jq -r ".emulators[0]" "$SETTINGS_FILE") == "true" ]; then
    crudini --set /opt/retropie/configs/$SYSTEM/retroarch.cfg '' 'run_ahead_enabled' '"true"'
    crudini --set /opt/retropie/configs/$SYSTEM/retroarch.cfg '' 'run_ahead_frames' '"1"'
    crudini --set /opt/retropie/configs/$SYSTEM/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
  fi

  # Install binary emulators
  jq -r ".emulators[]" "$SETTINGS_FILE" | while read emulator; do
    if [ "$emulator" != "lr-mame" ]; then
      sudo ~/RetroPie-Setup/retropie_packages.sh $emulator _binary_
    fi
  done

  # Compile lr-mame for a specific rev (or use mame2016)
  if [ $(jq -r '.emulators | index("lr-fbneo")' "$SETTINGS_FILE") != 'null' ]; then
    lr_mame_branch=$(jq -r ".emulators.\"lr-mame\".branch" "$SETTINGS_FILE")
    sed -i "s/mame.git master/mame.git $lr_mame_branch/g" ~/RetroPie-Setup/scriptmodules/libretrocores/lr-mame.sh
    sudo ~/RetroPie-Setup/retropie_packages.sh lr-mame _source_
  fi
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

# Installs a rom for a specific emulator
install_rom() {
  # Arguments
  rom_name="$1"
  emulator="$2"
  source_name=$(jq -r ".sources | to_entries | map(select(.value.emulator == \"$emulator\"))[] | .key" "$APP_SETTINGS_FILE" | head -n 1)

  # Configuration
  dat_dir="$SYSTEM_TMP_DIR/dat"

  # Target
  emulators_config="/opt/retropie/configs/all/emulators.cfg"
  mkdir -p "$roms_all_dir"

  # Source
  source_url=$(jq -r ".sources.\"$source_name\".url" "$APP_SETTINGS_FILE")
  source_core=$(jq -r ".sources.\"$source_name\".core" "$APP_SETTINGS_FILE")

  # Source: ROMs
  roms_source_url="$source_url$(jq -r ".sources.\"$source_name\".roms" "$APP_SETTINGS_FILE")"
  roms_source_dir="$roms_dir/.$source_core"
  mkdir -p "$roms_source_dir"

  # Source: Samples
  samples_source_url="$source_url$(jq -r ".sources.\"$source_name\".samples" "$APP_SETTINGS_FILE")"
  samples_target_dir="/home/pi/RetroPie/BIOS/$source_core/samples"
  mkdir -p "$samples_target_dir"

  rom_source_file="$roms_source_dir/$rom_name.zip"
  rom_target_file="$roms_all_dir/$rom_name.zip"

  if [ ! -f "$rom_target_file" ]; then
    rom_emulator_key=$(clean_emulator_config_key "arcade_${rom_name}")

    # Download ROM assets
    if [ ! -f "$rom_source_file" ]; then
      wget "$roms_source_url$rom_name.zip" -O "$rom_source_file"
    else
      echo "Already downloaded: $rom_source_file"
    fi

    # Install disk (if applicable)
    xmlstarlet sel -T -t -v "/*/disk/@name" "$dat_dir/$rom_name" | xargs -d '\n' -I{} echo '{}' | while read disk_name; do
      mkdir -p "$roms_source_dir/$rom_name"
      disk_file="$roms_source_dir/$rom_name/$disk_name"
      if [ ! -f "$disk_file" ]; then
        wget "$roms_source_url$rom_name/$disk_name" -O "$disk_file"
      else
        echo "Already downloaded: $disk_file"
      fi
    done

    # Install sample (if applicable)
    sample_name=$(xmlstarlet sel -T -t -v "/*/@sampleof" "$dat_dir/$rom_name" || true)
    if [ -n "$sample_name" ]; then
      sample_file="$samples_target_dir/$sample_name.zip"
      if [ ! -f "$sample_file" ]; then
        wget "$samples_source_url$sample_name.zip" -O "$sample_file"
      else
        echo "Already downloaded: $sample_file"
      fi
    fi

    # Link to -ALL- (including drive)
    ln -fs "$rom_source_file" "$rom_target_file"
    if [ -d "$roms_source_dir/$rom_name" ]; then
      ln -fs "$roms_source_dir/$rom_name" "$roms_all_dir/$rom_name"
    fi

    # Write emulator configuration
    crudini --set "$emulators_config" "" "$rom_emulator_key" "\"$emulator\""
  fi
}

# This is strongly customized due to the nature of Arcade ROMs
# 
# MAYBE it could be generalized, but I'm not convinced it's worth the effort.
download() {
  # Configurations
  roms_dir="/home/pi/RetroPie/roms/$SYSTEM"
  roms_all_dir="$roms_dir/-ALL-"
  dat_dir="$SYSTEM_TMP_DIR/dat"
  rom_xml_file="$SYSTEM_TMP_DIR/rom.xml"
  compatibility_file="$SYSTEM_TMP_DIR/compatibility.tsv"
  categories_file="$SYSTEM_TMP_DIR/catlist.ini"
  languages_file="$SYSTEM_TMP_DIR/languages.ini"
  names_file="$SYSTEM_TMP_DIR/filtered.csv"

  # Download dat file
  if [ ! -f "$dat_dir.all" ]; then
    wget -nc "$(jq -r ".support_files.dat" "$SETTINGS_FILE")" -O "$dat_dir.7z" || true
    7z e -so "$dat_dir.7z" "$(jq -r ".support_files.dat_file" "$SETTINGS_FILE")" > "$dat_dir.all"
  fi

  # Split dat file
  if [ "$(ls -U "$dat_dir" | wc -l)" -eq 0 ]; then
    csplit -n 6 --prefix "$dat_dir/" "$dat_dir.all" '/<machine/' '{*}'
    find "$dat_dir/" -type f | while read rom_dat_file; do
      rom_dat_filename=$(basename "$rom_dat_file")
      rom_name=$(grep -oP "machine name=\"\K[^\"]+" "$rom_dat_file")
      if [ -n "$rom_name" ]; then
        mv "$dat_dir/$rom_dat_filename" "$dat_dir/$rom_name"
      fi
    done
  fi

  # Download languages file
  if [ ! -f "$languages_file.split" ]; then
    wget -nc "$(jq -r ".support_files.languages" "$SETTINGS_FILE")" -O "$languages_file.zip" || true
    unzip -p "$languages_file.zip" "$(jq -r ".support_files.languages_file" "$SETTINGS_FILE")" > "$languages_file"
    crudini --get --format=lines "$languages_file" > "$languages_file.split"
  fi

  # Download categories file
  if [ ! -f "$categories_file" ]; then
    wget -nc "$(jq -r ".support_files.categories" "$SETTINGS_FILE")" -O "$categories_file.zip" || true
    unzip -p "$categories_file.zip" "$(jq -r ".support_files.categories_file" "$SETTINGS_FILE")" > "$categories_file"
    crudini --get --format=lines "$categories_file" > "$categories_file.split"
  fi

  # Download compatibility file
  if [ ! -f "$compatibility_file" ]; then
    wget -nc "$(jq -r ".support_files.compatibility" "$SETTINGS_FILE")" -O "$compatibility_file"
  fi

  # Reset everything
  truncate -s0 "$names_file"
  find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Compatible / Runnable roms
  # See https://www.waste.org/~winkles/ROMLister/ for list of possible fitler ideas
  grep -v $'\t[x!]\t' "$compatibility_file" | cut -d $'\t' -f 1 | while read rom_name; do
    emulator=$(grep "^$rom_name"$'\t' "$compatibility_file" | cut -d $'\t' -f 3)
    if [ "$emulator" == "lr-mame" ]; then
      emulator="lr-mame2016"
    fi

    # Always allow favorites regardless of filter
    if [ $(jq -r ".roms.favorites | index(\"$rom_name\")" "$SETTINGS_FILE") != 'null' ]; then
      install_rom "$rom_name" "$emulator"
      continue
    fi

    # Attributes
    rom_dat_file="$dat_dir/$rom_name"
    if [ ! -f "$rom_dat_file" ]; then
      continue
    fi

    # Clone
    is_clone=$(xmlstarlet sel -T -t -v "*/@cloneof" "$rom_dat_file" || true)
    if [ "$(jq -r ".roms.blocklists.clones" "$SETTINGS_FILE")" == "true" ] && [ -n "$is_clone" ]; then
      continue
    fi
    if [ "$(jq -r ".roms.allowlists.clones" "$SETTINGS_FILE")" == "false" ] && [ -n "$is_clone" ]; then
      continue
    fi

    # Language
    language=$(grep -oP "^\[ \K.*(?= \] $rom_name$)" "$languages_file.split" || true)
    if [ "$(jq -r ".roms.blocklists.languages | index(\"$language\")" "$SETTINGS_FILE")" != 'null' ]; then
      continue
    fi
    if [ "$(jq -r "(.roms.allowlists | has(\"languages\")) and (.roms.allowlists.languages | index(\"$language\") == null)" "$SETTINGS_FILE")" == 'true' ]; then
      continue
    fi

    # Category
    category=$(grep -oP "^\[ Arcade: \K.*(?= \] $rom_name$)" "$categories_file.split" || true)
    if [ "$(jq -r ".roms.blocklists.categories | index(\"$category\")" "$SETTINGS_FILE")" != 'null' ]; then
      continue
    fi
    if [ "$(jq -r "(.roms.allowlists | has(\"categories\")) and (.roms.allowlists.categories | index(\"$category\") == null)" "$SETTINGS_FILE")" == 'true' ]; then
      continue
    fi

    # Keywords
    description=$(xmlstarlet sel -T -t -v "*/description/text()" "$rom_dat_file")
    keyword_conditions=$(jq -r ".roms.blocklists.keywords[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$keyword_conditions" ] && [ $(echo "$description" | grep -oE "$keyword_conditions") ]; then
      continue
    fi
    keyword_conditions=$(jq -r ".roms.allowlists.keywords[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$keyword_conditions" ] && [ ! $(echo "$description" | grep -oE "$keyword_conditions") ]; then
      continue
    fi

    # Flags
    all_flags=$(echo "$description" | grep -oP "\( \K[^\)]+" || true)
    flags=$(echo "$all_flags" | tail -n +2)
    flag_conditions=$(jq -r ".roms.blocklists.flags[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$flag_conditions" ] && [ $(echo "$flags" | grep -E "$flag_conditions") ]; then
      continue
    fi
    flag_conditions=$(jq -r ".roms.allowlists.flags[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$flag_conditions" ] && [ ! $(echo "$flags" | grep -E "$flag_conditions") ]; then
      continue
    fi

    # Controls
    controls=$(xmlstarlet sel -T -t -v "*/input/control/@type" "$rom_dat_file" | sort | uniq || true)
    control_conditions=$(jq -r ".roms.blocklists.controls[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$control_conditions" ] && [ ! $(echo "$controls" | grep -vE "$control_conditions") ]; then
      continue
    fi
    control_conditions=$(jq -r ".roms.allowlists.controls[]?" "$SETTINGS_FILE" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
    if [ -n "$control_conditions" ] && [ ! $(echo "$controls" | grep -E "$control_conditions") ]; then
      continue
    fi

    # Name
    if [ "$(jq -r ".roms.blocklists.names | index(\"$name\")" "$SETTINGS_FILE")" != 'null' ]; then
      continue
    fi
    if [ "$(jq -r "(.roms.allowlists | has(\"names\")) and (.roms.allowlists.names | index(\"$name\") == null)" "$SETTINGS_FILE")" == 'true' ]; then
      continue
    fi

    # Install
    install_rom "$rom_name" "$emulator"
  done

  # Add to root
  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;
  jq -r ".roms.favorites[]" "$SETTINGS_FILE" | while read rom; do
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
