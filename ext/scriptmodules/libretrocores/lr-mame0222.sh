#!/usr/bin/env bash

rp_module_id="lr-mame0222"
rp_module_desc="MAME emulator - MAME 0.222 port for libretro"
rp_module_help="ROM Extensions: .zip\n\nCopy your MAME roms to either $romdir/mame-libretro or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/mame/master/COPYING"
rp_module_repo="git https://github.com/libretro/mame.git lrmame0222"
rp_module_section="exp"
rp_module_flags=""

function __binary_url_lr-mame0222() {
    echo "https://github.com/obrie/retrokit/releases/download/latest/lr-mame0222-rpi4-buster.tar.gz"
}

function install_bin_lr-mame0222() {
    downloadAndExtract "$(__binary_url_lr-mame0222)" "$md_inst" --strip-components 1
}

function depends_lr-mame0222() {
    depends_lr-mame
}

function sources_lr-mame0222() {
    sources_lr-mame
}

function build_lr-mame0222() {
    build_lr-mame
}

function install_lr-mame0222() {
    install_lr-mame
}

function configure_lr-mame0222() {
    configure_lr-mame-common 0222
}
