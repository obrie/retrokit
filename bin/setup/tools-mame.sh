#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# We need to install a newer version of chdman for it to work with
# Dreamcast redump images.  This won't be needed once we're on bullseye.
setup_module_id='tools-mame'
setup_module_desc='MAME 0.230 tools, like chdman, not available through system packages'

chdman_build=binary
chdman_min_version=0.230

depends() {
  if [ "$chdman_build" == 'binary' ]; then
    return
  fi

  sudo apt install -y libfontconfig1-dev qt5-default libsdl2-ttf-dev libxinerama-dev libxi-dev
}

build() {
  if [ ! `command -v chdman` ] || version_lt "$(chdman | grep -oE 'manager [0-9\.]+')" "$chdman_min_version"; then
    __build_chdman_${chdman_build}
  fi
}

__build_chdman_source() {
  # Set build flags
  export CFLAGS='-mcpu=cortex-a72 -mfpu=neon-fp-armv8 -O2'
  export MAKEFLAGS='-j4'

  # Build from source
  git clone --depth 1 -b mame0230 https://github.com/mamedev/mame "$tmp_ephemeral_dir/mame"
  pushd "$tmp_ephemeral_dir/mame"
  make NOWERROR=1 ARCHOPTS=-U_FORTIFY_SOURCE PYTHON_EXECUTABLE=python3 TOOLS=1 REGENIE=1

  # Install chdman
  sudo cp castool chdman floptool imgtool jedutil ldresample ldverify romcmp /usr/local/bin/
  popd
}

__build_chdman_binary() {
  sudo unzip -o "$cache_dir/mame/mame0230-tools.zip" -d /usr/local/bin/
}

remove() {
  sudo rm -fv \
    /usr/local/bin/castool \
    /usr/local/bin/chdman \
    /usr/local/bin/floptool \
    /usr/local/bin/imgtool \
    /usr/local/bin/jedutil \
    /usr/local/bin/ldresample \
    /usr/local/bin/ldverify \
    /usr/local/bin/romcmp
}

setup "${@}"
