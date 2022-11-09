#!/bin/bash

# Toggles between mixing stereo for mono output and playing stereo output
toggle_stereo_output() {
  if [ -f /etc/asound.conf ]; then
    rm /etc/asound.conf
    echo 'Mono output enabled (mixed)'
  else
    ln -fs /etc/asound-mono.conf /etc/asound.conf
    echo 'Stereo output enabled'
  fi
}

toggle_stereo_output
