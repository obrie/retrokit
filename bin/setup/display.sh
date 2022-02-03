#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

update_console() {
  sudo /etc/init.d/console-setup.sh restart

  if [ "$(tty | grep -E '/dev/tty[1-6]')" == '' ]; then
    sudo setupcon -f --force
  fi
}

install() {
  env_merge "$config_dir/display/console-setup" '/etc/default/console-setup' as_sudo=true
  update_console
}

uninstall() {
  restore_file '/etc/default/console-setup' as_sudo=true delete_src=true
  update_console
}

"${@}"
