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
