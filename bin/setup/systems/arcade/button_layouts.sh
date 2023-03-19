#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/button_layouts'
setup_module_desc='Remaps buttons according to a logical layout so all Arcade emulators behave consistently'

retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
retroarch_remapping_dir=${retroarch_remapping_dir%/}
autoconf_file="$retropie_configs_dir/all/autoconf.cfg"

# Maximum number of players to remap
max_players=8

# Default: b a y x l r l2 r2 l3 r3
# 
# MAME Reference:
# * RetroPad IDs: https://github.com/libretro/mame/blob/739058dac4d2d2a4553b8677cc54ebe474fea6c3/src/osd/libretro/libretro-internal/libretro.h#L183-L203
# * RetroPad Button Mappings: https://github.com/libretro/mame/blob/739058dac4d2d2a4553b8677cc54ebe474fea6c3/src/osd/modules/input/input_retro.cpp#L184-L189
# 
# MAME 2003-Plus Reference:
# * RetroPad IDs: https://github.com/libretro/mame2003-plus-libretro/blob/6f3b18c941327ff18b817e2fa40ccf3a15d6a3db/src/libretro-common/include/libretro.h#L188-L203
# * RetroPad Button Mappings: https://github.com/libretro/mame2003-plus-libretro/blob/d4d9bd8aebedaefe4bf94720589f7a007fcd401b/src/mame2003/mame2003.c#L1051-L1060
# * Internal Mappings: https://github.com/libretro/mame2003-plus-libretro/blob/d4d9bd8aebedaefe4bf94720589f7a007fcd401b/src/mame2003/mame2003.c#L912-L927
declare -a mame_buttons=(0 8 1 9 10 11 12 13 14 15)

# Default: b y x a l r l2 r2 l3 r3
# 
# MAME 2003 (0.78) Reference:
# * RetroPad IDs: https://github.com/libretro/mame2003-libretro/blob/77d6f13f45bd37ef6257b58b747a75c539b77b48/src/libretro-common/include/libretro.h#L188-L203
# * RetroPad Button Mappings: https://github.com/libretro/mame2003-libretro/blob/b8ba8232bd4539007d99b477118aa9354cb896d6/src/mame2003/mame2003.c#L239-L248
declare -a mame2003_buttons=(0 1 9 8 10 11 12 13 14 15)

# Default: a b x y l r l2 r2 l3 r3
# 
# MAME 2010 Reference:
# * RetroPad IDs: https://github.com/libretro/mame2010-libretro/blob/932e6f2c4f13b67b29ab33428a4037dee9a236a8/src/osd/retro/libretro.h#L144-L159
# * RetroPad Button Mappings: https://github.com/libretro/mame2010-libretro/blob/932e6f2c4f13b67b29ab33428a4037dee9a236a8/src/osd/retro/retromain.c#L835-L850
# 
# MAME 2015 Reference:
# * RetroPad IDs: https://github.com/libretro/mame2015-libretro/blob/ef41361dc9c88172617f7bbf6cd0ead4516a3c3f/src/osd/retro/libretro.h#L144-L159
# * RetroPad Button Mappings: https://github.com/libretro/mame2015-libretro/blob/e6a7aa4d53726e61498f68d6b8e2c092a2169fa2/src/osd/retro/retromain.c#L813-L814
# 
# MAME 2016 Reference:
# * RetroPad IDs: https://github.com/libretro/mame2016-libretro/blob/01058613a0109424c4e7211e49ed83ac950d3993/src/osd/retro/libretro-common/include/libretro.h#L186-L201
# * RetroPad Button Mappings: https://github.com/libretro/mame2016-libretro/blob/01058613a0109424c4e7211e49ed83ac950d3993/src/osd/retro/retromain.cpp#L333-L334
declare -a mame2010_buttons=(8 0 9 1 10 11 12 13 14 15)

# Default: b a y x r l r2 l2 r3 l3
# 
# FinalBurn Neo Reference:
# * RetroPad IDs: https://github.com/libretro/FBNeo/blob/607eed06f59dd744dc568c9060045ee20151bac2/src/burner/libretro/libretro-common/include/libretro.h#L183-L203
# * RetroPad Button Mappings: https://github.com/libretro/FBNeo/blob/607eed06f59dd744dc568c9060045ee20151bac2/src/burner/libretro/retro_input.cpp#L2063-L2081
declare -a fbneo_buttons=(0 8 1 9 11 10 13 12 15 14)

# Default: b a y x r l r2 l2 r3 l3
declare -a advmame_buttons=(1 2 3 4 5 6 7 8 9 10)

configure() {
  __configure_buttons mame_buttons 'MAME'
  __configure_buttons mame_buttons 'MAME 2003-Plus'

  __configure_buttons mame2003_buttons 'MAME 2003 (0.78)'

  __configure_buttons mame2010_buttons 'MAME 2010'
  __configure_buttons mame2010_buttons 'MAME 2015'
  __configure_buttons mame2010_buttons 'MAME 2016'

  __configure_buttons fbneo_buttons 'FinalBurn Neo'

  __configure_advmame
}

__configure_buttons() {
  local -n emulator_buttons=$1
  local library_name=$2
  if ! has_core_library_name "$library_name"; then
    return
  fi

  # Check if user is providing an explicit mapping
  if any_path_exists "{system_config_dir}/retroarch/$library_name/$library_name.rmp"; then
    return
  fi

  # Ensure target doesn't exist
  local target_path="$retroarch_remapping_dir/$library_name/$library_name.rmp"
  mkdir -p "$(dirname "$target_path")"
  rm -fv "$target_path"

  echo "Updating $target_path..."

  # Map to the emulator's input ids for each button index (logical layout)
  local button_index=0
  while read input_name; do
    local mapping_id=${emulator_buttons[$button_index]}
    if [ -z "$mapping_id" ]; then
      break
    fi

    local player_id
    for (( player_id=1; player_id<=$max_players; player_id++ )); do
      echo "input_player${player_id}_btn_${input_name} = \"$mapping_id\"" >> "$target_path"
    done

    ((button_index+=1))
  done < <(system_setting 'select(.controls .layout) | .controls .layout[]')
}

__configure_advmame() {
  if ! has_emulator_name 'advmame'; then
    return
  fi

  echo "Updating $autoconf_file for advmame..."
  local button_index=1

  # Inputs map to their button number (logical layout)
  declare -a buttons
  while read input_name; do
    buttons+=("$input_name=$button_index")
    ((button_index+=1))
  done < <(system_setting 'select(.controls .layout) | .controls .layout[]')

  # Update the autoconf file that will be used during controller configurations
  local buttons_csv=$(IFS=, ; echo "${buttons[*]}")
  crudini --set "$autoconf_file" '' 'advmame_layout' "\"$buttons_csv\""
}

restore() {
  while read -r library_name; do
    if ! any_path_exists "{system_config_dir}/retroarch/$library_name/$library_name.rmp"; then
      rm -fv "$retroarch_remapping_dir/$library_name/$library_name.rmp"*
    fi
  done < <(get_core_library_names)

  sed -i '/^advmame_layout/d' "$autoconf_file"
}

setup "${@}"
