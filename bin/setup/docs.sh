#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='docs'
setup_module_desc='Documentation builder for Retrokit'

deps() {
  sudo apt-get install -y pandoc chromium

  sudo pip3 install jinja2-cli
}

remove() {
  sudo pip3 remove jinja2-cli
}

setup "${@}"
