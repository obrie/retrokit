#!/bin/bash

system='psx'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/psx/roms-ppf_patches'
setup_module_desc='PSX patch files to convert konami lightgun code to guncon code'

guncon_patch_base_url='https://archive.org/download/ps1-guncon-patches'

# I found that using the built-in PPF patching mechanisms in both
# lr-pcsx-rearmed and lr-duckstation did not work.  Both failed
# under difference circumstances, whereas applyppf always works.
#
# As a result, we rely on manually patching and forgetting about
# what the emulators do.

declare -A patches
patches=(
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
)

deps() {
  if [ ! `command -v applyppf` ]; then
    local ppf_path=$(mktemp -d -p "$tmp_ephemeral_dir")
    git clone --depth 1 https://github.com/meunierd/ppf.git "$ppf_path"
    pushd "$ppf_path/ppfdev/applyppf_src"

    gcc -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE  -o applyppf applyppf3_linux.c
    sudo cp applyppf /usr/local/bin

    popd
  fi
}

configure() {
  local rom_name chd_path
  while IFS=$'\t' read -r rom_name chd_path; do
    if [ ! "${patches["$rom_name"]}" ]; then
      continue
    fi

    if [ -f "$chd_path.patched" ]; then
      echo "Already applied GunCon patch to $chd_path"
      continue
    fi

    echo "Applying GunCon patch to $chd_path"
    __apply_patch "$chd_path" a
  done < <(romkit_cache_list | jq -r '[.name, .path] | @tsv')
}

restore() {
  while read patch_file; do
    local chd_path=${patch_file%.patched}

    echo "Removing GunCon patch from $chd_path"
    __apply_patch "$chd_path" u
  done < <(find "$HOME/RetroPie/roms/$system" -name '*.chd.patched')
}

__apply_patch() {
  local original_chd_path=$1
  local command=$2

  local rom_dir=$(dirname "$original_chd_path")
  local rom_filename=${original_chd_path##*/}
  local rom_name=${rom_filename%.chd}

  local ppf_path="$rom_dir/$rom_name.ppf"
  local cue_path=$(mktemp -p "$tmp_ephemeral_dir")
  local bin_path=$(mktemp -p "$tmp_ephemeral_dir")
  local patched_chd_path=$(mktemp -p "$tmp_ephemeral_dir")

  # Download the ppf
  download "$guncon_patch_base_url/$rom_name.ppf" "$ppf_path"

  # Extract the bin/cue so we can patch
  chdman extractcd -f -i "$original_chd_path" -o "$cue_path" -ob "$bin_path"

  # Apply the patch
  local ppf_output=$(applyppf $command "$bin_path" "$ppf_path")
  echo "$ppf_output"

  # Check if the patch was successful
  if ! echo "$ppf_output" | grep -q 'successful'; then
    # Failed to patch -- escape
    echo "Aborting patch process for $original_chd_path"
    rm -f "$cue_path" "$bin_path"
    return
  fi

  # Re-build the chd file
  chdman createcd -f -i "$cue_path" -o "$patched_chd_path"

  # Copy and mark the file as patched
  mv "$patched_chd_path" "$original_chd_path"
  if [ "$command" == 'a' ]; then
    touch "$original_chd_path.patched"
  else
    rm "$original_chd_path.patched"
  fi

  # Remove the unused files
  rm -f "$cue_path" "$bin_path"
}

remove() {
  sudo rm -fv /usr/local/bin/applyppf
}

setup "${@}"
