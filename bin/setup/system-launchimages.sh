#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-launchimages'
setup_module_desc='System-specific launch images to display while emulators are loading'

depends() {
  sudo apt-get install -y chromium

  sudo pip3 install jinja2-cli~=0.8.2
}

configure() {
  local enabled=$(system_setting '.launchimages.enabled')
  enabled=${enabled:-$(setting '.launchimages.enabled')}

  local source=$(system_setting '.launchimages.source')
  source=${source:-$(setting '.launchimages.source')}

  if [ "$enabled" == 'false' ]; then
    echo 'Launch images disabled'
    restore
    return
  fi

  # Get the current ES theme set name
  local es_settings_file="$home/.emulationstation/es_settings.cfg"
  local es_settings=$(sed -e '$a</settings>' -e 's/<?xml version="1.0"?>/<settings>/g' "$es_settings_file")
  local theme_set=$(echo "$es_settings" | xmlstarlet sel -t -v '/settings/string[@name="ThemeSet"]/@value')

  # Identify system theme
  local default_theme=$(xmlstarlet select -t -v "*/system[name='$system']/theme" -n /etc/emulationstation/es_systems.cfg)
  local system_theme=$(ini_get '{config_dir}/retropie/platforms.cfg' '' "${system}_theme")
  system_theme=${system_theme:-$default_theme}
  system_theme=${system_theme:-$system}
  system_theme=${system_theme//\"/}

  local target_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix .png)
  if [ "$source" == 'theme' ]; then
    __configure_from_theme "$theme_set" "$system_theme" "$target_file"
  else
    __configure_from_url "$theme_set" "$system_theme" "$source" "$target_file"
  fi

  if [ -f "$target_file" ]; then
    mkdir -p "$retropie_system_config_dir"

    local theme_file="$retropie_system_config_dir/launching-extended-$theme_set.png"
    cp "$target_file" "$theme_file"

    # Promote it to the primary launch screen for the system
    ln_if_different "$theme_file" "$retropie_system_config_dir/launching-extended.png"
  fi
}

__configure_from_url() {
  local theme_set=$1
  local system_theme=$2
  local url_template=$3
  local target_file=$4

  local url=$(render_template "$url_template" theme="$system_theme")
  download "$url" "$target_file"
}

__configure_from_theme() {
  local theme_set=$1
  local system_theme=$2
  local target_file=$3

  # Identify path to the system theme's ES configuration file
  local es_system_theme_dir="/etc/emulationstation/themes/$theme_set/$system_theme"
  local es_system_theme_file="$es_system_theme_dir/theme.xml"
  if [ ! -f "$es_system_theme_file" ]; then
    return
  fi

  # The view to use when searching for background images / colors
  local background_view=$(setting '.launchimages.background_view')
  background_view=${background_view:-basic}

  # Screen dimensions so we know what size image to render
  local screen_dimensions=$(get_screen_dimensions)
  IFS=x read -r screen_width screen_height <<< "$screen_dimensions"

  # Theme files
  local background_file=$(__get_data_from_theme "$es_system_theme_file" "/theme/view[contains(@name,'$background_view')]/image[@name='background' or @name='SystemBackground']/path" is_path=true)
  local logo_file=$(__get_data_from_theme "$es_system_theme_file" "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='logo']/path" is_path=true)
  local font_file=$(__get_data_from_theme "$es_system_theme_file" "/theme/view[contains(@name,'detailed')]/textlist/fontPath" is_path=true)

  # Theme styles
  local background_tile=$(__get_data_from_theme "$es_system_theme_file" "/theme/view[contains(@name,'$background_view')]/image[@name='background' or @name='SystemBackground']/tile")
  background_tile=${background_tile,,}
  local background_color=$(__get_data_from_theme "$es_system_theme_file" "/theme/view[contains(@name,'$background_view')]/image[@name='background' or @name='SystemBackground']/color")
  if [ "$background_color" == '#' ]; then
    # Discard bad colors
    background_color=
  fi

  local stylesheet_file=$(first_path "{config_dir}/themes/launchimage.css")

  # runcommand info
  local disable_menu=$(ini_get '{config_dir}/runcommand/runcommand.cfg' '' 'disable_menu')
  disable_menu=${disable_menu//\"/}

  # Data file for use within the jinja template
  local data_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.json)
  echo '{}' > "$data_file"

  # Copy files to a directory chromium will have access to for rendering on the page
  local data_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  cp "$background_file" "$font_file" "$logo_file" "$data_dir"

  json_edit "$data_file" \
    ".screen.width" "$screen_width" \
    ".screen.height" "$screen_height" \
    ".hrefs.stylesheet" "file://$stylesheet_file" \
    ".hrefs.background_image" "file://$data_dir/$(basename "$background_file")" \
    ".hrefs.logo" "file://$data_dir/$(basename "$logo_file")" \
    ".hrefs.font" "file://$data_dir/$(basename "$font_file")" \
    ".background.tile" "$background_tile" \
    ".background.color" "$background_color" \
    ".runcommand.disable_menu" "$disable_menu"

  # Render the template
  local html_template=$(first_path '{config_dir}/themes/launchimage.html.jinja')
  local html_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.html)
  jinja2 "$html_template" "$data_file" > "$html_file"

  # Render HTML => PNG
  chromium --headless --disable-gpu --run-all-compositor-stages-before-draw --screenshot="$target_file" --window-size=$screen_width,$screen_height "$html_file" 2>/dev/null
}

__get_data_from_theme() {
  local es_system_theme_file=$1
  local xpath=$2
  local is_path=$3
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  # List of potential paths that may include the requested data
  local rendered_paths=(
    theme.xml
    $(xmlstarlet sel -t -v '/theme/include' "$es_system_theme_file" 2>/dev/null)
  )

  # Find the data in any of the rendered xml paths
  local theme_path
  for theme_path in "${rendered_paths[@]}"; do
    data=$(xmlstarlet sel -t -v "$xpath" "$es_system_theme_dir/$theme_path" 2>/dev/null | head -1)

    if [ -n "$data" ]; then
      # Check if this is a variable and substitute with its real value if so
      if [[ "$data" == '${'*'}' ]]; then
        local variable_name=${data:2:-1}
        data=$(xmlstarlet sel -t -v "/theme/variables/$variable_name" "$es_system_theme_dir/$theme_path" 2>/dev/null | head -1)
      fi

      break
    fi
  done

  if [ -z "$data" ]; then
    return
  fi

  if [ "$is_path" == 'true' ]; then
    local data_dir=$(dirname "$es_system_theme_dir/$theme_path")
    echo "$data_dir/$data"
  else
    echo "$data"
  fi
}

restore() {
  # Remove just the symlink since this will disable the functionality
  rm -fv "$retropie_system_config_dir/launching-extended.png"
}

remove() {
  rm -fv "$retropie_system_config_dir/"launching-extended-*
}

setup "${@}"
