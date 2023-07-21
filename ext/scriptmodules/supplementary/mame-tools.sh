#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="mame-tools"
rp_module_desc="MAME tools"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mamedev/mame/master/COPYING"
rp_module_repo="git https://github.com/mamedev/mame.git :_get_branch_mame-tools"
rp_module_section="exp"
rp_module_flags="!mali !armv6"

function _get_branch_mame-tools() {
    _get_branch_mame
}

function depends_mame-tools() {
    depends_mame
}

function sources_mame-tools() {
    sources_mame
}

function build_mame-tools() {
    # More memory is required for 64bit platforms
    if isPlatform "64bit"; then
        rpSwap on 8192
    else
        rpSwap on 4096
    fi

    # Compile MAME
    local params=(SUBTARGET=pacem SOURCES=src/mame/pacman/pacman.cpp NOWERROR=1 ARCHOPTS=-U_FORTIFY_SOURCE PYTHON_EXECUTABLE=python3 TOOLS=1 REGENIE=1)
    QT_SELECT=5 make "${params[@]}"

    rpSwap off
    md_ret_require="$md_build/chdman"
}

function install_mame-tools() {
    md_ret_files=(
        'castool'
        'chdman'
        'floptool'
        'imgtool'
        'jedutil'
        'ldresample'
        'ldverify'
        'romcmp'
    )
}

function configure_mame-tools() {
    for tool in castool chdman floptool imgtool jedutil ldresample ldverify romcmp; do
        if [[ "$md_mode" == "install" ]]; then
            ln -sf "$md_inst/$tool" "/usr/local/bin/$tool"
        else
            rm -f "/usr/local/bin/$tool"
        fi
    done
}
