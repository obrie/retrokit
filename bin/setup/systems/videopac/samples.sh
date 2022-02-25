#!/bin/bash

system='videopac'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/videopac/samples'
setup_module_desc='Voice Samples for Videopac/Odyssey'

build() {
  download 'http://o2em.sourceforge.net/files/o2mainsamp.zip' "$tmp_ephemeral_dir/o2mainsamp.zip"
  download 'http://o2em.sourceforge.net/files/sidsamp.zip' "$tmp_ephemeral_dir/sidsamp.zip"

  mkdir -p "$HOME/RetroPie/BIOS/voice"

  unzip -j "$tmp_ephemeral_dir/o2mainsamp.zip" -d "$HOME/RetroPie/BIOS/voice/"
  unzip -j "$tmp_ephemeral_dir/sidsamp.zip" -d "$HOME/RetroPie/BIOS/voice/"
}

remove() {
  rm -rf "$HOME/RetroPie/BIOS/voice"
}

setup "${@}"
