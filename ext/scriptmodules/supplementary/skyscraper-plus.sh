#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="skyscraper-plus"
rp_module_desc="Scraper for EmulationStation by Lars Muldjord + features by torresflo / detain"
rp_module_licence="GPL3 https://raw.githubusercontent.com/muldjord/skyscraper/master/LICENSE"
rp_module_repo="git https://github.com/detain/skyscraper.git :_get_branch_skyscraper-plus"
rp_module_section="opt"

function _get_branch_skyscraper-plus() {
    download https://api.github.com/repos/detain/skyscraper/releases/latest - | grep -m 1 tag_name | cut -d\" -f4
}

function depends_skyscraper-plus() {
    depends_skyscraper
}

function sources_skyscraper-plus() {
    sources_skyscraper
}

function build_skyscraper-plus() {
    build_skyscraper
}

function install_skyscraper-plus() {
    install_skyscraper

    md_ret_files+=(
        'platforms.json'
        'screenscraper.json'
    )
}

function remove_skyscraper-plus() {
    remove_skyscraper
}

function configure_skyscraper-plus() {
    configure_skyscraper

    local scraper_conf_dir="$configdir/all/skyscraper"

    # Copy additional resources
    local resource_file
    for resource_file in platforms.json screenscraper.json; do
        cp -f "$md_inst/$resource_file" "$scraper_conf_dir"
    done

    chown -R $user:$user "$scraper_conf_dir"
}
