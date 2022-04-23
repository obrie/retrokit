#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

# Reference: https://retropie.org.uk/forum/topic/28693/a-workaround-for-the-northwest-drift-
setup_module_id='hardware/controllers/calibrate'
setup_module_desc='Calibrates the axis midpoint using udev rules (avoids NW drift)'

# Script template
script_start="import evdev
from evdev import ecodes
device = evdev.InputDevice('%E{DEVNAME}')"
script_end="
device.write(ecodes.EV_SYN, 0, 0)
device.close()"

depends() {
  sudo pip3 install evdev
}

configure() {
  local rules=()

  while IFS=$'\t' read controller_name axis_config; do
    local script=$script_start

    # Add a write command for each axis code we need to calibrate
    while IFS='=' read axis_event_code axis_midpoint; do
      script="$script"$'\n'"device.write(ecodes.EV_ABS, ecodes.$axis_event_code, $axis_midpoint)"
    done < <(echo "$axis_config" | tr ',' '\n')

    # Convert the script to a one-liner
    script="$script$script_end"
    script="${script//$'\n'/; }"

    # Add the rule for this controller name
    local rule='SUBSYSTEM=="input", KERNEL=="event*", ACTION=="add", ATTRS{name}=="'"$controller_name"'", RUN+="/usr/bin/python3 -c \"'"$script"'\""'
    rules+=("$rule")
  done < <(setting '.hardware.controllers.inputs[] | select(.axis) | [.name, ([.axis | to_entries[] | [.key, .value | tostring] | join("=")] | join(","))] | @tsv')

  # Write the udev rule
  echo "${rules[@]}" | sudo tee /etc/udev/rules.d/99-joystick.rules >/dev/null

  # Reload the configuration (reboot still required)
  sudo udevadm control --reload
}

restore() {
  sudo rm -fv /etc/udev/rules.d/99-joystick.rules
  sudo udevadm control --reload
}

setup "${@}"
