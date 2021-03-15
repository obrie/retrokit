#!/bin/bash

set -ex

##############
# Cannonball
##############

sudo ~/RetroPie-Setup/retropie_packages.sh cannonball _binary_

##############
# Duke Nukem 3D
##############

sudo ~/RetroPie-Setup/retropie_packages.sh eduke32 _binary_

# TODO: Switch Renderer to "Classic"

##############
# Quake
##############

sudo ~/RetroPie-Setup/retropie_packages.sh quake _binary_

##############
# Wolfenstein 3D
##############

sudo ~/RetroPie-Setup/retropie_packages.sh wolf4sdl _binary_
