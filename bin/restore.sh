#!/bin/bash

##############
# Restore SD card
##############

set -ex

usage() {
  echo "usage: $0 [DEVICE]"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

gunzip --stdout ../backups/current/sd-retropie.iso.gz | sudo dd bs=4M of=$device
gunzip --stdout ../backups/current/sd-retropie-boot.iso.gz | sudo dd bs=4M of=$device
