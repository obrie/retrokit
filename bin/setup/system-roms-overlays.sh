#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-overlays'
setup_module_desc='Game-specific overlays to display for libretro emulators (lightgun compatible)'

# The directory to which we'll install the configurations and images
retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')
retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
system_overlay_dir="$retroarch_overlay_dir/$system"

# Overlay support
supports_vertical_overlays=$(system_setting 'select(.overlays .vertical) | true')
enable_lightgun_borders=$(setting '.overlays.lightgun_border.enabled')

# This installs individual overlays from The Bezel Project.  We use this instead of
# The Bezel Project's installer for two primary reasons:
# 
# * It reduces the amount of disk space required by an order of magnitude
# * The rom names don't always exactly match because either different regions are
#   installed or the No-Intro DATs have changed over time
# 
# Yes, this takes longer.  However, the pros far outweigh the cons.  We also don't
# clone so that we don't have to pull down the entire repo any time there's a new
# ROM added.
configure() {
  # Check if we're actually installing overlays
  if [ -z "$(system_setting '.overlays.default')" ]; then
    echo 'No overlays configured'
    return
  fi

  # Load the data we're going to need to do the install
  load_emulator_data
  __load_overlay_urls

  declare -Ag installed_files
  declare -A installed_playlists
  mkdir -pv "$system_overlay_dir"

  # Download overlays for installed roms and their associated emulator according
  # to romkit
  while IFS=» read -r rom_name playlist_name title group_name orientation emulator overlay_url controls; do
    emulator=${emulator:-default}
    local library_name=${emulators["$emulator/library_name"]}
    local is_lightgun=$([[ "$controls" == *lightgun* ]] && echo 'true' || echo 'false')
    local overlay_title=$group_name

    # Make sure this is a libretro core
    if [ -z "$library_name" ]; then
      continue
    fi

    if [ -z "$overlay_url" ]; then
      # Look up either by the current rom or the parent rom
      overlay_url=${overlay_urls[$rom_name]:-${overlay_urls[$(normalize_rom_name "$rom_name")]}}

      if [ -n "$overlay_url" ]; then
        overlay_title=$title
      else
        overlay_url=${overlay_urls[$group_name]:-${overlay_urls[$(normalize_rom_name "$group_name")]}}
      fi
    fi

    if [ -z "$overlay_url" ]; then
      echo "[$rom_name] No overlay available"

      if [ -z "$playlist_name" ]; then
        # Install overlay for single-disc games
        __create_default_retroarch_config "$rom_name" "$emulator" "$orientation" "$is_lightgun"
      elif [ ! "${installed_playlists["$playlist_name"]}" ]; then
        # Install overlay for the playlist
        __create_default_retroarch_config "$playlist_name" "$emulator" "$orientation" "$is_lightgun"
      fi

      continue
    fi

    # We have an image: download it
    __install_overlay "$overlay_url" "$overlay_title" "$is_lightgun"

    if [ -z "$playlist_name" ]; then
      # Install overlay for single-disc game
      __create_retroarch_config "$rom_name" "$emulator" "$system_overlay_dir/$overlay_title.cfg"
    elif [ ! "${installed_playlists["$playlist_name"]}" ]; then
      # Install overlay for the playlist
      __create_retroarch_config "$playlist_name" "$emulator" "$system_overlay_dir/$overlay_title.cfg"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .playlist.name, .title, .group.name, .orientation, .emulator, .media.overlay, (.controls | join(","))] | join("»")')

  __remove_unused_configs
}

# Get the list of overlay images available in each repo
__load_overlay_urls() {
  echo "Loading list of available overlays..."
  declare -Ag overlay_urls

  while IFS=$'\t' read -r repo branch rom_images_path; do
    local github_tree_path="$system_tmp_dir/$repo.list"

    if [ ! -f "$github_tree_path" ]; then
      # Get the Tree SHA for the directory storing the images
      local parent_tree_path=$(dirname "$rom_images_path")
      local sub_tree_name=$(basename "$rom_images_path")
      local tree_sha=$(__call_github_api "https://api.github.com/repos/$repo/contents/$parent_tree_path?ref=$branch" | jq -r ".[] | select(.name == \"$sub_tree_name\") | .sha")

      # Get the list of files at that sub-tree
      __call_github_api "https://api.github.com/repos/$repo/git/trees/$tree_sha" "$github_tree_path"
    fi

    while IFS=$'\t' read -r rom_name encoded_rom_name ; do
      local source_url="https://github.com/$repo/raw/$branch/$rom_images_path/$encoded_rom_name.png"
      overlay_urls["$rom_name"]="$source_url"

      # Generate a unique identifier for this rom
      local rom_id=$(normalize_rom_name "$rom_name")
      if [ -z "${overlay_urls["$rom_id"]}" ]; then
        overlay_urls["$rom_id"]="$source_url"
      fi
    done < <(jq -r '.tree[].path | select(. | contains(".png")) | split("/")[-1] | sub("\\.png$"; "") | [(. | @text), (. | @uri)] | @tsv' "$github_tree_path" | sort | uniq)
  done < <(system_setting '.overlays.repos[] | [.repo, .branch // "master", .path] | @tsv')
}

# Makes a call to GitHub with an authentication token (if provided)
__call_github_api() {
  local url=$1
  local path=$2
  download "$url" "$path" auth_token="$GITHUB_API_KEY"
}

# Download and install an overlay from the given url
__install_overlay() {
  local url=$1
  local overlay_title=$2
  local is_lightgun=$3

  local image_filename="$overlay_title.png"
  download "$url" "$system_overlay_dir/$image_filename"

  # Check if this is a lightgun game that needs special processing
  if [ "$enable_lightgun_borders" == 'true' ] && [ "$is_lightgun" == 'true' ]; then
    outline_overlay_image "$system_overlay_dir/$image_filename" "$system_overlay_dir/$overlay_title-lightgun.png"

    # Track the old file and update it to the lightgun version
    installed_files["$system_overlay_dir/$image_filename"]=1
    image_filename="$overlay_title-lightgun.png"
  fi

  # Create overlay config
  local overlay_config_path="$system_overlay_dir/$overlay_title.cfg"
  create_overlay_config "$overlay_config_path" "$image_filename"
  installed_files["$system_overlay_dir/$overlay_title.cfg"]=1
  installed_files["$system_overlay_dir/$image_filename"]=1
}

# Install a retroarch configuration for the given rom to one of the default
# overlays (horizontal, vertical, or lightgun)
# 
# A configuration will only be created if the overlay is vertical or lightgun.
# Otherwise, the default for the system will be automatically used by retroarch.
__create_default_retroarch_config() {
  local rom_name=$1
  local emulator=$2
  local orientation=$3
  local is_lightgun=$4

  if [ "$supports_vertical_overlays" == 'true' ] && [ "$orientation" == 'vertical' ]; then
    # Vertical format
    __create_retroarch_config "$rom_name" "$emulator" "$retroarch_overlay_dir/$system-vertical.cfg"
  elif [ "$enable_lightgun_borders" == 'true' ] && [ "$is_lightgun" == 'true' ]; then
    # Lightgun format
    __create_retroarch_config "$rom_name" "$emulator" "$retroarch_overlay_dir/$system-lightgun.cfg"
  fi
}

# Installs a retroarch configuration for the given rom to a specific overlay configuration
__create_retroarch_config() {
  local rom_name=$1
  local emulator=$2
  local overlay_config_path=$3
  local library_name=${emulators["$emulator/library_name"]}
  local emulator_config_dir="$retroarch_config_dir/$library_name"

  mkdir -pv "$emulator_config_dir"

  # Link emulator/rom retroarch config to overlay config
  echo "Linking $emulator_config_dir/$rom_name.cfg to overlay $overlay_config_path"
  touch "$emulator_config_dir/$rom_name.cfg"
  crudini --set "$emulator_config_dir/$rom_name.cfg" '' 'input_overlay' "\"$overlay_config_path\""

  installed_files["$emulator_config_dir/$rom_name.cfg"]=1
}

# Remove overlay / retroarch configurations for roms no longer installed
__remove_unused_configs() {
  # Remove old, unused emulator retroarch configs
  while read -r library_name; do
    [ ! -d "$retroarch_config_dir/$library_name" ] && continue

    while read -r path; do
      if [ ! "${installed_files["$path"]}" ] && grep -q input_overlay "$path"; then
        # Remove the input_overlay override
        crudini --del "$path" '' input_overlay

        # Delete the file if it's now empty
        if [ ! -s "$path" ]; then
          rm -fv "$path"
        fi
      fi
    done < <(find "$retroarch_config_dir/$library_name" -name '*.cfg' -not -name "$library_name.cfg")
  done < <(get_core_library_names)

  # Remove old, unused system overlay configs
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$system_overlay_dir" -name '*.cfg')
}

restore() {
  while read -r library_name; do
    # Check if any overrides exist
    [ ! -d "$retroarch_config_dir/$library_name" ] && continue

    while read rom_config_path; do
      if grep -q input_overlay "$rom_config_path"; then
        # Remove the input_overlay override
        crudini --del "$rom_config_path" '' input_overlay

        # Delete the file if it's now empty
        if [ ! -s "$rom_config_path" ]; then
          rm -fv "$rom_config_path"
        fi
      fi
    done < <(find "$retroarch_config_dir/$library_name" -name '*.cfg' -not -name "$library_name.cfg")
  done < <(get_core_library_names)
}

vacuum() {
  if [ ! -d "$system_overlay_dir" ]; then
    # No overlays configured
    return
  fi

  # Identify valid overlay images
  declare -A installed_images
  while IFS=$'\t' read -r title group_name; do
    if [ -f "$system_overlay_dir/$title.png" ]; then
      installed_images["$system_overlay_dir/$title.png"]=1
      installed_images["$system_overlay_dir/$title-lightgun.png"]=1
    else
      installed_images["$system_overlay_dir/$group_name.png"]=1
      installed_images["$system_overlay_dir/$group_name-lightgun.png"]=1
    fi
  done < <(romkit_cache_list | jq -r '[.title, .group.name] | @tsv')

  # Generate rm commands for unused images
  while read -r path; do
    [ "${installed_images["$path"]}" ] || echo "rm -fv $(printf '%q' "$path")"
  done < <(find "$system_overlay_dir" -name '*.png')
}

remove() {
  # Remove all overlay images
  rm -rfv "$system_overlay_dir"
}

setup "${@}"
