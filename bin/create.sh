#!/bin/bash

##############
# Create a new image
##############

set -e

# Install Raspberry Pie Imager (https://retropie.org.uk/docs/First-Installation/)

wget https://downloads.raspberrypi.org/imager/imager_1.5_amd64.deb
dpkg -i imager_1.5_amd64.deb
rpi-imager
