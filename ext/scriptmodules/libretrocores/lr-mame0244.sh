#!/usr/bin/env bash

rp_module_id="lr-mame0244"
rp_module_desc="MAME emulator - MAME 0.244 port for libretro"
rp_module_help="ROM Extensions: .zip\n\nCopy your MAME roms to either $romdir/mame-libretro or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/mame/master/COPYING"
rp_module_repo="git https://github.com/libretro/mame.git ee3942fc824edaf67768c249f2dd57ec3a20f4b5"
rp_module_section="exp"
rp_module_flags=""

function __binary_url_lr-mame0244() {
    echo "https://github.com/obrie/retrokit/releases/download/latest/lr-mame0244-rpi4-buster.tar.gz"
}

function install_bin_lr-mame0244() {
    downloadAndExtract "$(__binary_url_lr-mame0244)" "$md_inst" --strip-components 1
}

function depends_lr-mame0244() {
    depends_lr-mame
}

function sources_lr-mame0244() {
    sources_lr-mame
}

function build_lr-mame0244() {
    build_lr-mame
}

function install_lr-mame0244() {
    install_lr-mame
}

function configure_lr-mame0244() {
    configure_lr-mame-common 0244
}
