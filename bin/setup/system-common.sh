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
# ROMKit
##############

romkit_cli() {
  TMPDIR="$tmp_dir" python3 bin/romkit/cli.py $1 "$system_settings_file" ${@:2}
}
