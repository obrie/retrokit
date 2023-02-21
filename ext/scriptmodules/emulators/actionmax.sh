#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="actionmax"
rp_module_desc="ActionMax Emulator"
rp_module_help="ROM Extension: .daphne\n\nCopy your Daphne roms to $romdir/daphne"
rp_module_licence="GPL3 https://raw.githubusercontent.com/DirtBagXon/actionmax-pi/master/LICENSE"
rp_module_repo="git https://github.com/DirtBagXon/actionmax-pi.git main"
rp_module_section="exp"
rp_module_flags="sdl1"

function depends_actionmax() {
    getDepends libsdl1.2-dev libvorbis-dev libogg-dev libglew-dev zlib1g-dev libsdl-image1.2-dev libsdl-ttf2.0-dev
}

function sources_actionmax() {
    gitPullOrClone
}

function build_actionmax() {
    cd src/vldp2
    ./configure --disable-accel-detect
    rpSwap on 1024
    make -f Makefile.linux
    cd ../game/singe
    make -f Makefile.linux
    cd ../..
    make
    cd ..
    rpSwap off
    md_ret_require="actionmax.bin"
}

function install_actionmax() {
    md_ret_files=(
        'sound'
        'pics'
        'actionmax.bin'
        'singeinput.default'
        'LICENSE'
    )
}

function configure_actionmax() {
    mkRomDir "daphne"
    mkRomDir "daphne/roms"

    addEmulator 0 "$md_id" "daphne" "$md_inst/actionmax.sh %ROM%"
    addSystem "daphne"

    local allemu="$configdir/all/emulators.cfg"

    [[ "$md_mode" == "remove" ]] && return

    mkUserDir "$md_conf_root/daphne"

    ln -snf "$romdir/daphne/roms" "$md_inst/singe"
    ln -snf "$romdir/daphne/actionmax.daphne" "$romdir/daphne/actionmax"

    copyDefaultConfig "$md_inst/singeinput.default" "$md_conf_root/daphne/singeinput.ini"
    ln -sf "$md_conf_root/daphne/singeinput.ini" "$md_inst/singeinput.ini"

    local rom
    for rom in 38ambushalley bluethunder hydrosub2021 popsghostly sonicfury; do
    if ! grep -q "daphne_$rom" "$allemu"; then
    addLineToFile "daphne_$rom = \"$md_id\"" $allemu
    fi
    done

    local common_args="-framefile \"\$dir/\$name.txt\" -homedir \"$md_inst\" -fullscreen_window \$params"

    cat >"$md_inst/actionmax.sh" <<_EOF_
#!/bin/bash
dir="\$1"
name="\${dir##*/}"
name="\${name%.*}"

if [[ -f "\$dir/\$name.commands" ]]; then
    params=\$(<"\$dir/\$name.commands")
fi

"$md_inst/actionmax.bin" "\$dir/\$name.singe" $common_args
_EOF_
    chown -R $user:$user "$md_inst"
    chmod +x "$md_inst/actionmax.sh"
    chown -R $user:$user "$md_conf_root/daphne/singeinput.ini"
}
