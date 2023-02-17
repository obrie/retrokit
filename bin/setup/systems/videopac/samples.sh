#!/bin/bash

system='videopac'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/videopac/samples'
setup_module_desc='Voice Samples for Videopac/Odyssey'

build() {
  mkdir -p "$HOME/RetroPie/BIOS/voice"

  __build_common_samples
  __build_sid_the_spellbinder_samples
}

# Samples common to multiple games
__build_common_samples() {
  local url='http://o2em.sourceforge.net/files/o2mainsamp.zip'

  if [ ! -f "$HOME/RetroPie/BIOS/voice/E4BB.WAV" ] || [ "$FORCE_UPDATE" == 'true' ]; then
    local sample_archive_path=$(mktemp -p "$tmp_ephemeral_dir")
    download "$url" "$sample_archive_path"
    unzip -jo "$sample_archive_path" -d "$HOME/RetroPie/BIOS/voice/"
  else
    echo "Already downloaded $url"
  fi
}

# Samples specific to Sid the Spellbinder
__build_sid_the_spellbinder_samples() {
  local machine=$(romkit_cache_list | jq 'select(.title == "Sid the Spellbinder")')
  local url='http://o2em.sourceforge.net/files/sidsamp.zip'

  if [ -n "$machine" ]; then
    if [ ! -f "$HOME/RetroPie/BIOS/voice/EE80.WAV" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local sample_archive_path=$(mktemp -p "$tmp_ephemeral_dir")
      download "$url" "$sample_archive_path"
      unzip -jo "$sample_archive_path" -d "$HOME/RetroPie/BIOS/voice/"
    else
      echo "Already downloaded $url"
    fi
  fi
}

remove() {
  rm -rf "$HOME/RetroPie/BIOS/voice"
}

setup "${@}"
