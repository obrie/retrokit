#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="advmame-joy"
rp_module_desc="AdvanceMAME v3.9 - Raw udev input (no joystick overrides)"
rp_module_help="ROM Extension: .zip\n\nCopy your AdvanceMAME roms to either $romdir/mame-advmame or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/amadvance/advancemame/master/COPYING"
rp_module_repo="git https://github.com/amadvance/advancemame v3.9"
rp_module_section="opt"
rp_module_flags="sdl2 sdl1-videocore"

# function install_bin_advmame-joy() {
#     downloadAndExtract "<url>" "$md_inst" --strip-components 1
# }

function depends_advmame-joy() {
    depends_advmame
}

function sources_advmame-joy() {
    sources_advmame
}

function build_advmame-joy() {
    applyPatch "$md_data/01_disable_overrides.diff"
    build_advmame
}

function install_advmame-joy() {
    install_advmame
}

function configure_advmame-joy() {
    configure_advmame
}
