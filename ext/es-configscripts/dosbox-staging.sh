#!/usr/bin/env bash

function check_dosbox-staging() {
    [[ ! -d "$rootdir/emulators/dosbox-staging" ]] && return 1
    return 0
}

function onstart_dosbox-staging_joystick() {
    iniConfig ' ' '"' /tmp/dosbox-staging-device.conf
    truncate -s0 /tmp/dosbox-staging-device.conf
}

# Generates the configuration key for a given ES input name
function _get_dosbox-staging_config_key() {
    local input_name=$1
    local key=''

    case "$input_name" in
        up|down|left|right|a|b|x|y|leftthumb|rightthumb|start|select|leftanalogleft|leftanalogright|leftanalogup|leftanalogdown|rightanalogleft|rightanalogright|rightanalogup|rightanalogdown)
            key=$input_name
            ;;
        leftbottom|leftshoulder)
            key=leftshoulder
            ;;
        lefttop|lefttrigger)
            ket=lefttrigger
            ;;
        rightbottom|rightshoulder)
            key=rightshoulder
            ;;
        righttop|righttrigger)
            ket=righttrigger
            ;;
        *)
            ;;
    esac

    echo "$key"
}

function map_dosbox-staging_joystick() {
    local input_name=$1
    local input_type=$2
    local input_id=$3
    local input_value=$4

    local key=($(_get_dosbox-staging_config_key "$input_name"))
    if [ -z "$key" ]; then
        return
    fi

    local value
    case "$input_type" in
        hat)
            # up, right, down, left
            value="hat 0 $input_value"
            ;;
        axis)
            if [[ "$input_value" == '1' ]]; then
                value="axis $input_id 1"
            else
                value="axis $input_id 0"
            fi
            ;;
        *)
            value="button $input_id"
            ;;
    esac

    iniSet "$key" "$value"
}


function onend_dosbox-staging_joystick() {
    local dosbox_staging_device_config_file="$configdir/pc/autoconfig/${DEVICE_NAME//[:><?\"\/\\|*]/}.conf"
    mkdir -pv "$(dirname "$dosbox_staging_device_config_file")"
    cp '/tmp/dosbox-staging-device.conf' "$dosbox_staging_device_config_file"
}
