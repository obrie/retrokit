#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

call_github_api() {
  local url=$1
  local path=$2
  download "$url" "$path" auth_token="$GITHUB_API_KEY"
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
  # Check if we're actually installing overlays
  if [ -z "$(system_setting '.overlays.repos')" ]; then
    echo 'No overlays configured'
    return
  fi

  # Load emulator data
  load_emulator_data

  # The directory to which we'll install the configurations and images
  local overlays_dir="$retroarch_config_dir/overlay/$system"
  mkdir -pv "$overlays_dir"

  # Track whether this system supports vertical overlays
  local supports_vertical_overlays=false

  # Get the list of overlay images available in each repo
  echo "Loading list of available overlays..."
  declare -A overlay_urls
  while IFS='^' read repo branch rom_images_path vertical_image_path ; do
    branch=${branch:-master}
    if [ -n "$vertical_image_path" ]; then
      supports_vertical_overlays=true
    fi

    local github_tree_path="$system_tmp_dir/$repo.list"
    if [ ! -f "$github_tree_path" ]; then
      # Get the Tree SHA for the directory storing the images
      local parent_tree_path=$(dirname "$rom_images_path")
      local sub_tree_name=$(basename "$rom_images_path")
      local tree_sha=$(call_github_api "https://api.github.com/repos/$repo/contents/$parent_tree_path?ref=$branch" | jq -r ".[] | select(.name == \"$sub_tree_name\") | .sha")

      # Get the list of files at that sub-tree
      call_github_api "https://api.github.com/repos/$repo/git/trees/$tree_sha" "$github_tree_path"
    fi

    while IFS="$tab" read rom_name encoded_rom_name ; do
      # Generate a unique identifier for this rom
      local rom_id=$(normalize_rom_name "$rom_name")

      if [ -z "${overlay_urls["$rom_id"]}" ]; then
        overlay_urls["$rom_id"]="https://github.com/$repo/raw/$branch/$rom_images_path/$encoded_rom_name.png"
      fi
    done < <(jq -r '.tree[].path | select(. | contains(".png")) | split("/")[-1] | sub("\\.png$"; "") | [(. | @text), (. | @uri)] | @tsv' "$github_tree_path" | sort | uniq)
  done < <(system_setting '.overlays.repos[] | [.repo, .branch, .path, .vertical] | join("^")')

  # Download overlays for installed roms and their associated emulator according
  # to romkit
  declare -A installed_files
  while IFS='^' read rom_name parent_name emulator orientation; do
    local group_name=${parent_name:-$rom_name}
    emulator=${emulator:-default}

    # Use the default emulator if one isn't specified
    local library_name=${emulators["$emulator/library_name"]}

    # Make sure this is a libretro core
    if [ -z "$library_name" ]; then
      continue
    fi

    # Create directory storing the emulator configuration
    local emulator_config_dir="$retroarch_config_dir/config/$library_name"
    mkdir -pv "$emulator_config_dir"

    # Look up either by the current rom or the parent rom
    local url=${overlay_urls[$(normalize_rom_name "$rom_name")]:-${overlay_urls[$(normalize_rom_name "$group_name")]}}
    if [ -z "$url" ]; then
      echo "[$rom_name] No overlay available"

      # Handle Vertical configurations
      if [ "$supports_vertical_overlays" == 'true' ] && [ "$orientation" == 'vertical' ]; then
        # Link emulator/rom retroarch config to system vertical overlay config
        installed_files["$emulator_config_dir/$rom_name.cfg"]=1
        cat > "$emulator_config_dir/$rom_name.cfg" <<EOF
input_overlay = "$retroarch_config_dir/overlay/$system-vertical.cfg"
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

    installed_files["$emulator_config_dir/$rom_name.cfg"]=1
    installed_files["$overlays_dir/$rom_name.cfg"]=1
    installed_files["$overlays_dir/$image_filename"]=1
  done < <(romkit_cache_list | jq -r '[.name, .parent, .emulator, .orientation] | join("^")')

  # Remove old, unused emulator overlay configs
  while read library_name; do
    [ ! -d "$retroarch_config_dir/config/$library_name" ] && continue

    while read path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$retroarch_config_dir/config/$library_name" -name '*.cfg')
  done < <(get_core_library_names)

  # Remove old, unused system overlay configs
  while read path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$overlays_dir" -name '*.cfg' -o -name '*.png')
}

uninstall() {
  echo "Deleting $retroarch_config_dir/overlay/$system"
  rm -rfv "$retroarch_config_dir/overlay/$system"
}

"$1" "${@:3}"
