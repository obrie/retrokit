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

function depends_dosbox-staging() {
    getDepends build-essential cmake libasound2-dev libglib2.0-dev libopusfile-dev libpng-dev libsdl2-dev libsdl2-net-dev meson ninja-build
}

function sources_dosbox-staging() {
    gitPullOrClone
}

function build_dosbox-staging() {
    local params=(-Dbuildtype=release -Ddefault_library=static)

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
    md_ret_files=(
        'build/dosbox'
        'COPYING'
        'README'
    )
}

function configure_dosbox-staging() {
    local launcher_name="+Start DOSBox-Staging.sh"
    local config_filename="dosbox-staging.conf"

    mkRomDir "pc"
    rm -f "$romdir/pc/$launcher_name"
    if [[ "$md_mode" == "install" ]]; then
        cat > "$romdir/pc/$launcher_name" << _EOF_
#!/usr/bin/env bash
#
# if present
#   /home/$user/.config/dosbox/$config_filename
# will be used as primary config
#
params=("\$@")
if [[ -z "\${params[0]}" ]]; then
    params=(-c "@MOUNT C $romdir/pc -freesize 1024" -c "@C:")
elif [[ "\${params[0]}" == *.sh ]]; then
    bash "\${params[@]}"
    exit
elif [[ "\${params[0]}" == *.conf ]]; then
    params=(-userconf -conf "\${params[@]}")
else
    params+=(-exit)
fi

"$md_inst/dosbox" "\${params[@]}"
_EOF_
        chmod +x "$romdir/pc/$launcher_name"
        chown $user:$user "$romdir/pc/$launcher_name"

        local config_path=$(su "$user" -c "\"$md_inst/dosbox\" -printconf")
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
    fi

    moveConfigFile "$home/.config/dosbox/$config_filename" "$md_conf_root/pc/$config_filename"

    addEmulator 0 "$md_id" "pc" "bash $romdir/pc/${launcher_name// /\\ } %ROM%"
    addSystem "pc"
}
