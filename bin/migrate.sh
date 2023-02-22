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

  while IFS=» read path name playlist_name group_name manual_filename xref_path; do
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
    local old_playlist_name=${old_name// (Disc [0-9A-Z]*)/}

    echo "# \"$old_name\" => \"$name\""
    declare -A migrated_names

    # Migrate each of:
    # * Name
    # * Playlist Name
    # 
    # All of these are migrated since different files for different parts
    # of the system may make use of any of these.
    if [ "$old_name" != "$name" ]; then
      migrated_names["$old_name"]=1
      __migrate_rom "$system" "$old_name" "$name" "$group_name" "$manual_filename"
    fi

    if [ -n "$playlist_name" ] && [ "$old_playlist_name" != "$playlist_name" ] && [ -z "${migrated_names["$old_playlist_name"]}" ]; then
      migrated_names["$old_playlist_name"]=1
      __migrate_rom "$system" "$old_playlist_name" "$playlist_name" "$group_name" "$manual_filename"
    fi

    # Update symlink
    echo ln -fs $(__bash_esc "$path") $(__bash_esc "$xref_path")
  done < <(romkit_cache_list | jq -r '
    [
      .path,
      .name,
      .playlist .name,
      .group .name,
      (select(.manual) | (.manual.name // .group.name) + " (" + (.manual.languages | join(",")) + ")"),
      .xref .path
    ] | join("»")
  ')
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
# 
# All files are identified by rom name (or playlist name) except:
# * Manual files / downloads (by manual name)
__migrate_es_downloaded_media() {
  local system=$1
  local old_name=$2
  local new_name=$3
  local group_name=$4
  local manual_filename=$5

  local media_dir="$HOME/.emulationstation/downloaded_media/$system"
  __migrate_files_in_dir "$media_dir" "$old_name" "$new_name"

  # Migrate source manuals (use a different name than the rom)
  local manuals_dir="$media_dir/manuals"
  local manual_file="$manuals_dir/$old_name.pdf"
  if [ -f "$manual_file" ]; then
    local source_manual_file=$(realpath "$manual_file")
    local source_manual_filename=$(basename "$source_manual_file" .pdf)

    if [ "$manual_filename" != "$source_manual_filename" ]; then
      for manuals_dirname in .files .download; do
        __migrate_files_in_dir "$manuals_dir/$manuals_dirname" "$source_manual_filename" "$manual_filename"
        __migrate_files_in_dir "$manuals_dir/$manuals_dirname" "$source_manual_filename (archive)" "$manual_filename (archive)"
      done
    fi
  fi
}

# Migrates EmulationStation collections
# 
# All references are by rom name (or playlist name) only.
__migrate_es_collections() {
  local system=$1
  local old_name=$2
  local new_name=$3

  if [ ! -d "$HOME/.emulationstation/collections/" ]; then
    return
  fi

  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')

  while read collection_file; do
    while read rom_dir; do
      rom_dir=${rom_dir//"$roms_dir/"/}
      __migrate_string_in_file "$collection_file" "$rom_dir/$old_name." "$rom_dir/$new_name."
    done < <(echo "$rom_dirs")
  done < <(find "$HOME/.emulationstation/collections/" -name 'custom-*.cfg')
}

# Migrates EmulationStation gamelists
# 
# All references are by rom name (or playlist name) only.
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
# 
# All references are by rom name (or playlist name) only.
__migrate_scraper_db() {
  local system=$1
  local old_name=$2
  local new_name=$3

  local escaped_old_name=$(echo "$old_name" | xmlstarlet esc)
  local escaped_new_name=$(echo "$new_name" | xmlstarlet esc)

  __migrate_string_in_file "$retropie_configs_dir/all/skyscraper/cache/$system/quickid.xml" "/$old_name." "/$new_name."
}

# Migrates Retroarch configurations in /opt/retropie/
# 
# All references are by rom name (or playlist name) except:
# * Overlay configurations (based on title or group name)
__migrate_retroarch_config_files() {
  local system=$1
  local old_name=$2
  local new_name=$3
  local new_group=$4

  local old_title=${old_name%% \(*}
  local new_title=${new_name%% \(*}

  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
  local retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
  local retroarch_cheat_database_dir=$(get_retroarch_path 'cheat_database_path')

  declare -A image_names_to_migrate

  while read -r library_name; do
    # Core options / Overlays
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      # Overlay references
      # 
      # These files, although they may use the ROM's full name, will always
      # reference overlays named by title or group -- so when replacing strings
      # in the file, we need to pay attention that.
      while read old_filename; do
        local old_image_filename=$(grep input_overlay "$old_filename" | grep -oE "[^/]+\.cfg")
        local old_image_name=$(basename "$old_image_filename" .cfg)

        local new_image_name
        if [ "$old_image_name" == "$old_title" ]; then
          new_image_name=$new_title
        else
          new_image_name=$new_group
        fi

        if [ "$old_image_name" != "$new_image_name" ]; then
          __migrate_string_in_file "$old_filename" "$old_image_name" "$new_image_name"
          image_names_to_migrate[$old_image_name]=$new_image_name
        fi
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
    __migrate_files_in_dir "$retroarch_cheat_database_dir/$library_name" "$old_name" "$new_name"
  done < <(get_core_library_names)

  # Overlays - Image references
  local retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')
  while read old_filename; do
    __migrate_string_in_file "$old_filename" "$old_name" "$new_name"
  done < <(find "$retroarch_overlay_dir/$system" -name "$old_name.cfg")

  # Rename Overlay files
  for old_image_name in "${!image_names_to_migrate[@]}"; do
    local new_image_name=${image_names_to_migrate[$old_image_name]}
    __migrate_files_in_dir "$retroarch_overlay_dir/$system" "$old_image_name" "$new_image_name"
  done
}

# Migrates files in ~/RetroPie/roms/
# 
# All references are by rom name (or playlist name) only.
__migrate_rom_files() {
  local system=$1
  local old_name=$2
  local new_name=$3

  __migrate_files_in_dir "$roms_dir/$system" "$old_name" "$new_name"
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
