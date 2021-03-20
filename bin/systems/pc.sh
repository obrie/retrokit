#!/bin/bash

##############
# System: PC
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

DIR=$( dirname "$0" )
. $DIR/common.sh

SYSTEM="nes"
CONFIG_DIR="$APP_DIR/config/systems/$SYSTEM"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

setup() {
  # Install emulators
  sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
  sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

  # Sound driver
  sudo apt install fluid-soundfont-gm

  # Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):
}

download() {
  # Download according to settings file
  download_system "$SYSTEM"

  # Additional system-specific logic
  # https://github.com/Voljega/ExoDOSConverter
}

# fix_filenames() {
#   # ----- Uppercase filenames
#   rename 'y/a-z/A-Z/' *

#   # ----- Uppercase filenames inside CUE files
#   sed -i -e 's/\(.*\)/\U\1/' *.CUE 2> /dev/null || true
# }

# delete_unused_files {
#   # ----- Remove extra files if they exist
#   rm *.BA1 2> /dev/null || true
#   rm DOSBOX.CONF* 2> /dev/null || true
#   rm *.BAK 2> /dev/null || true
# }

# # https://github.com/sduensin/retropie-tools
# create_configs() {
#     BASE=$(basename `pwd`)
#     echo Reading and sorting `pwd`...
#     find . -type d -print0 | sort -r -z | while IFS= read -rd '' CFGDIR; do
#       pushd "${CFGDIR}" > /dev/null
#       echo Working on `pwd`...
      
#       # ----- Uppercase filenames
#       rename 'y/a-z/A-Z/' *
      
#       # ----- Are we in a game top level folder or subfolder?
#       GAME=
#       PARENT=$(basename `cd .. && pwd`)
#       if [[ "x${PARENT}" == "x${BASE}" ]]; then
#         GAME=$(basename `pwd`)
#         AUTOEXEC="${DOSGAMES}/${GAME^^}/AUTOEXEC.BAT"
        
#         # ----- Find game INI
#         INI=$(ls -1 MEAGRE/INIFILE/*.INI | head -n1)
        
#         # ----- Create script for RetroPie
#         SCRIPT="~/RetroPie/roms/pc/${GAME,,}.sh"
#         echo "#!/bin/bash" > "${SCRIPT}"
#         echo "/opt/retropie/emulators/dosbox/bin/dosbox -conf /opt/retropie/configs/pc/dosbox-SVN.conf -conf ${AUTOEXEC} -exit" >> "${SCRIPT}"
#         chmod a+x "${SCRIPT}"

#         # ----- Extract proper AUTOEXEC.BAT
#         echo "[autoexec]" > "${AUTOEXEC}"
#         echo "@ECHO OFF" >> "${AUTOEXEC}"
#         echo "MOUNT -u C" >> "${AUTOEXEC}"
#         if [[ -e DOSBOX.CONF ]]; then
#           FOUND=false
#           COUNTER=0
#           cat DOSBOX.CONF | sed $'s/\r$//' | while IFS='' read -r LINE || [[ -n "${LINE}" ]]; do
#             trim TRIMMED ${LINE}
#             UPPER=${TRIMMED^^}
#             if [[ ${FOUND} == false ]]; then
#               # Find start of autoexec section
#               if [[ "x${UPPER}" == "x[AUTOEXEC]" ]]; then
#                 FOUND=true
#               fi
#             else
#               FIRST=${UPPER:0:1}
#               # Remove comments
#               if [[ "x${FIRST}" == "x#" ]]; then continue; fi
#               # Remove leading @s
#               if [[ "x${FIRST}" == "x@" ]]; then 
#                 TRIMMED=${TRIMMED#?}
#                 UPPER=${UPPER#?}
#               fi
#               # Remove first two "CD" statements
#               if [[ ${COUNTER} -lt 2 ]]; then
#                 if [[ "x${UPPER}" == "xCD.." || "x${UPPER}" == "xCD .." ]]; then 
#                   COUNTER="$((COUNTER+1))";
#                   continue;
#                 fi
#               fi
#               # Redirect CDs to NUL since half of them make no sense
#               if [[ "x${UPPER:0:2}" == "xCD" ]]; then TRIMMED="${TRIMMED} > NUL"; fi
#               # Fix MOUNT and IMGMOUNT paths
#               if [[ "x${UPPER:0:5}" == "xMOUNT" || "x${UPPER:0:8}" == "xIMGMOUNT" ]]; then
#                 UPPER=${UPPER//\\/\/}
#                 UPPER=${UPPER//\.\/GAMES\//${DOSGAMES}\/}
#                 # Lower case the IMGMOUNT type parameter, change "cdrom" to "iso"
#                 UPPER=${UPPER/ -T ISO/ -t iso}
#                 UPPER=${UPPER/ -T CDROM/ -t iso}
#                 UPPER=${UPPER/ -T FLOPPY/ -t floppy}
#                 UPPER=${UPPER/ -T HDD/ -t hdd}
#                 # Lower case the filesystem parameter
#                 UPPER=${UPPER/ -FS ISO/ -fs iso}
#                 UPPER=${UPPER/ -FS FAT/ -fs fat}
#                 UPPER=${UPPER/ -FS NONE/ -fs none}
#                 TRIMMED=${UPPER}
#               fi
#               # Add to autoexec
#               echo "${TRIMMED}" >> "${AUTOEXEC}"
#             fi
#           done
#         fi

#       fi
      
#       popd > /dev/null
#     done

#   else  # ----- It's a game directory

#     # ----- Uppercase filenames
#     rename 'y/a-z/A-Z/' *

#     # ----- Remove extra files if they exist
#     rm *.BA1 2> /dev/null || true
#     rm DOSBOX.CONF* 2> /dev/null || true
#     rm *.BAK 2> /dev/null || true

#     # ----- Uppercase filenames inside CUE files
#     sed -i -e 's/\(.*\)/\U\1/' *.CUE 2> /dev/null || true
#   fi

#   popd > /dev/null
# done
# }


scrape() {
  scrape_system "$SYSTEM"
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift
"$command" "$@"
