#!/bin/bash

system='psx'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/psx/guncon_conversions'
setup_module_desc='PSX patch files to convert konami lightgun code to guncon code'

guncon_patch_base_url='https://archive.org/download/ps1-guncon-patches'

# I found that using the built-in PPF patching mechanisms in both
# lr-pcsx-rearmed and lr-duckstation did not work.  Both failed
# under difference circumstances, whereas applyppf always works.
#
# As a result, we rely on manually patching and forgetting about
# what the emulators do.

declare -A ppf
ppf=(
  ['Crypt Killer (USA)']=1
  ['Die Hard Trilogy (Europe) (En,Fr,De,Es,It,Sv)']=1
  ['Die Hard Trilogy (USA) (Rev 1)']=1
  ['Horned Owl (Japan)']=1
  ['Lethal Enforcers (Europe)']=1
  ['Lethal Enforcers I & II (USA)']=1
  ['Policenauts (Japan) (Disc 1)']=1
  ['Policenauts (Japan) (Disc 2)']=1
  ['Project - Horned Owl (USA)']=1
  ['Star Wars - Rebel Assault II - The Hidden Empire (USA) (Disc 1)']=1
  ['Star Wars - Rebel Assault II - The Hidden Empire (USA) (Disc 2)']=1
)

deps() {
  if [ ! `command -v applyppf` ]; then
    git clone --depth 1 https://github.com/meunierd/ppf.git "$tmp_ephemeral_dir/nibtools"
    pushd "$tmp_ephemeral_dir/ppf/ppfdev/applyppf_src"

    gcc -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE  -o applyppf applyppf3_linux.c
    sudo cp applyppf /usr/local/bin

    popd
  fi
}

configure() {
  while IFS=$'\t' read -r rom_name chd_path; do
    if [ ! "${patches[$rom_name]}" ] || [ -f "$path.patched" ]; then
      continue
    fi

    __apply_patch "$chd_path" a
  done < <(romkit_cache_list | jq -r '[.name, .path] | @tsv')
}

restore() {
  while read patch_file; do
    local chd_path=${patch_file%.patched}
    __apply_patch "$chd_path" u
  done < <(find "$HOME/RetroPie/roms/$system" -name '*.chd.patched')
}

__apply_patch() {
  local chd_path=$1
  local command=$2

  local rom_dir=$(dirname "$chd_path")
  local ppf_path="$rom_dir/$rom_name.ppf"
  local cue_path="$tmp_ephemeral_dir/$rom_name.cue"
  local bin_path="$tmp_ephemeral_dir/$rom_name.bin"
  local patched_chd_path="$tmp_ephemeral_dir/$rom_name.chd"

  # Download the ppf
  download "$guncon_patch_base_url/$rom_name.ppf" "$ppf_path"

  # Extract the bin/cue so we can patch
  chdman extractcd -i "$path" -o "$cue_path" -ob "$bin_path"

  # Apply the patch
  applyppf $command "$ppf_path" "$bin_path"

  # Re-build the chd file
  chdman createcd -i "$cue_path" -o "$patched_chd_path"

  # Copy and mark the file as patched
  mv "$patched_chd_path" "$path"
  if [ "$command" == 'a' ]; then
    touch "$path.patched"
  else
    rm "$path.patched"
  fi

  # Remove the unused files
  rm -f "$cue_path" "$bin_path"
}

remove() {
  sudo rm -fv /usr/local/bin/applyppf
}

setup "${@}"
