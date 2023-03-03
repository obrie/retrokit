#!/usr/bin/env bash

rp_module_id="lr-mame2016-lightgun"
rp_module_desc="MAME emulator - MAME 0.174 port for libretro"
rp_module_help="ROM Extensions: .zip\n\nCopy your MAME roms to either $romdir/mame-libretro or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/mame/master/COPYING"
rp_module_repo="git https://github.com/StormedBubbles/mame2016-libretro.git master"
rp_module_section="exp"
rp_module_flags=""

function __binary_url_lr-mame2016-lightgun() {
    echo "https://github.com/obrie/retrokit/releases/download/latest/$rp_module_id-$__platform-$__os_codename.tar.gz"
}

function install_bin_lr-mame2016-lightgun() {
    downloadAndExtract "$(__binary_url_lr-mame2016-lightgun)" "$md_inst" --strip-components 1
}

function depends_lr-mame2016-lightgun() {
    depends_lr-mame2016
}

function sources_lr-mame2016-lightgun() {
    sources_lr-mame2016
}

function build_lr-mame2016-lightgun() {
    build_lr-mame2016
}

function install_lr-mame2016-lightgun() {
    install_lr-mame2016
}

function configure_lr-mame2016-lightgun() {
    configure_lr-mame2016
}
