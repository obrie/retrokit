#!/bin/bash

# Clear the screen as quickly as we can
dd if=/dev/zero of=/dev/fb0 &>/dev/null

# Restore text mode for the console
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
python "$dir/tty.py" /dev/tty text
