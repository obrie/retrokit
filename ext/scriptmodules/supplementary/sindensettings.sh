#!/usr/bin/env bash

rp_module_id="sindensettings"
rp_module_desc="Configure Sinden settings"
rp_module_section="exp"
rp_module_flags="!all rpi"

function configure_sindensettings() {
    [[ "$md_mode" == "remove" ]] && return

    # Copy menu icon
    local rpdir="$home/RetroPie/retropiemenu"
    cp -Rv "$md_data/icon.jpg" "$rpdir/icons/sindensettings.jpg"
    chown $user:$user "$rpdir/icons/sindensettings.jpg"

    local file="sindensettings"
    local name="Sinden"
    local desc="Manages your sinden configurations"
    local image="$home/RetroPie/retropiemenu/icons/sindensettings.jpg"

    touch "$rpdir/$file.rp"
    chown $user:$user "$rpdir/$file.rp"

    # Add sinden to the retropie system
    local function
    for function in $(compgen -A function _add_rom_); do
        "$function" "retropie" "RetroPie" "$file.rp" "$name" "$desc" "$image"
    done
}

function remove_sindensettings() {
    rm -fv \
        "$home/RetroPie/retropiemenu/sindensettings.rp" \
        "$home/RetroPie/retropiemenu/icons/sindensettings.jpg"

    # Remove menu item
    if [ -f "$home/.emulationstation/gamelists/retropie/gamelist.xml" ]; then
        xmlstarlet ed --inplace -d '/gameList/game[name="Sinden"]' "$home/.emulationstation/gamelists/retropie/gamelist.xml"
    fi
}

# Main menu
function gui_sindensettings() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --menu "Sinden configuration" 22 85 16)
        local options=(
            "calibrate" "Calibrate aim"
            "controls" "Controller behaviors"
            "power" "Power settings"
            "recoil" "Recoil settings"
        )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            "_gui_${choice}_sindensettings"
        else
            break
        fi
    done
}

# Calibration menu
function _gui_calibrate_sindensettings() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label 'Back' --menu 'Sinden calibration' 22 85 16)
        local options=(
            "player1" "Calibrate Player 1"
            "player2" "Calibrate Player 2"
            "screenheight" "Set Screen Height"
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        case "$choice" in
            player1)
                _run_sindensettings calibrate 1 || _gui_error_sindensettings 'Failed to run Sinden software'
                ;;
            player2)
                _run_sindensettings calibrate 2 || _gui_error_sindensettings 'Failed to run Sinden software'
                ;;
            screenheight)
                _gui_screenheight_sindensettings
                ;;
            *)
                break
                ;;
        esac
    done
}

function _gui_power_sindensettings() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label 'Back' --menu 'Sinden power control' 22 85 16)
        local options=(
            "start" "Start All"
            "start1" "Start Player 1"
            "start2" "Start Player 2"
            "stop" "Stop All"
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        case "$choice" in
            start)
                _run_sindensettings start_all
                ;;
            start1)
                _run_sindensettings start 1
                ;;
            start2)
                _run_sindensettings start 2
                ;;
            stop)
                _run_sindensettings stop_all
                ;;
            *)
                break
                ;;
        esac

        if [ "$?" -ne 0 ]; then
            _gui_error_sindensettings 'Failed to run Sinden software'
        fi
    done
}

# Calibrate screen height
function _gui_screenheight_sindensettings() {
    local screen_height=$(_run_sindensettings get_screen_height)
    screen_height=$(inputBox "Screen Height (inches, excluding any bezel)" "$screen_height" 1)
    if [ -n "$screen_height" ]; then
        if [[ ! "$screen_height" =~ [0-9\.]+ ]]; then
            _gui_error_sindensettings "\"$screen_height\" is not a valid float value"
            return
        fi

        _run_sindensettings edit_screen_height "$screen_height" || _gui_error_sindensettings 'Failed to edit config'
    fi
}

# Sinden input controls
function _gui_controls_sindensettings() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label 'Back' --menu 'Sinden controls' 22 85 16)
        local options=(
            "enablerepeat" "Enable Trigger Repeat"
            "disablerepeat" "Disable Trigger Repeat"
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        case "$choice" in
            enablerepeat)
                _run_sindensettings edit_all TriggerRecoilNormalOrRepeat=1
                ;;
            disablerepeat)
                _run_sindensettings edit_all TriggerRecoilNormalOrRepeat=0
                ;;
            *)
                break
                ;;
        esac

        if [ "$?" -ne 0 ]; then
            _gui_error_sindensettings 'Failed to edit config'
        fi
    done
}

# Setup action selection
function _gui_recoil_sindensettings() {
    while true; do
        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label 'Back' --menu "$setupmodule setup configuration ($system)" 22 85 16)
        local options=(
            "disable" "Disable Recoil"
            "enable" "Enable Recoil (default power)"
            "25%" "Recoil Power: 25%"
            "50%" "Recoil Power: 50%"
            "75%" "Recoil Power: 75%."
            "100%" "Recoil Power: 100%"
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        case "$choice" in
            disable)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=0
                ;;
            enable)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=1
                ;;
            25%)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=1 RecoilStrength=25 AutoRecoilStrength=10
                ;;
            50%)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=1 RecoilStrength=50 AutoRecoilStrength=30
                ;;
            75%)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=1 RecoilStrength=75 AutoRecoilStrength=55
                ;;
            100%)
                /opt/retropie/supplementary/sinden/sinden.sh edit_all EnableRecoil=1 RecoilStrength=100 AutoRecoilStrength=80
                ;;
            *)
                break
                ;;
        esac

        if [ "$?" -ne 0 ]; then
            _gui_error_sindensettings 'Failed to edit config'
        fi
    done
}

function _run_sindensettings() {
    /opt/retropie/supplementary/sinden/sinden.sh "${@}"
}

function _gui_error_sindensettings() {
    printMsgs "dialog" "$1"
}
