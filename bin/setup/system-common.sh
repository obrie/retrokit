setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$setup_dir/../common.sh"

export system="${system:-$2}"
export system_tmp_dir="$tmp_dir/$system"
mkdir -p "$system_tmp_dir"

# Platform configurations
export retropie_system_config_dir="$retropie_configs_dir/$system"

# retrokit configurations
export system_config_dir="$app_dir/config/systems/$system"
export system_docs_dir="$docs_dir/systems/$system"
export system_settings_file=$(generate_system_settings_file "$system")

##############
# Settings
##############

system_setting() {
  jq -r "$1 | values" "$system_settings_file"
}
export system_data_file=$(system_setting '.metadata .path')

##############
# Setup stubs
##############

check_prereqs() {
  local action=$1
  local requested_system=$2

  local system_index=$(setting ".systems | index(\"$system\")")
  if [ -z "$requested_system" ] || [ "$system" != "$requested_system" ]; then
    # No system provided on the command-line
    if [ -z "$system_index" ]; then
      # System isn't enabled -- fail soft (skip)
      return 1
    fi
  else
    # System is provided on the command-line
    if [ "$SKIP_SYSTEM_CHECK" != 'true' ] && [ -z "$system_index" ]; then
      # System is not enabled -- fail hard
      echo "$system is not an enabled system"
      exit 1
    fi
  fi
}

##############
# ROM Matching
##############

# Generates a distinct name for a cheat file so that we can consistently
# look it up based on a ROM name.
# * Lowercase
# * Exclude flags
# * Exclude unimportant characters (dashes, spaces, etc.)
normalize_rom_name() {
  local name="$1"

  # Lowercase
  name="${name,,}"

  # Remove flag modifiers
  name="${name%% \(*}"

  # Remove non-alphanumeric characters
  name="${name//[^a-z0-9]/}"

  echo "$name"
}

##############
# ROMKit
##############

romkit_cli() {
  if [ -n "$(system_setting '.roms')" ]; then
    TMPDIR="$tmp_dir" python3 "$lib_dir/romkit/cli.py" $1 "$system_settings_file" ${@:2}
  fi
}

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run romkit once.
romkit_cache_list() {
  # Generate a unique name based on a hash of the settings file.
  # When the settings file changes, the cache file is invalidated.
  local settings_cache_id=$(jq -c 'del(.metadata .path)' "$system_settings_file" | md5sum | cut -d' ' -f 1)
  local data_cache_id=$(md5sum "$system_data_file" | cut -d' ' -f 1)
  local cache_id=$(echo "$settings_cache_id$data_cache_id" | md5sum | cut -d' ' -f 1)
  local cache_file="$system_tmp_dir/romkit-list.cache.$cache_id"

  if [ ! -s "$cache_file" ]; then
    # Remove any existing cache files
    find "$system_tmp_dir" -name 'romkit-list.cache*' -exec rm -f '{}' +

    # Re-cache the list
    romkit_cli list --log-level ERROR > "$cache_file"
    if [ $? -ne 0 ]; then
      rm "$cache_file"
    fi
  fi

  cat "$cache_file"
}

##############
# Retroarch
##############

retroarch_base_dir="$retropie_configs_dir/all/retroarch"

declare -Ag retroarch_path_defaults
retroarch_path_defaults['core_options_path']="$retropie_configs_dir/all/retroarch-core-options.cfg"
retroarch_path_defaults['cheat_database_path']="$retroarch_base_dir/cheats"
retroarch_path_defaults['overlay_directory']="$retroarch_base_dir/overlay"
retroarch_path_defaults['rgui_config_directory']="$retroarch_base_dir/config"
retroarch_path_defaults['input_remapping_directory']="$retroarch_base_dir/remaps"

get_retroarch_path() {
  local config_name=$1

  local override_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' "$config_name" 2>/dev/null | tr -d '"' || true)
  if [ -n "$override_path" ]; then
    echo "$override_path"
  else
    echo "${retroarch_path_defaults["$config_name"]}"
  fi
}

##############
# Overlays
##############

# Generates a Retroarch overlay configuration at the given path with the given
# overlay image
create_overlay_config() {
  local path=$1
  local overlay_filename=$2

  echo "Overlaying $path with $overlay_filename"
  cat > "$path" <<EOF
#include "$retroarch_base_dir/overlay/base.cfg"
overlay0_overlay = "$overlay_filename"
EOF
}

# Outlines that gameplay area for an existing overlay image in order to be
# compatible with certain lightgun controllers like Sinden.
# 
# This allows us to continue to use consistent overlay sources between all
# games by just dynamically generated compatible lightgun overlays.
outline_overlay_image() {
  local source_path="$1"
  local target_path="$2"

  # Formatting
  local width=$(setting '.overlays.lightgun_border.width')
  local color=$(setting '.overlays.lightgun_border.color')
  local fill=$(setting '.overlays.lightgun_border.fill')
  local brightness=$(setting '.overlays.lightgun_border.brightness // 1.0')
  
  # Coordinates
  local left=$(system_setting '.overlays.lightgun_border.offset_x // 0')
  local right="-$left"
  local top=$(system_setting '.overlays.lightgun_border.offset_y // 0')
  local bottom="-$top"

  python3 "$bin_dir/tools/outline-overlay.py" "$source_path" "$target_path" \
    --left "$left" --right "$right" --top "$top" --bottom "$bottom" --width "$width" \
    --color "$color" --fill "${fill:-true}" --brightness "$brightness"
}

##############
# Emulators
##############

# Load emulator info into the global variable $emulators
load_emulator_data() {
  declare -A -g emulators

  while IFS=» read -r package core_name core_option_prefix library_name is_default supports_overlays emulator_names alias_names; do
    IFS=',' read -r -a emulator_names <<< "$emulator_names"
    IFS=',' read -r -a alias_names <<< "$alias_names"
    local default_emulator=${emulator_names[0]}

    for emulator in "${emulator_names[@]}"; do
      emulators["$emulator/emulator"]=$emulator
      emulators["$emulator/core_name"]=$core_name
      emulators["$emulator/core_option_prefix"]=$core_option_prefix
      emulators["$emulator/library_name"]=$library_name
      emulators["$emulator/supports_overlays"]=$supports_overlays
    done

    for alias_emulator in "${alias_names[@]}"; do
      emulators["$alias_emulator/emulator"]=$default_emulator
      emulators["$alias_emulator/core_name"]=$core_name
      emulators["$alias_emulator/core_option_prefix"]=$core_option_prefix
      emulators["$alias_emulator/library_name"]=$library_name
      emulators["$alias_emulator/supports_overlays"]=$supports_overlays
    done

    if [ "$is_default" == "true" ]; then
      emulators['default/emulator']=$default_emulator
      emulators['default/core_name']=$core_name
      emulators['default/core_option_prefix']=$core_option_prefix
      emulators['default/library_name']=$library_name
      emulators["default/supports_overlays"]=$supports_overlays
    fi
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] |
    [
      .key,
      .value.core_name,
      .value.core_option_prefix // .value.core_name,
      .value.library_name,
      (.value.default // false | tostring),
      (.value.supports_overlays // false | tostring),
      (.value.names // [.key] | join(",")),
      (select(.value.aliases) | .value.aliases | join(","))
    ] | join("»")
  ')
}

get_core_library_names() {
  system_setting 'select(.emulators) | .emulators[] | select(.library_name) | .library_name'
}

has_libretro_cores() {
  local libretro_cores=$(get_core_library_names)
  [ -n "$libretro_cores" ]
}

has_emulator() {
  local emulator=$1
  local result=$(system_setting "select(.emulators) | (.emulators | keys) + ([.emulators | values[] | select(.name) | .name]) + ([.emulators | values[] | .aliases | select(.)] | flatten) | any(. == \"$emulator\")")
  if [ "$result" == 'true' ]; then
    return 0
  else
    return 1
  fi
}

##############
# Controls
##############

# Gets the primary control used from a list of controls.
get_primary_control() {
  local controls=$1

  for name in lightgun trackball pedal dial paddle keyboard; do
    if [[ "$controls" == *$name* ]]; then
      echo $name
      return
    fi
  done
}
