#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="xpadneo-plus"
rp_module_desc="Advanced Linux driver for Xbox One wireless gamepads with v0.10.0 backports and customizations"
rp_module_licence="GPL3 https://raw.githubusercontent.com/atar-axis/xpadneo/master/LICENSE"
rp_module_repo="git https://github.com/atar-axis/xpadneo.git v0.9.3"
rp_module_section="driver"
rp_module_flags="nobin"

function _version_xpadneo-plus() {
    _version_xpadneo
}

function depends_xpadneo-plus() {
    depends_xpadneo
}

function sources_xpadneo-plus() {
    sources_xpadneo

    cd "$md_inst"

    # Backport: Nintendo layout not default for 8bitdo controllers
    applyPatch "$md_data/01_nintendo_not_by_default.diff"

    # New: Support translating trigger axes to buttons
    applyPatch "$md_data/02_buttons_to_triggers.diff"
}

function build_xpadneo-plus() {
    build_xpadneo
}

function remove_xpadneo-plus() {
    remove_xpadneo
}

function configure_xpadneo-plus() {
    configure_xpadneo

    if [[ ! -f /etc/modprobe.d/99-xpadneo-bluetooth-overrides.conf ]]; then
        echo "options hid_xpadneo triggers_to_buttons=1" | sudo tee /etc/modprobe.d/99-xpadneo-bluetooth-overrides.conf
    fi
}
