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
    local ppf_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    git clone --depth 1 https://github.com/meunierd/ppf.git "$ppf_dir"
    pushd "$ppf_dir/ppfdev/applyppf_src"

    gcc -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE  -o applyppf applyppf3_linux.c
    sudo cp applyppf /usr/local/bin

    popd
  fi
}

configure() {
  local rom_name chd_file
  while IFS=$'\t' read -r rom_name chd_file; do
    if [ ! "${patches["$rom_name"]}" ]; then
      continue
    fi

    if [ -f "$chd_file.patched" ]; then
      echo "Already applied GunCon patch to $chd_file"
      continue
    fi

    echo "Applying GunCon patch to $chd_file"
    __apply_patch "$chd_file" a
  done < <(romkit_cache_list | jq -r '[.name, .path] | @tsv')
}

restore() {
  while read patch_file; do
    local chd_file=${patch_file%.patched}

    echo "Removing GunCon patch from $chd_file"
    __apply_patch "$chd_file" u
  done < <(find "$roms_dir/$system" -name '*.chd.patched')
}

__apply_patch() {
  local original_chd_file=$1
  local command=$2

  local rom_dir=$(dirname "$original_chd_file")
  local rom_basename=${original_chd_file##*/}
  local rom_name=${rom_basename%.chd}

  local ppf_file="$rom_dir/$rom_name.ppf"
  local cue_file=$(mktemp -p "$tmp_ephemeral_dir")
  local bin_file=$(mktemp -p "$tmp_ephemeral_dir")
  local patched_chd_file=$(mktemp -p "$tmp_ephemeral_dir")

  if [ ! -s "$original_chd_file" ]; then
    echo "Aborting patch process for $original_chd_file (file is invalid)"
    return
  fi

  # Download the ppf
  download "$guncon_patch_base_url/$rom_name.ppf" "$ppf_file"

  # Extract the bin/cue so we can patch
  chdman extractcd -f -i "$original_chd_file" -o "$cue_file" -ob "$bin_file"

  # Apply the patch
  local ppf_output=$(applyppf $command "$bin_file" "$ppf_file")
  echo "$ppf_output"

  # Check if the patch was successful
  if ! echo "$ppf_output" | grep -q 'successful'; then
    # Failed to patch -- escape
    echo "Aborting patch process for $original_chd_file"
    rm -f "$cue_file" "$bin_file"
    return
  fi

  # Re-build the chd file
  chdman createcd -f -i "$cue_file" -o "$patched_chd_file"

  # Copy and mark the file as patched
  mv "$patched_chd_file" "$original_chd_file"
  if [ "$command" == 'a' ]; then
    touch "$original_chd_file.patched"
  else
    rm "$original_chd_file.patched"
  fi

  # Remove the unused files
  rm -f "$cue_file" "$bin_file"
}

remove() {
  sudo rm -fv /usr/local/bin/applyppf
}

setup "${@}"
