#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

alias install=configure
alias uninstall=restore

configure() {
  env_merge "$config_dir/display/console-setup" '/etc/default/console-setup' as_sudo=true
  __update_console
}

restore() {
  restore_file '/etc/default/console-setup' as_sudo=true delete_src=true
  __update_console
}

__update_console() {
  sudo /etc/init.d/console-setup.sh restart

  if [ "$(tty | grep -E '/dev/tty[1-6]')" == '' ]; then
    sudo setupcon -f --force
  fi
}

"${@}"
