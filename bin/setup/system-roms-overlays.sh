#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

create_overlay_config() {
  local path=$1
  local overlay_filename=$2

  cat > "$path" <<EOF
overlays = 1

overlay0_overlay = $overlay_filename

overlay0_full_screen = true

overlay0_descs = 0
EOF
}

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
install() {
  # BezelProject github repos
  local bezelproject_theme=$(system_setting '.themes.bezel')
  if [ -z "$bezelproject_theme" ]; then
    return
  fi
  local bezelproject_repos=("bezelproject-$bezelproject_theme" "bezelprojectsa-$bezelproject_theme")
  
  # Path to rom-specific overlays
  local bezelproject_overlay_path="overlay/GameBezels/$bezelproject_theme"
  if [ "$system" == 'arcade' ]; then
    # Arcade override for unknown reasons
    bezelproject_overlay_path='overlay/ArcadeBezels'
  fi

  # The directory to which we'll install the configurations and images
  local overlays_dir="$retroarch_config_dir/$bezelproject_overlay_path"
  mkdir -p "$overlays_dir"

  # Map emulator to library name
  local default_emulator=''
  declare -A emulators
  while IFS="$tab" read emulator library_name is_default; do
    emulators["$emulator/library_name"]=$library_name

    if [ "$is_default" == "true" ]; then
      default_emulator=$emulator
    fi
  done < <(system_setting '.emulators | to_entries[] | select(.value.library_name) | [.key, .value.library_name, .value.default // false] | @tsv')

  # Copy over the default system overlay
  local system_config_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_overlay' | tr -d '"')
  local system_config_dir=$(dirname "$system_config_path")
  local system_image_filename="$(basename "$system_config_path" .cfg).png"
  download "https://github.com/thebezelproject/bezelproject-$bezelproject_theme/raw/master/retroarch/overlay/$system_image_filename" "$system_config_dir/$system_image_filename"
  create_overlay_config "$system_config_path" "$system_image_filename"

  # Arcade: Special handling for Vertical config
  if [ "$system" == 'arcade' ]; then
    download "https://github.com/thebezelproject/bezelproject-$bezelproject_theme/raw/master/retroarch/overlay/MAME-Vertical.png" "$system_config_dir/MAME-Vertical.png"
    create_overlay_config "$system_config_dir/MAME-Vertical.cfg" "MAME-Vertical.png"
  fi

  # Get the list of overlay images available
  echo "Loading list of available overlays..."
  declare -A overlay_urls
  for repo in "${bezelproject_repos[@]}"; do
    local github_tree_path="$system_tmp_dir/$repo.list"
    if [ ! -f "$github_tree_path" ]; then
      # Get the Tree SHA for the directory storing the images
      local parent_tree_path=$(dirname "$bezelproject_overlay_path")
      local sub_tree_name=$(basename "$bezelproject_overlay_path")
      local tree_sha=$(curl -s "https://api.github.com/repos/thebezelproject/$repo/contents/retroarch/$parent_tree_path" | jq -r ".[] | select(.name == \"$sub_tree_name\") | .sha")

      # Get the list of files at that sub-tree
      download "https://api.github.com/repos/thebezelproject/$repo/git/trees/$tree_sha" "$github_tree_path"
    fi

    while IFS="$tab" read rom_name encoded_rom_name ; do
      # Generate a unique identifier for this rom
      local rom_id=$(clean_rom_name "$rom_name")

      if [ -z "${overlay_urls["$rom_id"]}" ]; then
        overlay_urls["$rom_id"]="https://github.com/thebezelproject/$repo/raw/master/retroarch/$bezelproject_overlay_path/$encoded_rom_name.png"
      fi
    done < <(jq -r '.tree[].path | select(. | contains(".png")) | split("/")[-1] | sub("\\.png$"; "") | [(. | @text), (. | @uri)] | @tsv' "$github_tree_path" | sort | uniq)
  done

  # Download overlays for installed roms and their associated emulator according
  # to romkit
  while IFS='^' read rom_name parent_name emulator orientation; do
    local group_name=${parent_name:-$rom_name}

    # Use the default emulator if one isn't specified
    if [ -z "$emulator" ]; then
      emulator=$default_emulator
    fi
    local library_name=${emulators["$emulator/library_name"]}

    # Make sure this is a libretro core
    if [ -z "$library_name" ]; then
      continue
    fi

    # Create directory storing the emulator configuration
    local emulator_config_dir="$retroarch_config_dir/config/$library_name"
    mkdir -p "$emulator_config_dir"

    # Look up either by the current rom or the parent rom
    local url=${overlay_urls[$(clean_rom_name "$rom_name")]:-${overlay_urls[$(clean_rom_name "$group_name")]}}
    if [ -z "$url" ]; then
      echo "[$rom_name] No overlay available"

      # Arcade: Handle Vertical configurations
      if [ "$system" == 'arcade' ] && [ "$orientation" == 'vertical' ]; then
        # Link emulator/rom retroarch config to system vertical overlay config
        cat > "$emulator_config_dir/$rom_name.cfg" <<EOF
input_overlay = "/opt/retropie/configs/all/retroarch/overlay/MAME-Vertical.cfg"
EOF
      fi

      continue
    fi

    # We have an image: download it
    local image_filename="$group_name.png"
    download "$url" "$overlays_dir/$image_filename"

    # Create overlay config
    local overlay_config_path="$overlays_dir/$rom_name.cfg"
    create_overlay_config "$overlay_config_path" "$image_filename"

    # Link emulator/rom retroarch config to overlay config
    cat > "$emulator_config_dir/$rom_name.cfg" <<EOF
input_overlay = "$overlay_config_path"
EOF
  done < <(romkit_cache_list | jq -r '[.name, .parent, .emulator, .orientation] | @tsv' | tr "$tab" "^")
}

uninstall() {
  echo 'No uninstall for overlays'
}

"$1" "${@:3}"
