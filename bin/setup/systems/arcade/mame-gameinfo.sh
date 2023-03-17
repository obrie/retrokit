#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-gameinfo'
setup_module_desc='Game information support for MAME (command / gameinit)'

command_dat_home='https://www.progettosnaps.net/command/'
command_dat_url='https://www.progettosnaps.net/download/?tipo=command&file={filename}'

gameinit_dat_home='https://www.progettosnaps.net/gameinit/'
gameinit_dat_url='https://www.progettosnaps.net/download/?tipo=gameinit&file={filename}'

build() {
  __build_mame2016
  __build_mame0222
  __build_mame0244
  __build_mame
}

__build_mame2016() {
  if has_libretro_core 'mame2016'; then
    # Newer versions of command.dat break on lr-mame2016.  This is the newest
    # version of the file that I could find which doesn't break the emulator.
    download 'https://archive.org/download/shmupmame-4.2-mameplus-0.148-extras/SHMUPMAME_4.2_MAMEPLUS_0.148_EXTRAS.zip/command.dat' "$bios_dir/mame2016/history/command.dat"

    __download_gameinit_dat "$bios_dir/mame2016/history/gameinit.dat"
  fi
}

__build_mame0222() {
  if has_emulator 'lr-mame0222'; then
    __download_command_dat "$bios_dir/mame0222/history/command.dat"
    __download_gameinit_dat "$bios_dir/mame0222/history/gameinit.dat"
  fi
}

__build_mame0244() {
  if has_emulator 'lr-mame0244'; then
    __download_command_dat "$bios_dir/mame0244/history/command.dat"
    __download_gameinit_dat "$bios_dir/mame0244/history/gameinit.dat"
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    __download_command_dat "$bios_dir/mame/history/command.dat"
    __download_gameinit_dat "$bios_dir/mame/history/gameinit.dat"
  fi
}

# Looks for the latest version of command.dat and downloads it
__download_command_dat() {
  local target_file=$1
  if [ -f "$target_file" ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo "Already installed command.dat ($target_file)"
    return
  fi

  local filename=$(download "$command_dat_home" | grep -oE 'pS_Command_[0-9]+.zip')
  if [ -z "$filename" ]; then
    echo '[WARN] Unable to scrape command.dat filename'
    return 1
  fi

  local url=$(render_template "$command_dat_url" filename="$filename")
  local archive_file=$(mktemp -p "$tmp_ephemeral_dir")
  download "$url" "$archive_file"

  local extract_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  unzip -ojq "$archive_file" 'dats/command.dat' -d "$extract_dir/"
  file_cp "$extract_dir/command.dat" "$target_file" backup=false envsubst=false
}

# Looks for the latest version of gameinit.dat and downloads it
__download_gameinit_dat() {
  local target_file=$1
  if [ -f "$target_file" ] && [ "$FORCE_UPDATE" != 'true' ]; then
    echo "Already installed gameinit.dat ($target_file)"
    return
  fi

  local filename=$(download "$gameinit_dat_home" | grep -oE 'pS_gameinit_[0-9]+.zip')
  if [ -z "$filename" ]; then
    echo '[WARN] Unable to scrape gameinit.dat filename'
    return 1
  fi

  local url=$(render_template "$gameinit_dat_url" filename="$filename")
  local archive_file=$(mktemp -p "$tmp_ephemeral_dir")
  download "$url" "$archive_file"

  local extract_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  unzip -ojq "$archive_file" 'dats/gameinit.dat' -d "$extract_dir/"
  file_cp "$extract_dir/gameinit.dat" "$target_file" backup=false envsubst=false
}

remove() {
  rm -fv \
    "$bios_dir/mame2016/history/command.dat" \
    "$bios_dir/mame2016/history/gameinit.dat" \
    "$bios_dir/mame0222/history/command.dat" \
    "$bios_dir/mame0222/history/gameinit.dat" \
    "$bios_dir/mame0244/history/command.dat" \
    "$bios_dir/mame0244/history/gameinit.dat" \
    "$bios_dir/mame/history/command.dat" \
    "$bios_dir/mame/history/gameinit.dat"
}

setup "${@}"
