#!/bin/bash

# When the controls change, we reload manualkit in order to pick up the latest
# input configurations
exec 4<>/opt/retropie/configs/all/manualkit.fifo
>&4 echo 'reload_devices'
