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
clean_rom_name() {
  local name="$1"
  name="${name,,}"
  name="${name%% \(*}"
  name="${name//[^a-zA-Z0-9]/}"
  echo "$name"
}

##############
# ROMKit
##############

romkit_cli() {
  TMPDIR="$tmp_dir" python3 bin/romkit/cli.py $1 "$system_settings_file" ${@:2}
}

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run once.
# 
# TODO: It would be nice to have another level of cache on top of this
romkit_cache_list() {
  if [ -z "$rom_install_list" ]; then
    rom_install_list=$(romkit_cli list --log-level ERROR)
  fi

  echo "$rom_install_list"
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
load_emulators() {
  declare -A emulators

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
