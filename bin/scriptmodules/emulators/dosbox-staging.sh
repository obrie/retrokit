#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="dosbox-staging"
rp_module_desc="modern DOS/x86 emulator focusing on ease of use"
rp_module_help="ROM Extensions: .bat .com .exe .sh .conf\n\nCopy your DOS games to $romdir/pc"
rp_module_licence="GPL2 https://raw.githubusercontent.com/dosbox-staging/dosbox-staging/master/COPYING"
rp_module_repo="git https://github.com/dosbox-staging/dosbox-staging.git master"
rp_module_section="exp"
rp_module_flags="sdl2"

function depends_dosbox-staging() {
    getDepends build-essential cmake libasound2-dev libglib2.0-dev libopusfile-dev libpng-dev libsdl2-dev libsdl2-net-dev meson ninja-build
}

function sources_dosbox-staging() {
    gitPullOrClone
}

function build_dosbox-staging() {
    local params=(-Dbuildtype=release -Ddefault_library=static --prefix="$md_inst")

    # Fluidsynth (static)
    cd "$md_build/contrib/static-fluidsynth"
    make
    export PKG_CONFIG_PATH="${md_build}/contrib/static-fluidsynth/fluidsynth/build"

    cd "$md_build"
    meson setup "${params[@]}" build
    ninja -C build

    md_ret_require=(
        "$md_build/build/dosbox"
    )
}

function install_dosbox-staging() {
    cd "$md_build/build"
    meson install
}

function configure_dosbox-staging() {
    local def=0
    local launcher_name="+Start DOSBox-Staging.sh"
    local needs_synth=0
    local config_dir="$home/.config/dosbox"

    mkRomDir "pc"
    
    moveConfigDir "$config_dir" "$md_conf_root/pc"

    addEmulator "$def" "$md_id" "pc" "bash $romdir/pc/${launcher_name// /\\ } %ROM%"
    addSystem "pc"

    rm -f "$romdir/pc/$launcher_name"
    [[ "$md_mode" == "remove" ]] && return

    cat > "$romdir/pc/$launcher_name" << _EOF_
#!/bin/bash
[[ ! -n "\$(aconnect -o | grep -e TiMidity -e FluidSynth)" ]] && needs_synth="$needs_synth"
function midi_synth() {
    [[ "\$needs_synth" != "1" ]] && return
    case "\$1" in
        "start")
            timidity -Os -iAD &
            i=0
            until [[ -n "\$(aconnect -o | grep TiMidity)" || "\$i" -ge 10 ]]; do
                sleep 1
                ((i++))
            done
            ;;
        "stop")
            killall timidity
            ;;
        *)
            ;;
    esac
}
params=("\$@")
if [[ -z "\${params[0]}" ]]; then
    params=(-c "@MOUNT C $romdir/pc -freesize 1024" -c "@C:")
elif [[ "\${params[0]}" == *.sh ]]; then
    midi_synth start
    bash "\${params[@]}"
    midi_synth stop
    exit
elif [[ "\${params[0]}" == *.conf ]]; then
    params=(-userconf -conf "\${params[@]}")
else
    params+=(-exit)
fi
# fullscreen when running in X
[[ -n "\$DISPLAY" ]] && params+=(-fullscreen)
midi_synth start
"$md_inst/bin/dosbox" "\${params[@]}"
midi_synth stop
_EOF_
    chmod +x "$romdir/pc/$launcher_name"
    chown $user:$user "$romdir/pc/$launcher_name"

    local config_path=$(su "$user" -c "\"$md_inst/bin/dosbox\" -printconf")
    if [[ -f "$config_path" ]]; then
        iniConfig " = " "" "$config_path"
        if isPlatform "rpi"; then
            iniSet "fullscreen" "true"
            iniSet "fullresolution" "desktop"
            iniSet "output" "texturenb"
            iniSet "core" "dynamic"
            iniSet "cycles" "25000"
        fi
    fi
}
