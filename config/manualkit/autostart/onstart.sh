#!/bin/bash

# Ensure any previous instance of manualkit has been terminated
sudo pkill -f manualkit/cli.py

sudo python3 /opt/retropie/supplementary/manualkit/cli.py /opt/retropie/configs/all/manualkit.cfg --server --profile frontend --track-pid $PPID > $HOME/.emulationstation/manualkit_log.txt 2>&1 &
