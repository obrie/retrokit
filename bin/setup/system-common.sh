setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$setup_dir/../common.sh"

system="${system:-$2}"
system_tmp_dir="$tmp_dir/$system"
mkdir -p "$system_tmp_dir"

# Platform configurations
retropie_system_config_dir="/opt/retropie/configs/$system"
retroarch_config_dir="/opt/retropie/configs/all/retroarch"

# Retrokit configurations
system_config_dir="$app_dir/config/systems/$system"
system_settings_file="$system_config_dir/settings.json"

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
    TMPDIR="$tmp_dir" python3 "$bin_dir/romkit/cli.py" $1 "$system_settings_file" ${@:2}
  fi
}

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run romkit once.
romkit_cache_list() {
  # Generate a unique name based on a hash of the settings file.
  # When the settings file changes, the cache file is invalidated.
  local cache_id=($(md5sum "$system_settings_file"))
  local cache_file="$system_tmp_dir/romkit-list.cache.$cache_id"

  if [ ! -f "$cache_file" ]; then
    # Remove any existing cache files
    find "$system_tmp_dir" -name "romkit-list.cache*" -exec rm -f "{}" \;

    # Re-cache the list
    romkit_cli list --log-level ERROR > "$cache_file"
  fi

  cat "$cache_file"
}

##############
# Overlays
##############

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
}

##############
# Emulators
##############

# Load emulator info into the global variable $emulators
load_emulator_data() {
  declare -A -g emulators

  while IFS=',' read package emulator core_name library_name is_default; do
    emulators["$emulator/emulator"]=$emulator
    emulators["$emulator/core_name"]=$core_name
    emulators["$emulator/library_name"]=$library_name

    while read alias_emulator; do
      emulators["$alias_emulator/emulator"]=$emulator
      emulators["$alias_emulator/core_name"]=$core_name
      emulators["$alias_emulator/library_name"]=$library_name
    done < <(system_setting ".emulators.\"$package\" | select(.aliases) | .aliases[]")

    if [ "$is_default" == "true" ]; then
      emulators['default/emulator']=$emulator
      emulators['default/core_name']=$core_name
      emulators['default/library_name']=$library_name
    fi
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | [.key, .value.name // .key, .value.core_name, .value.library_name, .value.default // false] | @tsv' | tr "$tab" ',')
}
