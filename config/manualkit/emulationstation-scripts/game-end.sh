#!/bin/bash

# When a game ends we want to make sure:
# * We hide manualkit so that ES is visible
# * We switch back to the nohotkey toggle profile since we don't want to use hotkeys within ES
# * We stop tracking any external PIDs since it's not necessary with ES
exec 4<>/var/run/manualkit.fifo
>&4 echo \
  'hide'$'\n' \
  'set_profile'$'\t''frontend'
