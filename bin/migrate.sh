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

  while IFS=» read path name title playlist_name xref_path; do
    # Skip if:
    # * No xref path configured
    # * xref path doesn't exist
    # * xref path exists and is valid
    if [ -z "$xref_path" ] || [ ! -f "$xref_path" ]; then
      continue
    fi

    # Configure that the path maps to the same that came back from romkit
    local old_path=$(realpath "$xref_path")
    if [ "$old_path" == "$path" ]; then
      continue
    fi

    # Determine the old rom name
    local old_filename=$(basename "$old_path")
    local old_name=${old_filename%.*}
    local old_title=${old_name%% \(*}
    local old_playlist_name=${old_name// (Disc [0-9A-Z]*)/}

    echo "# \"$old_name\" => \"$name\""
    declare -A migrated_names

    # Migrate each of:
    # * Name
    # * Title
    # * Playlist Name
    # 
    # All of these are migrated since different files for different parts
    # of the system may make use of any of these.
    if [ "$old_name" != "$name" ]; then
      migrated_names["$old_name"]=1
      __migrate_rom "$system" "$old_name" "$name" "$title"
    fi

    if [ "$old_title" != "$title" ] && [ -z "${migrated_names["$old_title"]}" ]; then
      migrated_names["$old_title"]=1
      __migrate_rom "$system" "$old_title" "$title" "$title"
    fi

    if [ -n "$playlist_name" ] && [ "$old_playlist_name" != "$playlist_name" ] && [ -z "${migrated_names["$old_playlist_name"]}" ]; then
      migrated_names["$old_playlist_name"]=1
      __migrate_rom "$system" "$old_playlist_name" "$playlist_name" "$title"
    fi

    # Update symlink
    echo ln -fs $(__bash_esc "$path") $(__bash_esc "$xref_path")
  done < <(romkit_cache_list | jq -r '[.path, .name, .title, .playlist .name, .xref .path] | join("»")')
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

  if [ ! -d "$HOME/.emulationstation/collections/" ]; then
    return
  fi

  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')

  while read collection_path; do
    while read rom_dir; do
      rom_dir=${rom_dir//"$HOME/RetroPie/roms/"/}
      __migrate_string_in_file "$collection_path" "$rom_dir/$old_name." "$rom_dir/$new_name."
    done < <(echo "$rom_dirs")
  done < <(find "$HOME/.emulationstation/collections/" -name 'custom-*.cfg')
}

# Migrates EmulationStation gamelists
__migrate_es_gamelist() {
  local system=$1
  local old_name=$2
  local new_name=$3

  # Filenames are not only XML-escaped, but their single/double
  # quotes are also escaped for some reason
  local escaped_old_name=$(echo "$old_name" | xmlstarlet esc)
  escaped_old_name=${escaped_old_name//"'"/&apos;}
  escaped_old_name=${escaped_old_name//'"'/&quot;}

  local escaped_new_name=$(echo "$new_name" | xmlstarlet esc)
  escaped_new_name=${escaped_new_name//"'"/&apos;}
  escaped_new_name=${escaped_new_name//'"'/&quot;}

  __migrate_string_in_file "$HOME/.emulationstation/gamelists/$system/gamelist.xml" "/$escaped_old_name." "/$escaped_new_name."
}

# Migrates the Skyscraper quickid database
__migrate_scraper_db() {
  local system=$1
  local old_name=$2
  local new_name=$3

  local escaped_old_name=$(echo "$old_name" | xmlstarlet esc)
  local escaped_new_name=$(echo "$new_name" | xmlstarlet esc)

  __migrate_string_in_file "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" "/$old_name." "/$new_name."
}

# Migrates Retroarch configurations in /opt/retropie/
__migrate_retroarch_config_files() {
  local system=$1
  local old_name=$2
  local new_name=$3
  local new_title=$4

  local old_title=${old_name%% \(*}

  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  local retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
  local retroarch_cheat_database_path=$(get_retroarch_path 'cheat_database_path')

  while read -r library_name; do
    # Core options / Overlays
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      # Overlay references
      # 
      # These files, although they may use the ROM's full name, will always
      # reference overlays named by title -- so when replacing strings in the
      # file, we need to pay attention to the old / new title.
      while read old_filename; do
        __migrate_string_in_file "$old_filename" "$old_title" "$new_title"
      done < <(find "$emulator_config_dir" -name "$old_name.cfg")

      # Rename files
      __migrate_files_in_dir "$emulator_config_dir" "$old_name" "$new_name"
    fi

    # Remappings
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      __migrate_files_in_dir "$emulator_remapping_dir" "$old_name" "$new_name"
    fi

    # Cheats
    __migrate_files_in_dir "$retroarch_cheat_database_path/$library_name" "$old_name" "$new_name"
  done < <(get_core_library_names)

  # Overlays - Image references
  local retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')
  while read old_filename; do
    __migrate_string_in_file "$old_filename" "$old_name" "$new_name"
  done < <(find "$retroarch_overlay_dir/$system" -name "$old_name.cfg")

  # Rename Overlay files
  __migrate_files_in_dir "$retroarch_overlay_dir/$system" "$old_name" "$new_name"
}

# Migrates files in ~/RetroPie/roms/
__migrate_rom_files() {
  local system=$1
  local old_name=$2
  local new_name=$3

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
  echo mv -v $(__bash_esc "$old_filename") $(__bash_esc "$new_filename")
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

  if grep -F "$name_to_replace" "$path" >/dev/null; then
    # Escape to avoid regex interpretation
    local escaped_name=$(echo "$name_to_replace" | sed 's:[]\[^$.*/]:\\&:g')

    # Replace the value
    local sed_command="s|$escaped_name|$replacement_value|g"
    echo sed -i $(__bash_esc "$sed_command") $(__bash_esc "$path")
  fi
}

__bash_esc() {
  printf '%q' "$1"
}

main "$@"
