#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  sudo apt install -y transmission-daemon
  sudo systemctl stop transmission-daemon

  json_merge "$config_dir/transmission/settings.json" '/etc/transmission-daemon/settings.json' as_sudo=true

  sudo systemctl start transmission-daemon
}

setup
