#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

configure() {
  file_cp "$config_dir/localization/locale" '/etc/default/locale' as_sudo=true
  file_cp "$config_dir/localization/locale.gen" '/etc/locale.gen' as_sudo=true
  file_cp "$config_dir/localization/timezone" '/etc/timezone' as_sudo=true
  env_merge "$config_dir/localization/keyboard" '/etc/default/keyboard' as_sudo=true

  __reconfigure_packages
}

restore() {
  restore_file '/etc/default/keyboard' as_sudo=true delete_src=true
  restore_file '/etc/timezone' as_sudo=true delete_src=true
  restore_file '/etc/locale.gen' as_sudo=true delete_src=true
  restore_file '/etc/default/locale' as_sudo=true delete_src=true

  __reconfigure_packages
}

__reconfigure_packages() {
  # Update symlinks for the timezone
  sudo timedatectl set-timezone $(cat /etc/timezone)

  # Update current session settings
  export $(grep -v '^#' /etc/default/locale | xargs)

  # Update based on new configurations
  sudo dpkg-reconfigure -f noninteractive locales
  sudo update-locale
  sudo dpkg-reconfigure -f noninteractive tzdata

  # Reload the console
  if [ "$(tty | grep -E '/dev/tty[1-6]')" == '' ]; then
    sudo setupcon -f --force
  fi
}

"${@}"
