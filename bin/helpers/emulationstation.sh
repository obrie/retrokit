##############
# EmulationStation helpers
##############

# Ensures emulationstation is not running.  This can be useful in cases where
# we are overriding an ES configuration and don't want it to get overwritten
# by ES.
stop_emulationstation() {
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true
}