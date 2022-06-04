#!/usr/bin/env bash

# Adds support for overriding certain joystick controls automatically.
# This is most typically used for disabling hotkeys.
# 
# Also adds support for missing keyboard hotkeys.

function onstart_retrokit-overrides_keyboard() {
    iniConfig " = " '"' "$configdir/all/retroarch.cfg"
}

function map_retroarch_keyboard() {
    local input_name="$1"
    local input_type="$2"
    local input_id="$3"
    local input_value="$4"

    local key
    case "$input_name" in
        leftbottom|leftshoulder)
            keys=("input_load_state")
            ;;
        rightbottom|rightshoulder)
            keys=("input_save_state")
            ;;
        *)
            return
            ;;
    esac

    for key in "${keys[@]}"; do
        iniSet "$key" "${retroarchkeymap[$input_id]}"
    done
}

function onend_retrokit-overrides_keyboard() {
    __override_retroarch_settings_retrokit 'keyboard'
}

function onend_retrokit-overrides_joystick() {
    iniConfig " = " '"' "$configdir/all/retroarch-joypads/${DEVICE_NAME//[\?\<\>\\\/:\*\|]/}.cfg"
    __override_retroarch_settings_retrokit 'joystick'
}

# Overrides settings according to autoconf.cfg
function __override_retroarch_settings_retrokit() {
    local input_type=$1

    while IFS='=' read key override_value; do
        key=${key//retroarch_${input_type}_/}
        override_value=${value//\"/}

        if [ -n "$override_value" ]; then
            iniSet "$key" "$override_value"
        else
            iniDel "$key"
        fi
    done < <(grep "retroarch_${input_type}_" "$configdir/all/autoconf.cfg" | sed 's/ *= */=/g')
}
