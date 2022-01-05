#!/usr/bin/env bash

# Adds support for disabling certain emulator controls when Emulationstation is
# in Kiosk mode in order to avoid overriding emulator settings

# Path to the emulationstation configuration
es_settings_path="$configdir/all/emulationstation/es_settings.cfg"

function onend_retrokit-kiosk_keyboard() {
    if in_kiosk_mode; then
        iniConfig " = " '"' "$configdir/all/retroarch.cfg"
        remove_setting "menu" "input_menu_toggle"
        remove_setting "reset" "input_reset"
    fi
}

function onend_retrokit-kiosk_joystick() {
    if in_kiosk_mode; then
        iniConfig " = " '"' "$configdir/all/retroarch-joypads/${DEVICE_NAME//[\?\<\>\\\/:\*\|]/}.cfg"
        remove_setting "menu" "input_menu_toggle_btn"
        remove_setting "reset" "input_reset_btn"
    fi
}

# Determines whether emulationstation is currently in Kiosk or Kids mode
function in_kiosk_mode() {
    if [ -f "$es_settings_path" ]; then
        # Get current UI Mode
        local ui_mode=$(sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' "$es_settings_path" | xmlstarlet sel -t -v '/*/*[@name="UIMode"]/@value')
        [ "$ui_mode" == 'Kiosk' ] || [ "$ui_mode" == 'Kid' ]
    else
        return 1
    fi
}

# Removes the given settings.  Currently there's no control over which controls
# to disable, though this is set up to potentially support that.
function remove_setting() {
    local name=$1
    local setting=$2

    iniDel "$setting"
}
