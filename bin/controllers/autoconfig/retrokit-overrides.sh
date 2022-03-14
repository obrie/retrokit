#!/usr/bin/env bash

# Adds support for overriding certain joystick controls automatically.
# This is most typically used for disabling hotkeys.

# Path to the emulationstation configuration
overrides_path="$inputscriptdir/configscripts/autoconfig-overrides.cfg"

function onend_retrokit-overrides_keyboard() {
    iniConfig " = " '"' "$configdir/all/retroarch.cfg"
    __override_retroarch_settings_retrokit 'keyboard'
}

function onend_retrokit-overrides_joystick() {
    iniConfig " = " '"' "$configdir/all/retroarch-joypads/${DEVICE_NAME//[\?\<\>\\\/:\*\|]/}.cfg"
    __override_retroarch_settings_retrokit 'joystick'
}

# Overrides settings according to autoconf.cfg
function __override_retroarch_settings_retrokit() {
    local input_type=$1

    if [ -f "$overrides_path" ]; then
        while IFS='=' read key override_value; do
            key=${key//retroarch_${input_type}_/}
            override_value=${value//\"/}
            
            if [ -n "$override_value" ]; then
                iniSet "$key" "$override_value"
            else
                iniDel "$key"
            fi
        done < <(grep "retroarch_${input_type}_" "$configdir/all/autoconf.cfg" | sed 's/ *= */=/g')
    fi
}
