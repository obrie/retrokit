function run_scripts() {
  if [ -d /opt/retropie/configs/all/autostart.d ]; then
    for autostart_dir in /opt/retropie/configs/all/autostart.d/*; do
      if [ -f "$autostart_dir/$1.sh" ]; then
        "$autostart_dir/$1.sh"
      fi
    done
  fi
}

run_scripts onstart
emulationstation --no-exit #auto
run_scripts onend
