#!/bin/bash

##############
# System: Arcade
##############

set -ex

dir=$( dirname "$0" )
. $dir/common.sh

# System info
system="arcade"
init "$system"

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
dat_file="$system_tmp_dir/roms.dat"
compatibility_file="$system_tmp_dir/compatibility.tsv"
categories_file="$system_tmp_dir/catlist.ini"
categories_flat_file="$categories_file.flat"
languages_file="$system_tmp_dir/languages.ini"
languages_flat_file="$languages_file.flat"
ratings_file="$system_tmp_dir/ratings.ini"
ratings_flat_file="$ratings_file.flat"

# In-memory mappings
declare -A roms_compatibility
declare -A roms_categories
declare -A roms_languages
declare -A roms_ratings

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
  done < <(setting ".emulators | to_entries[] | [.key, .value.build, .value.branch, .value.default] | @tsv")
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
    done < <(setting ".roms.sources.\"$source_name\" | to_entries[] | [.key, .value] | @tsv")

    # Load emulator info
    emulators["${sources["$source_name/emulator"]}/source_name"]="$source_name"
  done < <(setting '.roms.sources | keys[]')
}

# Build the base url for the given source / asset
source_asset_url() {
  local source_name="$1"
  local asset_name="$2"
  local source_url=${sources["$source_name/url"]}
  local asset_path=${sources["$source_name/$asset_name"]}

  if [[ "$asset_path" =~ ^http ]]; then
    echo "$asset_path"
  else
    echo "$source_url$asset_path"
  fi
}

# Download external support files needed for filtering purposes
download_support_files() {
  # Load support file settings
  declare -A support_files
  while IFS="$tab" read -r name url file; do
    support_files["$name/url"]="$url"
    support_files["$name/file"]="$file"
  done < <(setting ".support_files | to_entries[] | [.key, .value.url, .value.file] | @tsv")

  # Download dat file
  if [ ! -f "$dat_file" ]; then
    if [ ! -f "$dat_file.7z" ]; then
      download_file "${support_files['dat/url']}" "$dat_file.7z"
    fi
    7z e -so "$dat_file.7z" "${support_files['dat/file']}" > "$dat_file"
  fi

  # Download languages file
  if [ ! -f "$languages_flat_file" ]; then
    if [ ! -f "$languages_file.zip" ]; then
      download_file "${support_files['languages/url']}" "$languages_file.zip"
    fi
    unzip -p "$languages_file.zip" "${support_files['languages/file']}" > "$languages_file"
    crudini --get --format=lines "$languages_file" > "$languages_flat_file"
  fi

  # Download categories file
  if [ ! -f "$categories_flat_file" ]; then
    if [ ! -f "$languages_file.zip" ]; then
      download_file "${support_files['categories/url']}" "$categories_file.zip"
    fi
    unzip -p "$categories_file.zip" "${support_files['categories/file']}" > "$categories_file"
    crudini --get --format=lines "$categories_file" > "$categories_flat_file"
  fi

  # Download compatibility file
  if [ ! -f "$compatibility_file" ]; then
    download_file "${support_files['compatibility/url']}" "$compatibility_file"
  fi

  # Download ratings file
  if [ ! -f "$ratings_flat_file" ]; then
    if [ ! -f "$ratings_file.zip" ]; then
      download_file "${support_files['ratings/url']}" "$ratings_file.zip"
    fi
    unzip -p "$ratings_file.zip" "${support_files['ratings/file']}" > "$ratings_file"
    crudini --get --format=lines "$ratings_file" > "$ratings_flat_file"
  fi
}

load_support_files() {
  echo "Loading emulator compatiblity..."
  while IFS="$tab" read -r rom_name emulator; do
    roms_compatibility["$rom_name"]="$emulator"
  done < <(cat "$compatibility_file" | awk -F"$tab" "{print \$1\"$tab\"tolower(\$3)}")

  while IFS="$tab" read -r rom_name emulator; do
    roms_compatibility["$rom_name"]="$emulator"
  done < <(setting ".roms.emulator_overrides | to_entries[] | [.key, .value] | @tsv")

  echo "Loading categories..."
  while IFS="$tab" read -r rom_name category; do
    roms_categories["$rom_name"]="$category"
  done < <(cat "$categories_flat_file" | grep Arcade | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")

  echo "Loading languages..."
  while IFS="$tab" read -r rom_name language; do
    roms_languages["$rom_name"]="$language"
  done < <(cat "$languages_flat_file" | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")

  echo "Loading ratings..."
  while IFS="$tab" read -r rom_name rating; do
    roms_ratings["$rom_name"]="$rating"
  done < <(cat "$ratings_flat_file" | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")
}

# Reset the list of ROMs that are visible
reset_filtered_roms() {
  find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;
}

# Installs a rom for a specific emulator
install_rom() {
  # Arguments
  local rom_name="$1"
  local emulator="$2"
  local rom_dat="$3"

  # TODO: Single xmlstarlet call here

  # Source
  local source_name=${emulators["$emulator/source_name"]}
  local source_core=${sources["$source_name/core"]}
  local source_format=${sources["$source_name/format"]}

  # Source: ROMs
  local roms_source_url=$(source_asset_url "$source_name" "roms")
  local roms_emulator_dir="$roms_dir/.$source_core"
  local rom_emulator_file="$roms_emulator_dir/$rom_name.zip"
  local rom_target_file="$roms_all_dir/$rom_name.zip"
  mkdir -p "$roms_all_dir" "$roms_emulator_dir"

  # Source: BIOS
  local bios_emulator_dir="$HOME/RetroPie/BIOS/$source_core"

  # Source: Samples
  local samples_source_url=$(source_asset_url "$source_name" "samples")
  local samples_target_dir="$bios_emulator_dir/samples"
  mkdir -p "$samples_target_dir"

  # Source: Disks
  local disks_source_url=$(source_asset_url "$source_name" "disks")
  local disk_emulator_dir="$roms_dir/.chd/$rom_name"
  local disk_target_dir="$roms_all_dir/$rom_name"

  # Only write if we haven't already written a ROM to the target destination
  if [ ! -f "$rom_target_file" ]; then
    # Install ROM asset
    if [ ! -f "$rom_emulator_file" ]; then
      # TODO: Support split sets
      if [[ "$source_format" =~ ^(merged)$ ]]; then
        # Merged set; we need to be a little smarter with the download
        local parent_rom_name=$(echo "$rom_dat" | xmlstarlet sel -T -t -v "/*/@cloneof" || echo "$rom_name")
        local parent_rom_emulator_file="$roms_emulator_dir/$parent_rom_name.orig.zip"

        # Download parent merged rom (contains children)
        if [ ! -f "$parent_rom_emulator_file" ]; then
          download_file "$roms_source_url$parent_rom_name.zip" "$parent_rom_emulator_file"
        fi

        # Create non-merged rom in target
        local rom_nonmerged_dir="$roms_emulator_dir/$rom_name.nonmerged"
        local rom_build_dir="$rom_nonmerged_dir/build"
        rm -rf "$rom_nonmerged_dir"
        mkdir -p "$rom_build_dir"
        unzip "$parent_rom_emulator_file" -d "$rom_nonmerged_dir/"

        # Download BIOS
        local bios_rom_name
        if [ "$parent_rom_name" == "$rom_name" ]; then
          bios_rom_name=$(echo "$rom_dat" | xmlstarlet sel -T -t -v "/*/@romof" || true)
        else
          bios_rom_name=$(xmlstarlet sel -T -t -v "/*/*[@name=\"$parent_rom_name\"]/@romof" "$dat_file" || true)
        fi
        if [ -n "$bios_rom_name" ]; then
          local bios_emulator_file="$bios_emulator_dir/$bios_rom_name.zip"

          if [ ! -f "$bios_emulator_file" ]; then
            download_file "$roms_source_url$bios_rom_name.zip" "$bios_emulator_file"
          fi

          unzip "$bios_emulator_file" -d "$rom_nonmerged_dir/bios/"
        fi

        # Copy over the required roms
        while read dest_name src_name; do
          # Determine if we're merging from a parent/bios
          declare -a src_files
          if [ -n "$src_name" ]; then
            # Copy from parent / BIOS
            src_files=("$rom_nonmerged_dir/$src_name" "$rom_nonmerged_dir/bios/$src_name")
          else
            # Copy from child / parent
            src_files=("$rom_nonmerged_dir/$rom_name/$dest_name" "$rom_nonmerged_dir/$dest_name")
          fi

          # Find the first file that exists
          for src_file in "${src_files[@]}"; do
            if [ -f "$src_file" ]; then
              cp "$src_file" "$rom_build_dir/$dest_name"
              break
            fi
          done

          if [ ! -f "$rom_build_dir/$dest_name" ]; then
            echo "Missing rom: $merge_name"
            exit 1
          fi
        done < <(echo "$rom_dat" | xmlstarlet sel -T -t -m "/*/rom" -v "@name" -o "$tab" -v "@merge" -n)

        # Create ZIP at target
        zip -j "$rom_emulator_file" $rom_build_dir/*
        trrntzip "$rom_emulator_file"
        rm -rf "$rom_nonmerged_dir"
      else
        download_file "$roms_source_url$rom_name.zip" "$rom_emulator_file"
      fi
    else
      echo "Already downloaded: $rom_emulator_file"
    fi

    # Install disk assets (if applicable)
    while read disk_name; do
      mkdir -p "$disk_emulator_dir"
      local disk_emulator_file="$disk_emulator_dir/$disk_name.chd"

      if [ ! -f "$disk_emulator_file" ]; then
        echo "Downloading $disks_source_url$rom_name/$disk_name.chd"
        download_file "$disks_source_url$rom_name/$disk_name.chd" "$disk_emulator_file" || return 1
      else
        echo "Already downloaded: $disk_emulator_file"
      fi
    done < <(echo "$rom_dat" | xmlstarlet sel -T -t -v "/*/disk/@name")

    # Install sample asset (if applicable)
    local sample_name=$(echo "$rom_dat" | xmlstarlet sel -T -t -v "/*/@sampleof" || true)
    if [ -n "$sample_name" ]; then
      local sample_file="$samples_target_dir/$sample_name.zip"

      if [ ! -f "$sample_file" ]; then
        echo "Downloading $samples_source_url$sample_name.zip"
        download_file "$samples_source_url$sample_name.zip" "$sample_file" || return 1
      else
        echo "Already downloaded: $sample_file"
      fi
    fi

    # Link to -ALL- (including disk)
    ln -fs "$rom_emulator_file" "$rom_target_file"
    if [ -d "$disk_emulator_dir" ]; then
      ln -fs "$disk_emulator_dir" "$roms_all_dir/$rom_name"
    fi
  fi
}

install_roms() {
  # Overrides
  local favorites=$(setting_regex ".roms.favorites")

  # Blocklists
  local blocklists_clones=$(setting ".roms.blocklists.clones")
  local blocklists_languages=$(setting_regex ".roms.blocklists.languages")
  local blocklists_categories=$(setting_regex ".roms.blocklists.categories")
  local blocklists_ratings=$(setting_regex ".roms.blocklists.ratings")
  local blocklists_keywords=$(setting_regex ".roms.blocklists.keywords")
  local blocklists_flags=$(setting_regex ".roms.blocklists.flags")
  local blocklists_controls=$(setting_regex ".roms.blocklists.controls")
  local blocklists_names=$(setting_regex ".roms.blocklists.names")

  # Allowlists
  local allowlists_clones=$(setting ".roms.allowlists.clones")
  local allowlists_languages=$(setting_regex ".roms.allowlists.languages")
  local allowlists_categories=$(setting_regex ".roms.allowlists.categories")
  local allowlists_ratings=$(setting_regex ".roms.allowlists.ratings")
  local allowlists_keywords=$(setting_regex ".roms.allowlists.keywords")
  local allowlists_flags=$(setting_regex ".roms.allowlists.flags")
  local allowlists_controls=$(setting_regex ".roms.allowlists.controls")
  local allowlists_names=$(setting_regex ".roms.allowlists.names")

  # Filter optimization to speed things up
  local dat_skip_filter="runnable|ismechanical|players=\"0\"|softwarelist"
  if [ "$blocklists_clones" == "true" ] || [ "$allowlists_clones" == "false" ]; then
    dat_skip_filter="$dat_skip_filter|cloneof"
  fi

  while read rom_dat; do
    # Read rom attributes
    local rom_info_tsv=$(echo "$rom_dat" | xmlstarlet sel -T -t -m "/*" -v "@name" -o "$tab" -v "boolean(@cloneof)" -o "$tab" -v "description/text()")
    IFS="$tab" read -ra rom_info <<< "$rom_info_tsv"
    local rom_name=${rom_info[0]}
    local is_clone=${rom_info[1]}
    local description=$(echo "${rom_info[2]}" | tr '[:upper:]' '[:lower:]')
    local emulator=${roms_compatibility["$rom_name"]}
    local category=${roms_categories["$rom_name"]}
    local language=${roms_languages["$rom_name"]}
    local rating=${roms_ratings["$rom_name"]}
    local source_name=${emulators["$emulator/source_name"]}

    # Compatible / Runnable roms
    if [ -z "$emulator" ]; then
      echo "[Skip] $rom_name (poor compatibility)"
      continue
    fi

    # ROMs with sources
    if [ -z "$source_name" ]; then
      echo "[Skip] $rom_name (no source for emulator)"
      continue
    fi

    # Always allow favorites regardless of filter
    if filter_regex "" "$favorites" "$rom_name" exact_match=true; then
      # Is Clone
      if filter_regex "$blocklists_clones" "$allowlists_clones" "$is_clone"; then
        echo "[Skip] $rom_name (clone)"
        continue
      fi

      # Language
      if filter_regex "$blocklists_languages" "$allowlists_languages" "$language"; then
        echo "[Skip] $rom_name (language)"
        continue
      fi

      # Category
      if filter_regex "$blocklists_categories" "$allowlists_categories" "$category"; then
        echo "[Skip] $rom_name (category)"
        continue
      fi

      # Rating
      if filter_regex "$blocklists_ratings" "$allowlists_ratings" "$rating"; then
        echo "[Skip] $rom_name (rating)"
        continue
      fi

      # Keywords
      if filter_regex "$blocklists_keywords" "$allowlists_keywords" "$description"; then
        echo "[Skip] $rom_name (description)"
        continue
      fi

      # Flags
      local flags=$(echo "$description" | grep -oP "\(\K[^\)]+" || true)
      if filter_regex "$blocklists_flags" "$allowlists_flags" "$flags"; then
        echo "[Skip] $rom_name (flags)"
        continue
      fi

      # Controls
      # TODO: Move this to the above xmlstarlet call
      local controls=$(echo "$rom_dat" | xmlstarlet sel -T -t -v "*/input/control/@type" | sort | uniq || true)
      if filter_all_in_list "$blocklists_controls" "$allowlists_controls" "$controls"; then
        echo "[Skip] $rom_name (controls)"
        continue
      fi

      # Name
      if filter_regex "$blocklists_names" "$allowlists_names" "$rom_name" exact_match=true; then
        echo "[Skip] $rom_name (name)"
        continue
      fi
    fi

    # Install
    echo "[Install] $rom_name"
    install_rom "$rom_name" "$emulator" "$rom_dat" || echo "Failed to download: $rom_name ($emulator)"
  done < <(awk '{sub(/\r/,"")}/<machine/{i=1}/<\/machine/{i=0;print;next}i{printf"%s",$0}{next}' "$dat_file" | awk "/machine name=\"($favorites)\"/ || "'!'"/$dat_skip_filter/")

  # Merge emulator configurations
  # 
  # This is done at the end in one batch because it's a bit slow otherwise
  crudini --merge "$emulators_retropie_config" < <(
    for rom_name in "${!emulators[@]}"; do
      echo "$(clean_emulator_config_key "arcade_$rom_name") = \"${emulators["$rom_name"]}\""
    done
  )
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
  done < <(setting ".roms.favorites[]")
}

# This is strongly customized due to the nature of Arcade ROMs
# 
# MAYBE it could be generalized, but I'm not convinced it's worth the effort.
download() {
  load_sources
  download_support_files
  load_support_files
  reset_filtered_roms
  install_roms
  organize_system "$system"
  scrape_system "$system" "screenscraper"
  scrape_system "$system" "arcadedb"
  build_gamelist "$system"
  theme_system "MAME"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
