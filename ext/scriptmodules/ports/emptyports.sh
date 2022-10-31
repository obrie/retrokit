#!/usr/bin/env bash

rp_module_id="emptyports"
rp_module_desc="Installs the ports system without any actual ports"
rp_module_section="opt"

function configure_emptyports() {
    mkUserDir "$romdir/ports"
    addSystem "ports"
}
