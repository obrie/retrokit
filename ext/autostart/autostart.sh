# Run all scripts with the given hook name
function run_scripts() {
  local hook=$1

  if [ -d /opt/retropie/configs/all/autostart.d ]; then
    for autostart_dir in /opt/retropie/configs/all/autostart.d/*; do
      if [ -f "$autostart_dir/$hook.sh" ]; then
        "$autostart_dir/$hook.sh"
      fi
    done
  fi
}

# Provide a hook extension to the default autostart script so that
# we can add piecemeal extensions it without having to rewrite the
# entire autostart.sh file.
# 
# The primary contents of what gets launched occur in autostart-launch.sh.
run_scripts onstart
/opt/retropie/configs/all/autostart-launch.sh
run_scripts onend
