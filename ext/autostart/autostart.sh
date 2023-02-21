retropie_configs_dir=/opt/retropie/configs
autostart_dir="$retropie_configs_dir/all/autostart.d"

# Run all scripts with the given hook name
function run_scripts() {
  local hook=$1

  if [ -d "$autostart_dir" ]; then
    for autostart_subdir in "$autostart_dir/"*; do
      if [ -f "$autostart_subdir/$hook.sh" ]; then
        "$autostart_subdir/$hook.sh"
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
"$retropie_configs_dir/all/autostart-launch.sh"
run_scripts onend
