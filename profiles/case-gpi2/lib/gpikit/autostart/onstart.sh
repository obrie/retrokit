#!/bin/bash

# Enable reading GPIO state
if [ ! -f /sys/class/gpio/gpio18/value ]; then
  echo 18 > /sys/class/gpio/export
  echo in > /sys/class/gpio/gpio18/direction
fi

function update_es_setting() {
  local key=$1
  local value=$2
  sed -i 's/\(name="'"$key"'" value="\)[^"]\+"/\1'"$value"'"/' "$HOME/.emulationstation/es_settings.cfg"
}

# Switch the Audio Device based on whether we're connected to the HDMI or LCD
HDMI_HPD_VALUE=$(cat /sys/class/gpio/gpio18/value)
if [ $HDMI_HPD_VALUE == "1" ]; then
  update_es_setting AudioDevice HDMI
else
  update_es_setting AudioDevice Speaker
fi
