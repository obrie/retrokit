#!/bin/bash

##############
# Restore SD card
##############

set -e

gunzip --stdout ../backups/current/sd-retropie.iso.gz | sudo dd bs=4M of=/dev/mmcblk0p2
gunzip --stdout ../backups/current/sd-retropie-boot.iso.gz | sudo dd bs=4M of=/dev/mmcblk0p1
