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
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    # Newer versions of command.dat break on lr-mame2016.  This is the newest
    # version of the file that I could find which doesn't break the emulator.
    download 'https://archive.org/download/shmupmame-4.2-mameplus-0.148-extras/SHMUPMAME_4.2_MAMEPLUS_0.148_EXTRAS.zip/command.dat' "$HOME/RetroPie/BIOS/mame2016/history/command.dat"

    if [ ! -f "$HOME/RetroPie/BIOS/mame2016/history/gameinit.dat" ]  || [ "$FORCE_UPDATE" == 'true' ]; then
      __download_gameinit_dat
      file_cp "$tmp_ephemeral_dir/gameinit.dat" "$HOME/RetroPie/BIOS/mame2016/history/gameinit.dat" backup=false envsubst=false
    else
      echo "Already installed gameinit.dat (lr-mame2016)"
    fi
  fi
}

__build_mame0222() {
  if has_emulator 'lr-mame0222'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame0222/history/command.dat" ]  || [ "$FORCE_UPDATE" == 'true' ]; then
      __download_command_dat
      file_cp "$tmp_ephemeral_dir/command.dat" "$HOME/RetroPie/BIOS/mame0222/history/command.dat" backup=false envsubst=false
    else
      echo "Already installed command.dat (lr-mame)"
    fi

    if [ ! -f "$HOME/RetroPie/BIOS/mame0222/history/gameinit.dat" ]  || [ "$FORCE_UPDATE" == 'true' ]; then
      __download_gameinit_dat
      file_cp "$tmp_ephemeral_dir/gameinit.dat" "$HOME/RetroPie/BIOS/mame0222/history/gameinit.dat" backup=false envsubst=false
    else
      echo "Already installed gameinit.dat (lr-mame0222)"
    fi
  fi
}

__build_mame0244() {
  if has_emulator 'lr-mame'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame0244/history/command.dat" ]  || [ "$FORCE_UPDATE" == 'true' ]; then
      __download_command_dat
      file_cp "$tmp_ephemeral_dir/command.dat" "$HOME/RetroPie/BIOS/mame0244/history/command.dat" backup=false envsubst=false
    else
      echo "Already installed command.dat (lr-mame)"
    fi

    if [ ! -f "$HOME/RetroPie/BIOS/mame0244/history/gameinit.dat" ]  || [ "$FORCE_UPDATE" == 'true' ]; then
      __download_gameinit_dat
      file_cp "$tmp_ephemeral_dir/gameinit.dat" "$HOME/RetroPie/BIOS/mame0244/history/gameinit.dat" backup=false envsubst=false
    else
      echo "Already installed gameinit.dat (lr-mame0244)"
    fi
  fi
}

# Looks for the latest version of command.dat and downloads it
__download_command_dat() {
  local filename=$(download "$command_dat_home" | grep -oE 'pS_Command_[0-9]+.zip')
  if [ -z "$filename" ]; then
    echo '[WARN] Unable to scrape command.dat filename'
    return 1
  fi

  local url=$(render_template "$command_dat_url" filename="$filename")
  download "$url" "$tmp_ephemeral_dir/mame-command.zip"
  unzip -ojq "$tmp_ephemeral_dir/mame-command.zip" 'dats/command.dat' -d "$tmp_ephemeral_dir/"
}

# Looks for the latest version of gameinit.dat and downloads it
__download_gameinit_dat() {
  local filename=$(download "$gameinit_dat_home" | grep -oE 'pS_gameinit_[0-9]+.zip')
  if [ -z "$filename" ]; then
    echo '[WARN] Unable to scrape gameinit.dat filename'
    return 1
  fi

  local url=$(render_template "$gameinit_dat_url" filename="$filename")
  download "$url" "$tmp_ephemeral_dir/mame-gameinit.zip"
  unzip -ojq "$tmp_ephemeral_dir/mame-gameinit.zip" 'dats/gameinit.dat' -d "$tmp_ephemeral_dir/"
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2016/history/command.dat" \
    "$HOME/RetroPie/BIOS/mame2016/history/gameinit.dat" \
    "$HOME/RetroPie/BIOS/mame0222/history/command.dat" \
    "$HOME/RetroPie/BIOS/mame0222/history/gameinit.dat" \
    "$HOME/RetroPie/BIOS/mame0244/history/command.dat" \
    "$HOME/RetroPie/BIOS/mame0244/history/gameinit.dat"
}

setup "${@}"
