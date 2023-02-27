#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='docs'
setup_module_desc='Documentation builder for retrokit'

depends() {
  sudo apt-get install -y chromium fonts-roboto fonts-noto-color-emoji

  sudo pip3 install jinja2-cli~=0.8.2
}

remove() {
  command -v pip3 >/dev/null && sudo pip3 uninstall -y jinja2-cli
}

setup "${@}"
