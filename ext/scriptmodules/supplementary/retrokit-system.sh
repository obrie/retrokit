#!/usr/bin/env bash

rp_module_id="retrokit-system"
rp_module_desc="Configure custom retrokit systems"
rp_module_section="exp"
rp_module_flags="!all rpi"

function configure_retrokit-system() {
    local package_id=$1
    local system=$2
    local cmd=$3

    mkRomDir "$system"
    defaultRAConfig "$system"

    md_inst=$(rp_getInstallPath "$package_id")
    addEmulator 0 "$package_id" "$system" "$md_inst/$cmd"
    addSystem "$system"
}
