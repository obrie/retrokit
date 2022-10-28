#!/bin/bash
# Toggles between mixing stereo for mono output and playing stereo output
if [ -f /etc/asound.conf ]; then
  rm /etc/asound.conf
else
  ln -fs /etc/asound-mono.conf /etc/asound.conf
fi
