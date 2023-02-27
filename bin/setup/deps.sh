#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='deps'
setup_module_desc='retrokit common system dependencies'

depends() {
  # PIP
  sudo apt-get install -y python3-pip

  # Ini editor
  sudo pip3 install crudini~=0.9.3

  # Env editor
  dotenv_version=d71c9d786fe193f43f1cb57c6b4a152ebb01ba60
  local current_dotenv_version=$(cat /usr/local/etc/dotenv.version 2>/dev/null || true)
  if [ ! `command -v dotenv` ] || [ "$current_dotenv_version" != "$dotenv_version" ]; then
    download "https://raw.githubusercontent.com/bashup/dotenv/$dotenv_version/dotenv" '/usr/local/bin/dotenv' as_sudo=true force=true
    chmod +x /usr/local/bin/dotenv
    echo "$dotenv_version" | sudo tee /usr/local/etc/dotenv.version
  fi

  # JSON reader
  sudo apt-get install -y jq

  # Video editor
  sudo apt-get install -y ffmpeg

  # Image editor
  sudo pip3 install pillow~=9.0
}

remove() {
  sudo rm -fv /usr/local/bin/dotenv /usr/local/etc/dotenv.version
  command -v pip3 >/dev/null && sudo pip3 uninstall -y crudini pillow
  sudo apt-get remove -y ffmpeg jq python3-pip
  sudo apt-get autoremove --purge -y
}

setup "${@}"
