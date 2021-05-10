set -ex

setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$setup_dir/../common.sh"

system="${system:-$2}"
system_tmp_dir="$tmp_dir/$system"

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
  TMPDIR="$tmp_dir" python3 bin/romkit/cli.py $1 "$system_settings_file" ${@:2}
}

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run romkit once.
romkit_cache_list() {
  local cache_file="$system_tmp_dir/romkit-list.cache"

  # If the settings file has been modified recently, look up the
  # list again and re-cache it.
  if [ "$system_settings_file" -nt "$cache_file" ]; then
    romkit_cli list --log-level ERROR > "$cache_file"
    touch -r "$system_settings_file" "$cache_file"
  fi

  cat "$cache_file"
}

##############
# Overlays
##############

create_overlay_config() {
  local path=$1
  local overlay_filename=$2

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

  while IFS="$tab" read emulator core_name library_name is_default; do
    emulators["$emulator/core_name"]=$core_name
    emulators["$emulator/library_name"]=$library_name

    if [ "$is_default" == "true" ]; then
      emulators['default']=$emulator
      emulators['default/core_name']=$core_name
      emulators['default/library_name']=$library_name
    fi
  done < <(system_setting '.emulators | to_entries[] | select(.value.core_name) | [.key, .value.core_name, .value.library_name, .value.default // false] | @tsv')
}
