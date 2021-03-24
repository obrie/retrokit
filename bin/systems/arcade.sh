#!/bin/bash

##############
# System: Arcade
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System info
system="arcade"

# Directories
config_dir="$app_dir/config/systems/$system"
settings_file="$config_dir/settings.json"
system_tmp_dir="$tmp_dir/arcade"
mkdir -p "$system_tmp_dir"

# Support files
roms_dir="$HOME/RetroPie/roms/$system"
roms_all_dir="$roms_dir/-ALL-"
dat_dir="$system_tmp_dir/dat"
dat_file="$dat_dir.all"
rom_xml_file="$system_tmp_dir/rom.xml"
compatibility_file="$system_tmp_dir/compatibility.tsv"
categories_file="$system_tmp_dir/catlist.ini"
categories_flat_file="$categories_file.flat"
languages_file="$system_tmp_dir/languages.ini"
languages_flat_file="$languages_file.flat"

# Source data
declare -A sources
declare -A emulators

usage() {
  echo "usage: $0"
  exit 1
}

setup() {
  # Input Lag
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'

  # Install emulators
  while IFS="," read -r emulator build branch is_default; do
    if [ "${build:-binary}" == "binary" ]; then
      # Binary install
      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _binary_
    else
      # Source install
      if [ -n "$branch" ]; then
        # Set to correct branch
        setup_file="$HOME/RetroPie-Setup/scriptmodules/libretrocores/$emulator.sh"
        if [ ! -f "$setup_file.orig" ]; then
          cp "$setup_file" "$setup_file.orig"
        fi

        sed -i "s/.git master/.git $branch/g" "$setup_file"
      fi

      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _source_
    fi

    # Set default
    if [ "$is_default" == "true" ]; then
      crudini --set "/opt/retropie/configs/$system/emulators.cfg" '' 'default' "\"$emulator\""
    fi
  done < <(jq -r ".emulators | to_entries[] | [.key, .value.build, .value.branch, .value.default] | @tsv" "$app_settings_file")
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

load_sources() {
  # Read configured sources
  while read -r source_name; do
    # Load the source
    while IFS="$SEP" read -r key value; do
      SOURCES["$source_name/$key"]="$value"
    done < <(jq -r ".sources.\"$source_name\" | to_entries[] | [.key, .value] | @tsv" "$app_settings_file")

    # Load emulator info
    EMULATORS["${SOURCES["$source_name/emulator"]}/source_name"]="$source_name"
  done < <(jq -r '.roms.sources | keys[]' "$settings_file")
}

source_asset_url() {
  source_name="$1"
  asset_name="$2"
  source_url=${SOURCES["$source_name/url"]}

  asset_path=${SOURCES["$source_name/$asset_name"]}
  if [ $(grep -E "^http" "$asset_path") ]; then
    echo "$asset_path"
  else
    echo "$source_url$asset_path"
  fi
}

# Installs a rom for a specific emulator
install_rom() {
  # Arguments
  rom_name="$1"
  emulator="$2"

  # Determine which source to use based on the configured emulator
  source_name=${EMULATORS["$emulator/source_name"]}

  # Configuration
  dat_dir="$system_tmp_dir/dat"
  dat_file="$dat_dir/$rom_name"

  # Target
  emulators_config="/opt/retropie/configs/all/emulators.cfg"
  mkdir -p "$roms_all_dir"

  # Source
  source_core=${SOURCES["$source_name/core"]}

  # Source: ROMs
  roms_source_url=$(source_asset_url "$source_name" "roms")
  roms_source_dir="$roms_dir/.$source_core"
  rom_source_file="$roms_source_dir/$rom_name.zip"
  rom_target_file="$roms_all_dir/$rom_name.zip"
  mkdir -p "$roms_source_dir"

  # Source: Samples
  samples_source_url=$(source_asset_url "$source_name" "samples")
  samples_target_dir="$HOME/RetroPie/BIOS/$source_core/samples"
  mkdir -p "$samples_target_dir"

  # Source: Disks
  disks_source_url=$(source_asset_url "$source_name" "disks")
  disk_source_dir="$roms_source_dir/$rom_name"
  disk_target_dir="$roms_all_dir/$rom_name"

  # Only write if we haven't already written a ROM to the target destination
  if [ ! -f "$rom_target_file" ]; then
    rom_emulator_key=$(clean_emulator_config_key "arcade_${rom_name}")

    # Install ROM asset
    if [ ! -f "$rom_source_file" ]; then
      wget "$roms_source_url$rom_name.zip" -O "$rom_source_file" || return 1
    else
      echo "Already downloaded: $rom_source_file"
    fi

    # Install disk assets (if applicable)
    while read disk_name; do
      mkdir -p "$disk_source_dir"
      disk_file="$disk_source_dir/$disk_name"
      if [ ! -f "$disk_file" ]; then
        wget "$disks_source_url$rom_name/$disk_name" -O "$disk_file" || return 1
      else
        echo "Already downloaded: $disk_file"
      fi
    done < <(xmlstarlet sel -T -t -v "/*/disk/@name" "$dat_file")

    # Install sample asset (if applicable)
    sample_name=$(xmlstarlet sel -T -t -v "/*/@sampleof" "$dat_dir/$rom_name" || true)
    if [ -n "$sample_name" ]; then
      sample_file="$samples_target_dir/$sample_name.zip"
      if [ ! -f "$sample_file" ]; then
        wget "$samples_source_url$sample_name.zip" -O "$sample_file" || return 1
      else
        echo "Already downloaded: $sample_file"
      fi
    fi

    # Link to -ALL- (including disk)
    ln -fs "$rom_source_file" "$rom_target_file"
    if [ -d "$roms_source_dir/$rom_name" ]; then
      ln -fs "$roms_source_dir/$rom_name" "$roms_all_dir/$rom_name"
    fi

    # Write emulator configuration
    crudini --set "$emulators_config" "" "$rom_emulator_key" "\"$emulator\""
  fi
}

organize_system() {
  roms_dir="$HOME/RetroPie/roms/$system"
  roms_all_dir="$roms_dir/-ALL-"

  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;
  while read rom; do
    ln -fs "$roms_all_dir/$rom" "$roms_dir/$rom"

    # Create link for drive as well (if applicable)
    rom_name=$(basename -s .zip "$rom")
    if [ -d "$roms_all_dir/$rom_name" ]; then
      ln -fs "$roms_all_dir/$rom_name" "$roms_dir/$rom_name"
    fi
  done < <(jq -r ".roms.favorites[]" "$settings_file")
}

download_support_files() {
  declare -A support_files
  while IFS="$SEP" read -r key value; do
    support_files["$key"]="$value"
  done < <(jq -r ".support_files | to_entries[] | [.key, .value] | @tsv" "$app_settings_file")

  # Download dat file
  if [ ! -f "$dat_file" ]; then
    wget -nc "${support_files['dat_url']}" -O "$dat_dir.7z" || true
    7z e -so "$dat_dir.7z" "${support_files['dat_file']}" > "$dat_file"
  fi

  # Split dat file
  if [ "$(ls -U "$dat_dir" | wc -l)" -eq 0 ]; then
    csplit -n 6 --prefix "$dat_dir/" "$dat_file" '/<machine/' '{*}'
    while read rom_dat_file; do
      rom_dat_filename=$(basename "$rom_dat_file")
      rom_name=$(grep -oP "machine name=\"\K[^\"]+" "$rom_dat_file")
      if [ -n "$rom_name" ]; then
        mv "$dat_dir/$rom_dat_filename" "$dat_dir/$rom_name"
      fi
    done < <(find "$dat_dir/" -type f )
  fi

  # Download languages file
  if [ ! -f "$languages_flat_file" ]; then
    wget -nc "${support_files['languages_url']}" -O "$languages_file.zip" || true
    unzip -p "$languages_file.zip" "${support_files['languages_file']}" > "$languages_file"
    crudini --get --format=lines "$languages_file" > "$languages_flat_file"
  fi

  # Download categories file
  if [ ! -f "$categories_flat_file" ]; then
    wget -nc "${support_files['categories_url']}" -O "$categories_file.zip" || true
    unzip -p "$categories_file.zip" "${support_files['categories_file']}" > "$categories_file"
    crudini --get --format=lines "$categories_file" > "$categories_flat_file"
  fi

  # Download compatibility file
  if [ ! -f "$compatibility_file" ]; then
    wget -nc "${support_files['compatibility_url']}" -O "$compatibility_file"
  fi
}

reset_roms() {
  find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;
}

# This is strongly customized due to the nature of Arcade ROMs
# 
# MAYBE it could be generalized, but I'm not convinced it's worth the effort.
download() {
  load_sources
  download_support_files
  reset_roms
  find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Overrides
  favorites=$(jq -r ".roms.favorites[]" "$settings_file" | tr "\n" "$SEP")

  # Blocklists
  declare -A blocklists
  blocklists_clones=$(jq -r ".roms.blocklists.clones" "$settings_file")
  blocklists_languages=$(jq -r ".roms.blocklists.languages[]" "$settings_file" | tr "\n" "$SEP")
  blocklists_categories=$(jq -r ".roms.blocklists.categories[]" "$settings_file" | tr "\n" "$SEP")
  blocklists_keywords=$(jq -r ".roms.blocklists.keywords[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  blocklists_flags=$(jq -r ".roms.blocklists.flags[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  blocklists_controls=$(jq -r ".roms.blocklists.controls[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  blocklists_names=$(jq -r ".roms.blocklists.names[]" "$settings_file" | tr "\n" "$SEP")

  # Allowlists
  allowlists_clones=$(jq -r ".roms.allowlists.clones" "$settings_file")
  allowlists_languages=$(jq -r ".roms.allowlists.languages[]" "$settings_file" | tr "\n" "$SEP")
  allowlists_categories=$(jq -r ".roms.allowlists.categories[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  allowlists_keywords=$(jq -r ".roms.allowlists.keywords[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  allowlists_flags=$(jq -r ".roms.allowlists.flags[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  allowlists_controls=$(jq -r ".roms.allowlists.controls[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  allowlists_names=$(jq -r ".roms.allowlists.names[]" "$settings_file" | tr "\n" "$SEP")

  # Compatible / Runnable roms
  # See https://www.waste.org/~winkles/ROMLister/ for list of possible fitler ideas
  while read rom_name; do
    emulator=$(grep "^$rom_name$SEP" "$compatibility_file" | cut -d "$SEP" -f 3)
    if [ "$emulator" == "lr-mame" ]; then
      emulator="lr-mame2016"
    fi

    # [Exact match] Always allow favorites regardless of filter
    if [ "$SEP$favorites$SEP" == *"$SEP$rom_name$SEP"* ]; then
      install_rom "$rom_name" "$emulator"
      continue
    fi

    # Attributes
    rom_dat_file="$dat_dir/$rom_name"
    if [ ! -f "$rom_dat_file" ]; then
      continue
    fi

    # [Exact match] Clone
    is_clone=$(xmlstarlet sel -T -t -v "*/@cloneof" "$rom_dat_file" || true)
    if [ "$blocklists_clones" == "true" ] && [ "$is_clone" == "true" ]; then
      continue
    fi
    if [ "$allowlists_clones" == "false" ] && [ "$is_clone" == "false" ]; then
      continue
    fi

    # [Exact match] Language
    language=$(grep -oP "^\[ \K.*(?= \] $rom_name$)" "$languages_flat_file" || true)
    if [ "$SEP$blocklists_languages$SEP" == *"$SEP$language$SEP"* ]; then
      continue
    fi
    if [ "$SEP$allowlists_languages$SEP" != *"$SEP$language$SEP"* ]; then
      continue
    fi

    # [Partial match] Category
    category=$(grep -oP "^\[ Arcade: \K.*(?= \] $rom_name$)" "$categories_flat_file" || true)
    if [ -n "$blocklists_categories" ] && [[ "$category" =~ ($blocklists_categories) ]]; then
      continue
    fi
    if [ -n "$allowlists_categories" ] && ! [[ "$category" =~ ($allowlists_categories) ]]; then
      continue
    fi

    # [Partial match] Keywords
    description=$(xmlstarlet sel -T -t -v "*/description/text()" "$rom_dat_file" | tr '[:upper:]' '[:lower:]')
    if [ -n "$blocklists_keywords" ] && [[ "$description" =~ ($blocklists_keywords) ]]; then
      continue
    fi
    if [ -n "$allowlists_keywords" ] && ! [[ "$description" =~ ($allowlists_keywords) ]]; then
      continue
    fi

    # [Partial intersection] Flags
    flags=$(echo "$description" | grep -oP "\( \K[^\)]+" || true)
    if [ -n "$blocklists_flags" ] && [[ "$flags" =~ ($blocklists_flags) ]]; then
      continue
    fi
    if [ -n "$allowlists_flags" ] && ! [[ "$flags" =~ ($allowlists_flags) ]]; then
      continue
    fi

    # [Partial intersection] Controls
    controls=$(xmlstarlet sel -T -t -v "*/input/control/@type" "$rom_dat_file" | sort | uniq || true)
    if [ -n "$blocklists_control" ] && [[ "$controls" =~ ($blocklists_control) ]]; then
      continue
    fi
    if [ -n "$allowlists_controls" ] && ! [[ "$controls" =~ ($allowlists_controls) ]]; then
      continue
    fi

    # [Exact match] Name
    if [ "$SEP$blocklists_names$SEP" == *"$SEP$rom_name$SEP"* ]; then
      continue
    fi
    if [ "$SEP$allowlists_names$SEP" != *"$SEP$rom_name$SEP"* ]; then
      continue
    fi

    # Install
    install_rom "$rom_name" "$emulator" || echo "Failed to download: $rom_name ($emulator)"
  done < <(grep -v "$SEP[x!]$SEP" "$compatibility_file" | cut -d "$SEP" -f 1)

  organize_system "$system"
  scrape_system "$system" "screenscraper"
  scrape_system "$system" "arcadedb"
  theme_system "MAME"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
