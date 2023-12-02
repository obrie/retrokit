#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/pc/soundfonts'
setup_module_desc='PC emulator soundfont installation'

build() {
  # Default soundfont
  sudo apt-get install -y fluid-soundfont-gm

  # MT-32 soundfont (used by eXoDOS)
  local mt32_soundfont_file="$retropie_system_config_dir/soundfonts/mt32/SoundCanvas.sf2"
  if [ ! -f "$mt32_soundfont_file" ]; then
    download 'https://archive.org/download/sc-55/SC-55.sf2' "$mt32_soundfont_file"
  fi
}

remove() {
  rm -fv "$retropie_system_config_dir/soundfonts/SoundCanvas.sf2"

  sudo apt-get remove -y fluid-soundfont-gm
  sudo apt-get autoremove --purge -y
}

setup "${@}"
