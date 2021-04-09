#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  env_merge "$config_dir/display/console-setup" '/etc/default/console-setup' as_sudo=true
}

uninstall() {
  restore '/etc/default/console-setup'
}

"${@}"
