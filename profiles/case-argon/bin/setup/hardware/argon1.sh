#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/argon1'
setup_module_desc='Argon1 management utilities'

build() {
  if [ ! `command -v argonone-uninstall` ]; then
    local argon_bin="$tmp_ephemeral_dir/argon1.sh"
    download 'https://download.argon40.com/argon1.sh' "$argon_bin"
    bash "$argon_bin"
    rm -v "$argon_bin"
  else
    echo 'argoneone scripts are already installed'
  fi
}

configure() {
  backup_and_restore '/usr/bin/argononed.py' as_sudo=true

  # Disable power management since it's handled by powerkit
  sudo sed -i 's/^\tt1/\t#t1/g' /usr/bin/argononed.py
}

restore() {
  restore_file '/usr/bin/argononed.py' as_sudo=true delete_src=true
}

remove() {
  if [ `command -v argonone-uninstall` ]; then
    echo 'Y' | argonone-uninstall
  fi
}

setup "${@}"
