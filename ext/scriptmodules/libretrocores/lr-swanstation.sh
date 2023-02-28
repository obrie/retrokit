#!/usr/bin/env bash

rp_module_id="lr-swanstation"
rp_module_desc="PlayStation emulator - Swanstation for libretro"
rp_module_help="ROM Extensions: .exe .cue .bin .chd .psf .m3u .pbp\n\nCopy your PlayStation roms to $romdir/psx\n\nCopy compatible BIOS files to $biosdir"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/swanstation/main/LICENSE"
rp_module_repo="git https://github.com/libretro/swanstation.git main"
rp_module_section="exp"
rp_module_flags="!all arm !armv6 aarch64 64bit"

function depends_lr-swanstation() {
    getDepends cmake
}

function sources_lr-swanstation() {
    gitPullOrClone
}

function build_lr-swanstation() {
    mkdir build
    cmake -DCMAKE_BUILD_TYPE=Release -Bbuild
    cmake --build build --target swanstation_libretro --config Release
    md_ret_require="$md_build/build/swanstation_libretro.so"
}

function install_lr-swanstation() {
    md_ret_files=(
        'build/swanstation_libretro.so'
    )
}

function configure_lr-swanstation() {
    mkRomDir "psx"
    defaultRAConfig "psx"

    if isPlatform "gles" && ! isPlatform "gles3"; then
        # Hardware renderer not supported on GLES2 devices
        setRetroArchCoreOption "duckstation_GPU.Renderer" "Software"
    fi

    # Pi 4 has occasional slowdown with hardware rendering
    # e.g. Gran Turismo 2 (Arcade) race start
    isPlatform "rpi4" && setRetroArchCoreOption "duckstation_GPU.Renderer" "Software"

    # Configure the memory card 1 saves through the libretro API
    setRetroArchCoreOption "duckstation_MemoryCards.Card1Type" "NonPersistent"

    # dynarec segfaults without redirecting stdin from </dev/null
    addEmulator 0 "$md_id" "psx" "$md_inst/swanstation_libretro.so </dev/null"
    addSystem "psx"
}
