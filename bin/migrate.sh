#!/bin/bash

##############
# ROM file migration
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <all|system>"
  exit 1
}

main() {
  local system=$1

  if [ -z "$system" ] || [ "$system" == 'all' ]; then
    while read system; do
      __migrate_system "$system"
    done < <(setting '.systems[]')
  else
    __migrate_system "$system"
  fi
}

__migrate_system() {
  local system=$1
  . "$dir/setup/system-common.sh"

  while read name title playlist_name xref_path; do
    # Skip if:
    # * No xref path configured
    # * xref path doesn't exist
    # * xref path exists and is valid
    if [ -z "$xref_path" ] || [ ! -f "$xref_path" ] || [ -e "$xref_path" ]; then
      continue
    fi

    # Determine the old rom name
    local old_path=$(realpath "$xref_path")
    local old_filename=$(basename "$old_path")
    local old_name=${old_filename%.*}
    local old_title=${old_name%% \(*}
    local old_playlist_name=${old_name// (Disc [0-9A-Z]*)/}

    # Migrate each of:
    # * Name
    # * Title
    # * Playlist Name
    # 
    # All of these are migrated since different files for different parts
    # of the system may make use of any of these.
    if [ "$old_name" != "$name" ]; then
      __migrate_rom "$system" "$old_name" "$name"
    fi

    if [ "$old_title" != "$title" ]; then
      __migrate_rom "$system" "$old_title" "$title"
    fi

    if [ "$old_playlist_name" != "$playlist_name" ]; then
      __migrate_rom "$system" "$old_playlist_name" "$playlist_name"
    fi
  done < <(romkit_cache_list | jq -r '[.id, .path, .name, .title, .playlist .name, .xref .path] | join("»")')
}

__migrate_rom() {
  __migrate_es_downloaded_media "${@}"
  __migrate_es_collections "${@}"
  __migrate_es_gamelist "${@}"
  __migrate_scraper_db "${@}"
  __migrate_retroarch_config_files "${@}"
  __migrate_rom_files "${@}"
}

# Migrates media in ~/.emulationstation/downloaded_media/
__migrate_es_downloaded_media() {
  local system=$1
  local old_name=$2
  local new_name=$3

  __migrate_files_in_dir "$HOME/.emulationstation/downloaded_media/$system" "$old_name" "$new_name"
}

# Migrates EmulationStation collections
__migrate_es_collections() {
  local system=$1
  local old_name=$2
  local new_name=$3

  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')

  while read collection_path; do
    while read rom_dir; do
      __migrate_string_in_file "$collection_path" "$rom_dir/$old_name." "$rom_dir/$new_name."
    done < <(echo "$rom_dirs")
  done < <(find "$HOME/.emulationstation/collections/" -name 'custom-*.cfg')
}

# Migrates EmulationStation gamelists
__migrate_es_gamelist() {
  local system=$1
  local old_name=$2
  local new_name=$3

  __migrate_string_in_file "$HOME/.emulationstation/gamelists/$system/gamelist.xml" "/$old_name." "/$new_name."
}

# Migrates the Skyscraper quickid database
__migrate_scraper_db() {
  local system=$1
  local old_name=$2
  local new_name=$3

  __migrate_string_in_file "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" "/$old_name." "/$new_name."
}

# Migrates Retroarch configurations in /opt/retropie/
__migrate_retroarch_config_files() {
  local system=$1
  local old_name=$2
  local new_name=$3

  while read -r library_name; do
    # Core options
    local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      __migrate_files_in_dir "$emulator_config_dir" "$old_name" "$new_name"
    fi

    # Remappings
    local retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      __migrate_files_in_dir "$emulator_remapping_dir" "$old_name" "$new_name"
    fi
  done < <(get_core_library_names)
}

# Migrates files in ~/RetroPie/roms/
__migrate_rom_files() {
  __migrate_files_in_dir "$HOME/RetroPie/roms/$system" "$old_name" "$new_name"
}

# Migrates files in the given directory from one name to another
# (includes all extensions)
__migrate_files_in_dir() {
  local dir_path=$1
  local old_name=$2
  local new_name=$3

  if [ ! -d "$dir_path" ]; then
    # No files to migrate
    return
  fi

  while read old_filename; do
    __migrate_file "$old_filename" "$new_name"
  done < <(find "$dir_path" -name "$old_name.*")
}

# Renames a file based on a new name
__migrate_file() {
  local path=$1
  local new_name=$2

  local extension=${path##*.}
  local parent_dir=$(dirname "$path")
  local new_filename="$parent_dir/$new_name.$extension"
  echo mv -v "$old_filename" "$new_filename"
}

# Renames rom name references within the given file
__migrate_string_in_file() {
  local path=$1
  local name_to_replace=$2
  local replacement_value=$3

  if [ ! -f "$path" ]; then
    # Path doesn't exist -- nothing to migrate
    return
  fi

  # Escape to avoid regex interpretation
  local escaped_name=$(echo "$name_to_replace" | sed 's:[]\[^$.*/]:\\&:g')

  # Replace the value
  echo sed -i "s|$escaped_name|$replacement_value|g" "$path"
}

main "$@"
