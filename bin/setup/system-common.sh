setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$setup_dir/../common.sh"

system="${system:-$2}"
system_tmp_dir="$tmp_dir/$system"
mkdir -p "$system_tmp_dir"

# Platform configurations
retropie_system_config_dir="/opt/retropie/configs/$system"

# Retrokit configurations
system_config_dir="$app_dir/config/systems/$system"
system_settings_file="$system_config_dir/settings.json"
common_settings_file="$app_dir/config/systems/settings.json"

##############
# Settings
##############

system_setting() {
  jq -r "$1 | values" "$(conf_prepare "$system_settings_file")"
}

if [ -z $(setting ".systems | index(\"$system\")") ]; then
  echo "$system is not a valid system"
  exit 1
fi

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
    TMPDIR="$tmp_dir" python3 "$bin_dir/romkit/cli.py" $1 <(jq -s '.[0] * .[1]' "$common_settings_file" "$system_settings_file") ${@:2}
  fi
}

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run romkit once.
romkit_cache_list() {
  # Generate a unique name based on a hash of the settings file.
  # When the settings file changes, the cache file is invalidated.
  local cache_id=($(md5sum "$system_settings_file"))
  local cache_file="$system_tmp_dir/romkit-list.cache.$cache_id"

  if [ ! -s "$cache_file" ]; then
    # Remove any existing cache files
    find "$system_tmp_dir" -name "romkit-list.cache*" -exec rm -f "{}" \;

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

retroarch_base_path='/opt/retropie/configs/all/retroarch'

declare -Ag retroarch_path_defaults
retroarch_path_defaults['core_options_path']='/opt/retropie/configs/all/retroarch-core-options.cfg'
retroarch_path_defaults['cheat_database_path']="$retroarch_base_path/cheats"
retroarch_path_defaults['overlay_directory']="$retroarch_base_path/overlay"
retroarch_path_defaults['rgui_config_directory']="$retroarch_base_path/config"
retroarch_path_defaults['input_remapping_directory']="$retroarch_base_path/remaps"

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
overlays = 1

overlay0_overlay = "$overlay_filename"

overlay0_full_screen = true

overlay0_descs = 0
EOF

  if [ -f "$system_config_dir/overlay.cfg" ]; then
    crudini --merge --inplace "$path" < "$system_config_dir/overlay.cfg"
  fi
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
  
  # Coordinates
  local left=$(system_setting '.overlays.lightgun_border.offset_x // 0')
  local right="-$left"
  local top=$(system_setting '.overlays.lightgun_border.offset_y // 0')
  local bottom="-$bottom"

  python3 "$bin_dir/tools/outline-overlay.py" "$source_path" "$target_path" --left "$left" --right "$right" --width "$width" --color "$color"
}

##############
# Emulators
##############

# Load emulator info into the global variable $emulators
load_emulator_data() {
  declare -A -g emulators

  while IFS=, read -r package emulator core_name library_name is_default; do
    emulators["$emulator/emulator"]=$emulator
    emulators["$emulator/core_name"]=$core_name
    emulators["$emulator/library_name"]=$library_name

    while read -r alias_emulator; do
      emulators["$alias_emulator/emulator"]=$emulator
      emulators["$alias_emulator/core_name"]=$core_name
      emulators["$alias_emulator/library_name"]=$library_name
    done < <(system_setting ".emulators.\"$package\" | select(.aliases) | .aliases[]")

    if [ "$is_default" == "true" ]; then
      emulators['default/emulator']=$emulator
      emulators['default/core_name']=$core_name
      emulators['default/library_name']=$library_name
    fi
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | [.key, .value.name // .key, .value.core_name, .value.library_name, .value.default // false | tostring] | join(",")')
}

get_core_library_names() {
  system_setting 'select(.emulators) | .emulators[] | select(.library_name) | .library_name'
}

has_emulator() {
  if [ $(system_setting ".emulators | has(\"$1\")") == 'true' ]; then
    return 0
  else
    return 1
  fi
}

##############
# Playlists
##############

is_multidisc() {
  [[ "$1"  == *'(Disc '* ]]
}

supports_playlists() {
  [ "$(system_setting '.playlists.enabled')" == 'true' ]
}

show_discs() {
  [ "$(system_setting '.playlists.show_discs')" == 'true' ]
}

has_disc_config() {
  local rom_name=$1
  ! supports_playlists || ! is_multidisc "$rom_name" || show_discs
}

has_playlist_config() {
  local rom_name=$1
  supports_playlists && is_multidisc "$rom_name"
}

get_playlist_name() {
  local rom_name=$1
  echo "${rom_name// (Disc [0-9A-Z]*)/}"
}
