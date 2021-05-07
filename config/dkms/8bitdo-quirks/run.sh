#!/bin/bash
rpi_kernel_ver='rpi-5.10.y'
mkdir -p 'drivers/hid/' 'patches'
curl -s https://raw.githubusercontent.com/raspberrypi/linux/"\$rpi_kernel_ver"/drivers/hid/hid-input.c -o 'drivers/hid/hid-input.c'
patch -p1 < 'patches/0001-hid8bitdo-quirks.diff'
