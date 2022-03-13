#!/usr/bin/env bash

# Adds support for overriding certain joystick controls automatically.
# This is most typically used for disabling hotkeys.

# Path to the emulationstation configuration
overrides_path="$inputscriptdir/configscripts/autoconfig-overrides.cfg"

function onend_retrokit-overrides_keyboard() {
    iniConfig " = " '"' "$configdir/all/retroarch.cfg"
    override_settings 'keyboard'
}

function onend_retrokit-overrides_joystick() {
    iniConfig " = " '"' "$configdir/all/retroarch-joypads/${DEVICE_NAME//[\?\<\>\\\/:\*\|]/}.cfg"
    override_settings 'joystick'
}

# Removes the given settings.  Currently there's no control over which controls
# to disable, though this is set up to potentially support that.
function override_settings() {
    local input_type=$1

    if [ -f "$overrides_path" ]; then
        while read key; do
            local override_value=$(crudini --get "$overrides_path" "$input_type" "$key")
            if [ -n "$override_value" ]; then
                iniSet "$key" "$override_value"
            else
                iniDel "$key"
            fi
        done < <(crudini --get "$overrides_path" "$input_type")
    fi
}
