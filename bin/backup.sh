#!/bin/bash

##############
# Backup SD card
##############

set -ex

usage() {
  echo "usage: $0 [DEVICE]"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

device=$1

sudo dd bs=4M if=$device | gzip | dd bs=4M of=../backups/sd-retropie.iso
sudo dd bs=4M if=$device | gzip | dd bs=4M of=../backups/sd-retropie-boot.iso
