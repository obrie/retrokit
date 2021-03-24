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

# Configurations
retroarch_config="/opt/retropie/configs/$system/retroarch.cfg"
emulators_config="/opt/retropie/configs/$system/emulators.cfg"
emulators_retropie_config="/opt/retropie/configs/all/emulators.cfg"

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
  crudini --set "$retroarch_config" '' 'run_ahead_enabled' '"true"'
  crudini --set "$retroarch_config" '' 'run_ahead_frames' '"1"'
  crudini --set "$retroarch_config" '' 'run_ahead_secondary_instance' '"true"'

  # Install emulators
  while IFS="$tab" read -r emulator build branch is_default; do
    if [ "${build:-binary}" == "binary" ]; then
      # Binary install
      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _binary_
    else
      # Source install
      if [ -n "$branch" ]; then
        # Set to correct branch
        local setup_file="$HOME/RetroPie-Setup/scriptmodules/libretrocores/$emulator.sh"
        if [ ! -f "$setup_file.orig" ]; then
          cp "$setup_file" "$setup_file.orig"
        fi

        sed -i "s/.git master/.git $branch/g" "$setup_file"
      fi

      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _source_
    fi

    # Set default
    if [ "$is_default" == "true" ]; then
      crudini --set "$emulators_config" '' 'default' "\"$emulator\""
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

# Load information about the sources from which we'll pull down ROMs
load_sources() {
  # Read configured sources
  while read -r source_name; do
    # Load the source
    while IFS="$tab" read -r key value; do
      sources["$source_name/$key"]="$value"
    done < <(jq -r ".sources.\"$source_name\" | to_entries[] | [.key, .value] | @tsv" "$app_settings_file")

    # Load emulator info
    emulators["${sources["$source_name/emulator"]}/source_name"]="$source_name"
  done < <(jq -r '.roms.sources | keys[]' "$settings_file")
}

# Build the base url for the given source / asset
source_asset_url() {
  local source_name="$1"
  local asset_name="$2"
  local source_url=${sources["$source_name/url"]}
  local asset_path=${sources["$source_name/$asset_name"]}

  if [ $(grep -E "^http" "$asset_path") ]; then
    echo "$asset_path"
  else
    echo "$source_url$asset_path"
  fi
}

# Installs a rom for a specific emulator
install_rom() {
  # Arguments
  local rom_name="$1"
  local emulator="$2"

  # Determine which source to use based on the configured emulator

  # Configuration
  local dat_dir="$system_tmp_dir/dat"
  local dat_file="$dat_dir/$rom_name"

  # Target
  mkdir -p "$roms_all_dir"

  # Source
  local source_name=${emulators["$emulator/source_name"]}
  local source_core=${sources["$source_name/core"]}

  # Source: ROMs
  local roms_source_url=$(source_asset_url "$source_name" "roms")
  local roms_emulator_dir="$roms_dir/.$source_core"
  local rom_emulator_file="$roms_emulator_dir/$rom_name.zip"
  local rom_target_file="$roms_all_dir/$rom_name.zip"
  mkdir -p "$roms_source_url"

  # Source: Samples
  local samples_source_url=$(source_asset_url "$source_name" "samples")
  local samples_target_dir="$HOME/RetroPie/BIOS/$source_core/samples"
  mkdir -p "$samples_target_dir"

  # Source: Disks
  local disks_source_url=$(source_asset_url "$source_name" "disks")
  local disk_emulator_dir="$roms_emulator_dir/$rom_name"
  local disk_target_dir="$roms_all_dir/$rom_name"

  # Only write if we haven't already written a ROM to the target destination
  if [ ! -f "$rom_target_file" ]; then
    # Install ROM asset
    if [ ! -f "$rom_emulator_file" ]; then
      wget "$roms_source_url$rom_name.zip" -O "$rom_emulator_file" || return 1
    else
      echo "Already downloaded: $rom_emulator_file"
    fi

    # Install disk assets (if applicable)
    while read disk_name; do
      mkdir -p "$disk_emulator_dir"
      local disk_emulator_file="$disk_emulator_dir/$disk_name"
      
      if [ ! -f "$disk_emulator_file" ]; then
        wget "$disks_source_url$rom_name/$disk_name" -O "$disk_emulator_file" || return 1
      else
        echo "Already downloaded: $disk_emulator_file"
      fi
    done < <(xmlstarlet sel -T -t -v "/*/disk/@name" "$dat_file")

    # Install sample asset (if applicable)
    local sample_name=$(xmlstarlet sel -T -t -v "/*/@sampleof" "$dat_file" || true)
    if [ -n "$sample_name" ]; then
      local sample_file="$samples_target_dir/$sample_name.zip"
      
      if [ ! -f "$sample_file" ]; then
        wget "$samples_source_url$sample_name.zip" -O "$sample_file" || return 1
      else
        echo "Already downloaded: $sample_file"
      fi
    fi

    # Link to -ALL- (including disk)
    ln -fs "$rom_emulator_file" "$rom_target_file"
    if [ -d "$disk_emulator_dir" ]; then
      ln -fs "$disk_emulator_dir" "$roms_all_dir/$rom_name"
    fi

    # Write emulator configuration
    crudini --set "$emulators_retropie_config" "" "$(clean_emulator_config_key "arcade_${rom_name}")" "\"$emulator\""
  fi
}

# Organize ROMs based on favorites
organize_system() {
  # Clear existing ROMs
  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Add based on favorites
  while read rom; do
    local source_rom_file="$roms_all_dir/$rom.zip"
    local source_disk_dir="$roms_all_dir/$rom"
    local target_rom_file="$roms_dir/$rom.zip"
    local target_disk_dir="$roms_dir/$rom"

    ln -fs "$source_rom_file" "$target_rom_file"

    # Create link for drive as well (if applicable)
    if [ -d "$source_disk_dir" ]; then
      ln -fs "$source_disk_dir" "$target_disk_dir"
    fi
  done < <(jq -r ".roms.favorites[]" "$settings_file")
}

# Download external support files needed for filtering purposes
download_support_files() {
  declare -A support_files
  while IFS="$tab" read -r key value; do
    support_files["$key"]="$value"
  done < <(jq -r ".support_files | to_entries[] | [.key, .value] | @tsv" "$app_settings_file")

  # Download dat file
  if [ ! -f "$dat_file" ]; then
    wget -nc "${support_files['dat_url']}" -O "$dat_dir.7z" || true
    7z e -so "$dat_dir.7z" "${support_files['dat_file']}" > "$dat_file"
  fi

  # Split dat file for better performance on lookup
  if [ "$(ls -U "$dat_dir" | wc -l)" -eq 0 ]; then
    csplit -n 6 --prefix "$dat_dir/" "$dat_file" '/<machine/' '{*}'
    while read rom_dat_file; do
      local rom_dat_filename=$(basename "$rom_dat_file")
      local rom_name=$(grep -oP "machine name=\"\K[^\"]+" "$rom_dat_file")
      
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

# Reset the list of ROMs that are visible
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

  # Overrides
  local favorites=$(jq -r ".roms.favorites[]" "$settings_file" | tr "\n" "$tab")

  # Blocklists
  declare -A blocklists
  local blocklists_clones=$(jq -r ".roms.blocklists.clones" "$settings_file")
  local blocklists_languages=$(jq -r ".roms.blocklists.languages[]" "$settings_file" | tr "\n" "$tab")
  local blocklists_categories=$(jq -r ".roms.blocklists.categories[]" "$settings_file" | tr "\n" "$tab")
  local blocklists_keywords=$(jq -r ".roms.blocklists.keywords[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local blocklists_flags=$(jq -r ".roms.blocklists.flags[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local blocklists_controls=$(jq -r ".roms.blocklists.controls[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local blocklists_names=$(jq -r ".roms.blocklists.names[]" "$settings_file" | tr "\n" "$tab")

  # Allowlists
  local allowlists_clones=$(jq -r ".roms.allowlists.clones" "$settings_file")
  local allowlists_languages=$(jq -r ".roms.allowlists.languages[]" "$settings_file" | tr "\n" "$tab")
  local allowlists_categories=$(jq -r ".roms.allowlists.categories[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local allowlists_keywords=$(jq -r ".roms.allowlists.keywords[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local allowlists_flags=$(jq -r ".roms.allowlists.flags[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local allowlists_controls=$(jq -r ".roms.allowlists.controls[]" "$settings_file" | sed 's/[][()\.^$?*+]/\\&/g' | paste -sd '|')
  local allowlists_names=$(jq -r ".roms.allowlists.names[]" "$settings_file" | tr "\n" "$tab")

  # Compatible / Runnable roms
  # See https://www.waste.org/~winkles/ROMLister/ for list of possible fitler ideas
  while read rom_name; do
    local emulator=$(grep "^$rom_name$tab" "$compatibility_file" | cut -d "$tab" -f 3)
    if [ "$emulator" == "lr-mame" ]; then
      # TODO: Remove this once we have lr-mame integration done
      emulator="lr-mame2016"
    fi

    # [Exact match] Always allow favorites regardless of filter
    if [ "$tab$favorites$tab" == *"$tab$rom_name$tab"* ]; then
      install_rom "$rom_name" "$emulator" || echo "Failed to download: $rom_name ($emulator)"
      continue
    fi

    # Attributes
    local rom_dat_file="$dat_dir/$rom_name"
    if [ ! -f "$rom_dat_file" ]; then
      continue
    fi

    # [Exact match] Clone
    local is_clone=$(xmlstarlet sel -T -t -v "*/@cloneof" "$rom_dat_file" || true)
    if [ $(filter_equals "$blocklists_clones" "$allowlists_clones" "$is_clone") ]; then
      continue
    fi

    # [Exact match] Language
    local language=$(grep -oP "^\[ \K.*(?= \] $rom_name$)" "$languages_flat_file" || true)
    if [ $(filter_exact_in_list "$blocklists_languages" "$allowlists_languages" "$language") ]; then
      continue
    fi

    # [Partial match] Category
    category=$(grep -oP "^\[ Arcade: \K.*(?= \] $rom_name$)" "$categories_flat_file" || true)
    if [ $(filter_substring_in_list "$blocklists_categories" "$allowlists_categories" "$category") ]; then
      continue
    fi

    # [Partial match] Keywords
    description=$(xmlstarlet sel -T -t -v "*/description/text()" "$rom_dat_file" | tr '[:upper:]' '[:lower:]')
    if [ $(filter_substring_in_list "$blocklists_keywords" "$allowlists_keywords" "$description") ]; then
      continue
    fi

    # [Partial match] Flags
    flags=$(echo "$description" | grep -oP "\( \K[^\)]+" || true)
    if [ $(filter_substring_in_list "$blocklists_flags" "$allowlists_flags" "$flags") ]; then
      continue
    fi

    # [Partial intersection] Controls
    controls=$(xmlstarlet sel -T -t -v "*/input/control/@type" "$rom_dat_file" | sort | uniq || true)
    if [ $(filter_all_in_list "$blocklists_controls" "$allowlists_controls" "$controls") ]; then
      continue
    fi

    # [Exact match] Name
    if [ $(filter_exact_in_list "$blocklists_names" "$allowlists_names" "$rom_name") ]; then
      continue
    fi

    # Install
    install_rom "$rom_name" "$emulator" || echo "Failed to download: $rom_name ($emulator)"
  done < <(grep -v "$tab[x!]$tab" "$compatibility_file" | cut -d "$tab" -f 1)

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
