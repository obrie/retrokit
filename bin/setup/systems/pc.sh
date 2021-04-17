#!/bin/bash

set -ex

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  # Sound driver
  sudo apt install -y fluid-soundfont-gm

  # Metadata
  download "https://***REMOVED***" "$system_dir/DOSmetadata.zip"

  # Install metadata and follow steps here: https://github.com/sduensin/retropie-tools/blob/master/import-eXoDOS.txt

  # 1. Generate zip with config files
  # 2. Choose dosbox or dosbox-staging based on dosbox/dosbox-ece
  # 3. Generate config files based on above steps and https://github.com/Voljega/ExoDOSConverter
  # 4. Update config file paths to exodos
}

uninstall() {
  sudo apt remove -y fluid-soundfont-gm
}

"${@}"
