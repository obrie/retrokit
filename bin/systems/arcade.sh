#!/bin/bash

##############
# System: Arcade
##############

set -e
if [ -n "$VERBOSE" ]; then
  set -x
fi

dir=$( dirname "$0" )
. $dir/common.sh

# System info
system="arcade"
init "$system"

# Directories
config_dir="$app_dir/config/systems/$system"
system_tmp_dir="$tmp_dir/arcade"
roms_dir="$HOME/RetroPie/roms/$system"
roms_all_dir="$roms_dir/-ALL-"
mkdir -p "$system_tmp_dir" "$roms_all_dir"

# Configurations
settings_file="$config_dir/settings.json"
retroarch_config="/opt/retropie/configs/$system/retroarch.cfg"
emulators_config="/opt/retropie/configs/$system/emulators.cfg"
emulators_retropie_config="/opt/retropie/configs/all/emulators.cfg"

# Support files
compatibility_file="$system_tmp_dir/compatibility.tsv"
categories_file="$system_tmp_dir/catlist.ini"
categories_flat_file="$categories_file.flat"
languages_file="$system_tmp_dir/languages.ini"
languages_flat_file="$languages_file.flat"
ratings_file="$system_tmp_dir/ratings.ini"
ratings_flat_file="$ratings_file.flat"

# Filters: Overrides
favorites=$(setting_regex ".roms.favorites")

# Filters: Blocklists
blocklists_clones=$(setting ".roms.blocklists.clones")
blocklists_languages=$(setting_regex ".roms.blocklists.languages")
blocklists_categories=$(setting_regex ".roms.blocklists.categories")
blocklists_ratings=$(setting_regex ".roms.blocklists.ratings")
blocklists_keywords=$(setting_regex ".roms.blocklists.keywords")
blocklists_flags=$(setting_regex ".roms.blocklists.flags")
blocklists_controls=$(setting_regex ".roms.blocklists.controls")
blocklists_names=$(setting_regex ".roms.blocklists.names")

# Filters: Allowlists
allowlists_clones=$(setting ".roms.allowlists.clones")
allowlists_languages=$(setting_regex ".roms.allowlists.languages")
allowlists_categories=$(setting_regex ".roms.allowlists.categories")
allowlists_ratings=$(setting_regex ".roms.allowlists.ratings")
allowlists_keywords=$(setting_regex ".roms.allowlists.keywords")
allowlists_flags=$(setting_regex ".roms.allowlists.flags")
allowlists_controls=$(setting_regex ".roms.allowlists.controls")
allowlists_names=$(setting_regex ".roms.allowlists.names")

# XSLT for grabbing data from DAT files
roms_dat_xslt='''<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" version="1.0" extension-element-prefixes="exslt">
  <xsl:variable name="lowercase" select="'"'"'abcdefghijklmnopqrstuvwxyz'"'"'" />
  <xsl:variable name="uppercase" select="'"'"'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"'"'" />
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:template match="/">
    <xsl:for-each select="/*/*[rom and not(@ismechanical = '"'"'yes'"'"')]">
      <xsl:value-of select="@name"/>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:value-of select="translate(description/text(), $uppercase, $lowercase)"/>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:value-of select="@romof"/>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:value-of select="@cloneof"/>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:value-of select="@sampleof"/>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:for-each select="rom[@merge and not(@status = '"'"'nodump'"'"')]">
        <xsl:value-of select="@name"/><xsl:text>,</xsl:text>
        <xsl:value-of select="@crc"/><xsl:text>,</xsl:text>
        <xsl:value-of select="@merge"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:for-each select="rom[not(@merge) and not(@status = '"'"'nodump'"'"')]">
        <xsl:value-of select="@name"/><xsl:text>,</xsl:text>
        <xsl:value-of select="@crc"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:for-each select="device_ref">
        <xsl:value-of select="@name"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:for-each select="disk">
        <xsl:value-of select="@name"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:text>&#xBB;</xsl:text>
      <xsl:for-each select="input/control">
        <xsl:value-of select="@type"/><xsl:text> </xsl:text>
      </xsl:for-each>
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
'''

# In-memory mappings: Filters
declare -A roms_compatibility
declare -A roms_categories
declare -A roms_languages
declare -A roms_ratings

# In-memory mappings: Sets / roms
declare reference_set_name
declare -A sets
declare -A emulators
declare -A roms
declare -a rom_names

usage() {
  echo "usage: $0"
  exit 1
}

##############
# Setup
##############

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
        backup "$setup_file"

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

##############
# Sets
##############

# Load information about the sets from which we'll pull down ROMs
load_sets() {
  log "--- Loading sets ---"

  # Read configured sets
  while read -r set_name; do
    # Load the set
    while IFS="$tab" read -r key value; do
      sets["$set_name/$key"]="$value"
    done < <(setting ".roms.sets.\"$set_name\" | to_entries[] | [.key, .value] | @tsv")

    # Load emulator info
    emulators["${sets["$set_name/emulator"]}/set_name"]="$set_name"
  done < <(setting '.roms.sets | keys[]')
}

index_sets() {
  log "--- Indexing sets ---"

  while read -r set_name; do
    local set_core=${sets["$set_name/core"]}
    local set_dat_url=$(get_set_url "$set_name" "dat")
    local set_dat_refresh=${sets["$set_name/dat_refresh"]}
    local set_is_reference=${sets["$set_name/reference"]}
    local target_dat_file="$system_tmp_dir/$set_core.dat"

    download_file "$set_dat_url" "$target_dat_file" refresh=$set_dat_refresh

    if [ ! -s "$target_dat_file.index" ]; then
      log "Generating index for $set_name"
      xmlstarlet tr <(echo "$roms_dat_xslt") "$target_dat_file" > "$target_dat_file.index"
    fi

    if [ -n "$set_is_reference" ]; then
      reference_set_name="$set_name"
    fi

    # Find the list of roms that are downloadable
    log "Loading index for $set_name"
    while IFS="»" read -r name description romof cloneof sampleof merge_files files device_refs disks controls; do
      if [ -n "$set_is_reference" ]; then
        rom_names+=("$name")
      fi

      # Desription
      roms["$set_name/$name/description"]="$description"

      # Parent
      if [ -n "$cloneof" ]; then
        roms["$set_name/$name/parent"]="$cloneof"

        if [ -n "$merge_files" ]; then
          roms["$set_name/$name/merge_files"]="$merge_files"
        fi
      else
        # BIOS
        if [ -n "$romof" ]; then
          roms["$set_name/$name/bios"]="$romof"
        fi
      fi

      # Sample
      if [ -n "$sampleof" ]; then
        roms["$set_name/$name/sampleof"]="$sampleof"
      fi

      # Files
      if [ -n "$files" ]; then
        roms["$set_name/$name/files"]="$files"
      fi

      # Devices
      if [ -n "$device_refs" ]; then
        roms["$set_name/$name/devices"]="$device_refs"
      fi

      # Disks
      if [ -n "$disks" ]; then
        roms["$set_name/$name/disks"]="$disks"
      fi

      # Controls
      if [ -n "$controls" ]; then
        roms["$set_name/$name/controls"]="$controls"
      fi
    done < "$target_dat_file.index"
  done < <(setting '.roms.sets | keys[]')
}

# Build the base url for the given set / asset
get_set_url() {
  local set_name="$1"
  local asset_name="$2"
  local set_url=${sets["$set_name/url"]}
  local asset_path=${sets["$set_name/$asset_name"]}

  if [[ "$asset_path" =~ ^(http|https|file):// ]]; then
    echo "$asset_path"
  else
    echo "$set_url$asset_path"
  fi
}

##############
# Support Files
##############

# Download external support files needed for filtering purposes
download_support_files() {
  log "--- Downloading support files ---"

  # Load support file settings
  declare -A support_files
  while IFS="$tab" read -r name url file; do
    support_files["$name/url"]="$url"
    support_files["$name/file"]="$file"
  done < <(setting ".support_files | to_entries[] | [.key, .value.url, .value.file] | @tsv")

  # Download languages file
  if [ ! -s "$languages_flat_file" ]; then
    download_file "${support_files['languages/url']}" "$languages_file.zip"
    unzip -p "$languages_file.zip" "${support_files['languages/file']}" > "$languages_file"
    crudini --get --format=lines "$languages_file" > "$languages_flat_file"
  fi

  # Download categories file
  if [ ! -s "$categories_flat_file" ]; then
    download_file "${support_files['categories/url']}" "$categories_file.zip"
    unzip -p "$categories_file.zip" "${support_files['categories/file']}" > "$categories_file"
    crudini --get --format=lines "$categories_file" > "$categories_flat_file"
  fi

  # Download compatibility file
  download_file "${support_files['compatibility/url']}" "$compatibility_file"

  # Download ratings file
  if [ ! -s "$ratings_flat_file" ]; then
    download_file "${support_files['ratings/url']}" "$ratings_file.zip"
    unzip -p "$ratings_file.zip" "${support_files['ratings/file']}" > "$ratings_file"
    crudini --get --format=lines "$ratings_file" > "$ratings_flat_file"
  fi
}

load_support_files() {
  download_support_files

  log "--- Loading support files ---"

  log "Loading emulator compatiblity"
  while IFS="$tab" read -r rom_name emulator; do
    roms_compatibility["$rom_name"]="$emulator"
  done < <(cat "$compatibility_file" | grep -v "$tab[x!]$tab" | awk -F"$tab" "{print \$1\"$tab\"tolower(\$3)}")

  while IFS="$tab" read -r rom_name emulator; do
    roms_compatibility["$rom_name"]="$emulator"
  done < <(setting ".roms.emulator_overrides | to_entries[] | [.key, .value] | @tsv")

  log "Loading categories"
  while IFS="$tab" read -r rom_name category; do
    roms_categories["$rom_name"]="$category"
  done < <(cat "$categories_flat_file" | grep Arcade | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")

  log "Loading languages"
  while IFS="$tab" read -r rom_name language; do
    roms_languages["$rom_name"]="$language"
  done < <(cat "$languages_flat_file" | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")

  log "Loading ratings"
  while IFS="$tab" read -r rom_name rating; do
    roms_ratings["$rom_name"]="$rating"
  done < <(cat "$ratings_flat_file" | sed "s/^\[ \(.*\) \] \(.*\)$/\2$tab\1/g")
}

##############
# ROM Installation
##############

# Creates an empty zip file
create_empty_rom() {
  echo -ne '\x50\x4b\x05\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' > "$1"
}

# Gets the file names from fileinfo objects
get_file_names() {
  if [ -z "$1" ]; then
    return 0
  fi

  local names=()
  for file in $1; do
    local file_info=(${file//,/ })
    names+=(${file_info[0]})
  done

  echo "${names[@]}"
}

# Checks whether the target rom/machine already contains all of the files for the
# source rom/machine
validate_rom_has_files() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"
  local files="$3"

  # Set info
  local set_core=${sets["$set_name/core"]}
  local set_roms_dir="$roms_dir/.$set_core"

  # Target info
  local rom_file="$set_roms_dir/$rom_name.zip"
  if [ ! -s "$rom_file" ]; then
    # Target doesn't exist at all: not valid
    return 1
  fi
  local existing_files="$(unzip -vl "$rom_file" 2>/dev/null)"

  for file in $files; do
    local file_info=(${file//,/ })
    local file_name="${file_info[0]}"
    local file_checksum="${file_info[1]}"

    if [[ " $existing_files " != *" $file_checksum "*" $file_name"* ]]; then
      # Missing a file: not valid
      log "[$rom_name] Missing file: $file_name (crc: $file_checksum)"
      return 1
    fi
  done

  return 0
}

download_rom() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_core=${sets["$set_name/core"]}
  local set_login=${sets["$set_name/login"]:-false}
  local set_roms_url=$(get_set_url "$set_name" "roms")

  # Rom info
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ -f "$rom_file" ]; then
    # Make sure the rom has everything we expect it to have, otherwise we need to re-download it
    local redownload=false
    local existing_files="$(unzip -vl "$rom_file" 2>/dev/null)"

    for expected_file in ${roms["$set_name/$rom_name/files"]}; do
      local file_info=(${expected_file//,/ })
      local file_name="${file_info[0]}"
      local file_checksum="${file_info[1]}"

      if [[ " $existing_files " != *" $file_checksum "*" $file_name"* ]]; then
        redownload=true
        log "[$rom_name] Existing ROM missing file: $file_name (crc: $file_checksum); re-downloading"
        break
      fi
    done

    if [ "$redownload" == "false" ]; then
      return 0
    fi
  fi

  download_file "$set_roms_url$rom_name.zip" "$rom_file" login=$set_login force=true
}

merge_rom() {
  # Arguments
  local set_name="$1"
  local merge_from="$2"
  local merge_to="$3"

  # Optional arguments
  local source_suffix=""
  local source_from="$merge_from"
  local include_all="false"
  local files="${roms["$set_name/$merge_from/files"]}"
  if [ $# -gt 3 ]; then local "${@:4}"; fi

  if [ -z "$files" ]; then
    # Ignore and don't log anything -- this rom has no files
    return 0
  fi

  # Check if merging is needed (either there are no files to merge or we have all the files)
  if validate_rom_has_files "$set_name" "$merge_to" "$files"; then
    log "[$merge_to] Skip merge $merge_from (no files or already merged)"
    return 0
  fi

  # Set info
  local set_roms_dir="$roms_dir/.${sets["$set_name/core"]}"
  local set_tmp_dir="$set_roms_dir/tmp"
  mkdir -p "$set_tmp_dir"

  # Source file
  local source_from_archive="$set_roms_dir/$source_from$source_suffix.zip"

  # Target file
  local merge_to_archive="$set_roms_dir/$merge_to.zip"
  if [ ! -s "$merge_to_archive" ]; then
    create_empty_rom "$merge_to_archive"
  fi

  # Download the rom we're sourcing from
  download_rom "$set_name" "$source_from" rom_file="$source_from_archive"

  if [ "$include_all" == "true" ]; then
    # Merge everything
    log "[$merge_to] Merging all files from $merge_from"
    zipmerge -S "$merge_to_archive" "$source_from_archive" >/dev/null
  else
    local existing_files="$(unzip -vl "$merge_to_archive" 2>/dev/null)"

    # Merge files
    for file in $files; do
      local file_info=(${file//,/ })
      local file_target="${file_info[0]}"
      local file_checksum="${file_info[1]}"
      local file_source="${file_info[2]:-$file_target}"

      if [[ " $existing_files " != *" $file_checksum "*" $file_target"* ]]; then
        log "[$merge_to] Merging $file_target (crc: $file_checksum) from $merge_from"

        # File doesn't exist: add it (using crc would be more accurate)
        local tmp_file="$set_tmp_dir/$file_target"
        local file_to_extract=$(zipinfo -1 "$source_from_archive" | grep -E "(^|/)$file_source\$")

        unzip -p "$source_from_archive" "$file_to_extract" > "$tmp_file"
        zip -j "$merge_to_archive" "$tmp_file" >/dev/null
        rm "$tmp_file"
      fi
    done
  fi
}

install_rom_nonmerged_file() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_name="${emulators["$emulator/set_name"]}"
  local set_format="${sets["$set_name/format"]}"

  # Rom info
  local parent_rom_name="${roms["$set_name/$rom_name/parent"]}"
  local merge_files="${roms["$set_name/$rom_name/merge_files"]}"

  if [ "$set_format" == "merged" ]; then
    args="source_from=${parent_rom_name:-$rom_name} source_suffix=.merged"

    merge_rom "$set_name" "$parent_rom_name" "$rom_name" $args files="$merge_files"
    merge_rom "$set_name" "$rom_name" "$rom_name" $args
  else
    download_rom "$set_name" "$rom_name"

    if [ "$set_format" == "split" ]; then
      merge_rom "$set_name" "$parent_rom_name" "$rom_name" files="$merge_files"
    fi
  fi
}

install_rom_bios() {
  local set_name="$1"
  local rom_name="$2"
  local bios_rom_name="${roms["$set_name/$rom_name/bios"]}"

  merge_rom "$set_name" "$bios_rom_name" "$rom_name" include_all=true
}

install_rom_devices() {
  local set_name="$1"
  local rom_name="$2"

  # Merge devices (if necessary)
  for device_name in ${roms["$set_name/$rom_name/devices"]}; do
    merge_rom "$set_name" "$device_name" "$rom_name" include_all=true
  done
}

# Lists the files that should be in the given rom
list_expected_rom_files() {
  # Arguments
  set_name="$1"
  rom_name="$2"

  # ROM info
  local set_core="${sets["$set_name/core"]}"
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"
  local bios_name="${roms["$set_name/$rom_name/bios"]}"

  # Build list of files we expect to see
  local expected_files=($(get_file_names "${roms["$set_name/$rom_name/files"]} ${roms["$set_name/$rom_name/merge_files"]} ${roms["$set_name/$bios_name/files"]}"))
  for device in ${roms["$set_name/$rom_name/devices"]}; do
    expected_files+=($(get_file_names "${roms["$set_name/$device/files"]}"))
  done

  echo "${expected_files[@]}"
}

clean_rom() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"
  local expected_files="$3"

  # ROM info
  local set_core="${sets["$set_name/core"]}"
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"

  # Rom actual files on the filsystem
  local existing_files="$(zipinfo -1 "$rom_file" | paste -sd ' ')"

  # Remove the differences
  for file in $existing_files; do
    if [[ " $expected_files " != *" $file "* ]]; then
      # File should not be there: delete it
      log "[$rom_name] Deleting unused file: $file"
      zip -d "$rom_file" "$file"
    fi
  done
}

torrentzip_rom() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # ROM info
  local set_core="${sets["$set_name/core"]}"
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"

  log "[$rom_name] Torrentzip'ing"

  # Ensure TorrentZip logs are clear in case there was an error log (which will
  # cause the command to be interactive)
  rm -f $app_dir/log/*log

  # Create ZIP at target
  pushd "$app_dir/log" &>/dev/null
  trrntzip "$rom_file" >/dev/null
  popd &>/dev/null

  # Remove generated logs
  rm -f $app_dir/log/*log
}

install_rom_disks() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_core=${sets["$set_name/core"]}

  # Disks
  local disks_url=$(get_set_url "$set_name" "disks")
  local disk_dir="$roms_dir/.chd/$rom_name"

  # Install
  for disk_name in ${roms["$set_name/$rom_name/disks"]}; do
    mkdir -p "$disk_dir"
    local disk_file="$disk_dir/$disk_name.chd"

    log "[$rom_name] Installing disk: $disk_name"
    download_file "$disks_url$rom_name/$disk_name.chd" "$disk_file" || return 1
  done
}

install_rom_samples() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_core=${sets["$set_name/core"]}

  # Samples
  local samples_url=$(get_set_url "$set_name" "samples")
  local samples_dir="$HOME/RetroPie/BIOS/$set_core/samples"
  mkdir -p "$samples_dir"

  # Install
  local sample_name=${roms["$set_name/$rom_name/sample"]}
  if [ -n "$sample_name" ]; then
    local sample_file="$samples_dir/$sample_name.zip"

    log "[$rom_name] Installing sample: $sample_name"
    download_file "$samples_url$sample_name.zip" "$sample_file" || return 1
  fi
}

enable_rom() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_core=${sets["$set_name/core"]}
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"
  local disk_dir="$roms_dir/.chd/$rom_name"

  # Target
  local enabled_rom_file="$roms_all_dir/$rom_name.zip"
  local enabled_disk_dir="$roms_all_dir/$rom_name"
  mkdir -p "$roms_all_dir"

  log "[$rom_name] Enabling"

  # Link to -ALL- (including disk)
  ln -fs "$rom_file" "$enabled_rom_file"
  if [ -d "$disk_dir" ]; then
    ln -fs "$disk_dir" "$enabled_disk_dir"
  fi
}

# Installs a rom for a specific emulator
install_rom() {
  # Arguments
  local set_name="$1"
  local rom_name="$2"

  # Set info
  local set_core=${sets["$set_name/core"]}
  local rom_file="$roms_dir/.$set_core/$rom_name.zip"

  log "[$rom_name] Installing..."

  install_rom_nonmerged_file "${@}"
  install_rom_bios "${@}"
  install_rom_devices "${@}"
  install_rom_disks "${@}"
  install_rom_samples "${@}"

  # Make sure generated rom is valid
  local expected_files="$(list_expected_rom_files "$set_name" "$rom_name")"
  if validate_rom_has_files "${@}" "$expected_files"; then
    clean_rom "${@}" "$expected_files"
    torrentzip_rom "${@}"
    enable_rom "${@}"
  else
    log "[$rom_name] Skip (missing files!)"
  fi
}

should_install_rom() {
  # Arguments
  local rom_name="$1"

  # Filters
  local emulator=${roms_compatibility["$rom_name"]}
  local set_name=${emulators["$emulator/set_name"]}
  local is_clone=${roms["$reference_set_name/$rom_name/cloneof"]}
  local description=${roms["$reference_set_name/$rom_name/description"]}
  local controls=${roms["$reference_set_name/$rom_name/controls"]}
  local category=${roms_categories["$rom_name"]}
  local language=${roms_languages["$rom_name"]}
  local rating=${roms_ratings["$rom_name"]}

  # Compatible / Runnable roms
  if [ -z "$emulator" ]; then
    log "[$rom_name] Skip (no compatibility)"
    return 1
  fi

  # ROMs with sets
  if [ -z "$set_name" ]; then
    log "[$rom_name] Skip (no set for emulator)"
    return 1
  fi

  # Always allow favorites regardless of filter
  if filter_regex "" "$favorites" "$rom_name" exact_match=true; then
    # Is Clone
    if filter_regex "$blocklists_clones" "$allowlists_clones" "$is_clone"; then
      log "[$rom_name] Skip (clone)"
      return 1
    fi

    # Language
    if filter_regex "$blocklists_languages" "$allowlists_languages" "$language"; then
      log "[$rom_name] Skip (language)"
      return 1
    fi

    # Category
    if filter_regex "$blocklists_categories" "$allowlists_categories" "$category"; then
      log "[$rom_name] Skip (category)"
      return 1
    fi

    # Rating
    if filter_regex "$blocklists_ratings" "$allowlists_ratings" "$rating"; then
      log "[$rom_name] Skip (rating)"
      return 1
    fi

    # Keywords
    if filter_regex "$blocklists_keywords" "$allowlists_keywords" "$description"; then
      log "[$rom_name] Skip (description)"
      return 1
    fi

    # Flags
    local flags=$(echo "$description" | grep -oP "\(\K[^\)]+" || true)
    if filter_regex "$blocklists_flags" "$allowlists_flags" "$flags"; then
      log "[$rom_name] Skip (flags)"
      return 1
    fi

    # Controls
    if filter_all_in_list "$blocklists_controls" "$allowlists_controls" "$controls"; then
      log "[$rom_name] Skip (controls)"
      return 1
    fi

    # Name
    if filter_regex "$blocklists_names" "$allowlists_names" "$rom_name" exact_match=true; then
      log "[$rom_name] Skip (name)"
      return 1
    fi
  fi

  return 0
}

install_roms() {
  log "--- Installing roms ---"
  for rom_name in "${rom_names[@]}"; do
    if should_install_rom "$rom_name"; then
      # Read rom attributes
      local emulator=${roms_compatibility["$rom_name"]}
      local set_name=${emulators["$emulator/set_name"]}

      # Install
      install_rom "$set_name" "$rom_name" || log "[$rom_name] Failed to download (set: $set_name)"
    fi
  done
}

# Reset the list of ROMs that are visible
reset_roms() {
  if [ -d "$roms_all_dir" ]; then
    find "$roms_all_dir/" -maxdepth 1 -type l -exec rm "{}" \;
  fi
}

##############
# ROM Organization
##############

set_default_emulators() {
  log "--- Setting default emulators ---"

  # Merge emulator configurations
  # 
  # This is done at the end in one batch because it's a bit slow otherwise
  crudini --merge "$emulators_retropie_config" < <(
    for rom_name in "${emulators[@]}"; do
      echo "$(clean_emulator_config_key "arcade_$rom_name") = \"${emulators["$rom_name"]}\""
    done
  )
}

# Organize ROMs based on favorites
organize_system() {
  log "--- Organizing rom directories ---"

  # Clear existing ROMs
  find "$roms_dir/" -maxdepth 1 -type l -exec rm "{}" \;

  # Add based on favorites
  while read rom; do
    local source_file="$roms_all_dir/$rom.zip"
    local source_disk_dir="$roms_all_dir/$rom"
    local target_file="$roms_dir/$rom.zip"
    local target_disk_dir="$roms_dir/$rom"

    log "[$rom] Adding to favorites"

    ln -fs "$source_file" "$target_file"

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
  load_sets
  index_sets
  load_support_files
  reset_roms
  install_roms
  set_default_emulators
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
