#!/bin/bash

##############
# Backup SD card
##############

set -e

sudo dd bs=4M if=/dev/mmcblk0p2 | gzip | dd bs=4M of=../backups/sd-retropie.iso
sudo dd bs=4M if=/dev/mmcblk0p1 | gzip | dd bs=4M of=../backups/sd-retropie-boot.iso
