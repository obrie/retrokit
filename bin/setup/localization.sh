#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

reconfigure() {
  # Update symlinks for the timezone
  sudo timedatectl set-timezone $(cat /etc/timezone)

  # Update current session settings
  export LANG=$(cat /etc/default/locale)

  # Update based on new configurations
  sudo dpkg-reconfigure -f noninteractive tzdata
  sudo update-locale
  sudo dpkg-reconfigure -f noninteractive locales
}

install() {
  file_cp "$config_dir/localization/locale" '/etc/default/locale' as_sudo=true
  file_cp "$config_dir/localization/locale.gen" '/etc/locale.gen' as_sudo=true
  file_cp "$config_dir/localization/timezone" '/etc/timezone' as_sudo=true
  env_merge "$config_dir/localization/keyboard" '/etc/default/keyboard' as_sudo=true

  reconfigure
}

uninstall() {
  restore '/etc/default/keyboard' as_sudo=true
  restore '/etc/timezone' as_sudo=true
  restore '/etc/locale.gen' as_sudo=true
  restore '/etc/default/locale' as_sudo=true

  reconfigure
}

"${@}"
