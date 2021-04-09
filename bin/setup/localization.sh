#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  conf_cp "$config_dir/localization/locale" '/etc/default/locale'
  conf_cp "$config_dir/localization/locale.gen" '/etc/locale.gen'
  conf_cp "$config_dir/localization/timezone" '/etc/timezone'
  env_merge "$config_dir/localization/keyboard" '/etc/default/keyboard'

  # Update based on new configurations
  sudo dpkg-reconfigure -f noninteractive tzdata
  sudo update-locale
  sudo dpkg-reconfigure -f noninteractive locales
}

setup
