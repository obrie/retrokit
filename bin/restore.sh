#!/bin/bash

##############
# Restore SD card
##############

set -e

sudo dd bs=4M if=/dev/mmcblk0p2 | gzip | dd bs=4M of=../backups/sd-retropie.iso.gz
sudo dd bs=4M if=/dev/mmcblk0p1 | gzip | dd bs=4M of=../backups/sd-retropie-boot.iso.gz

gunzip --stdout ../backups/current/sd-retropie.iso.gz | sudo dd bs=4M of=/dev/mmcblk0p2
gunzip --stdout ../backups/current/sd-retropie-boot.iso.gz | sudo dd bs=4M of=/dev/mmcblk0p1
