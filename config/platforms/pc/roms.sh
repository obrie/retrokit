#!/bin/bash

# set -ex

# DIR=$(dirname "$0")
# APP_DIR=$(cd "$DIR/../../.." && pwd)
# DOWNLOAD_DIR="$APP_DIR/tmp/pc"
# mkdir -p "$DOWNLOAD_DIR"

# # Install config
# ROMS_DIR="/home/pi/RetroPie/roms/pc"
# FILES_DIR="$ROMS_DIR/.files"

# # Torrent config
# SEED_TIME=0
# TORRENT_FILE="$DOWNLOAD_DIR/exodos.torrent"
# TORRENT_FILTER="$TORRENT_FILE.filter"
# TORRENT_DIR="$DOWNLOAD_DIR/eXoDOS/eXo/eXoDOS"

# usage() {
#   echo "usage: $0 [command]"
#   exit 1
# }

# download_torrent() {
#   if [ ! -f "$TORRENT_FILE" ]; then
#     wget -nc "https://***REMOVED***" -O "$TORRENT_FILE"
#   fi
# }

# install_torrent() {
#   download_torrent

#   # Create directories
#   mkdir -p "$FILES_DIR"

#   # Create torrent filters
#   jq -r '.default[]' "$DIR/roms.json" > "$TORRENT_FILTER"

#   # Filter Torrent
#   select_files=$(aria2c -S "$TORRENT_FILE" | grep -F -f "$TORRENT_FILTER" | cut -d"|" -f 1 | tr -d " " | tr '\n' ',' | sed 's/,*$//g')

#   # Download files
#   aria2c "$TORRENT_FILE" -d "$DOWNLOAD_DIR" --select-file="$select_files" --seed-time=$SEED_TIME
#   ls "$TORRENT_DIR" > "$TORRENT_FILE.extras"
#   comm -13 "$TORRENT_FILTER" "$TORRENT_FILE.extras" | xargs -I{} rm "$TORRENT_DIR/{}"

#   # Extract files
#   while read file; do
#     name=$(basename $file -s .zip)
#     if [ ! -f "$FILES_DIR/$name" ]; then
#       unzip -o "$TORRENT_DIR/$file" -d "$FILES_DIR/"
#     fi
#   done < $TORRENT_FILTER
# }

# install() {
#   install_torrent
# }

# if [[ $# -gt 1 ]]; then
#   usage
# fi

# command=${1:-install}
# "$command"

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

# https://github.com/sduensin/retropie-tools/issues/2

# https://github.com/sduensin/retropie-tools/blob/master/import-eXoDOS.sh

# #!/bin/bash -e

# # ----- License --------------------------------------------------------------
# #
# #  import-eXoDOS
# #
# #  Copyright 2017 Scott Duensing <scott@duensing.com>
# #
# #  This work is free. You can redistribute it and/or modify it under the
# #  terms of the Do What The Fuck You Want To Public License, Version 2,
# #  as published by Sam Hocevar. See the COPYING file or visit 
# #  http://www.wtfpl.net/ for more details.
# #
# # ----- History --------------------------------------------------------------
# #
# #  18-AUG-2017 - Initial Release
# #
# # ----------------------------------------------------------------------------


# # ----- Helper Functions -----------------------------------------------------

# function escapeXml() {
#   local __RESULT=$1
#   local __VAR=${*:2}
#   __VAR=$(echo ${__VAR} | sed -e 's~&~\&amp;~g' -e 's~<~\&lt;~g' -e 's~>~\&gt;~g')
#   eval $__RESULT=\${__VAR}
# }

# function findPath() {
#   local __RESULT=$1
#   local __SOURCE=$2
#   local __DIR=
#   while [[ -h "${__SOURCE}" ]]; do
#     __DIR="$( cd -P "$( dirname "${__SOURCE}" )" && pwd )"
#     __SOURCE="$(readlink "${__SOURCE}")"
#     # If $__SOURCE was a relative symlink, we need to resolve it
#     # relative to the path where the symlink file was located.
#     [[ ${__SOURCE} != /* ]] && __SOURCE="${__DIR}/${__SOURCE}"
#   done
#   __DIR="$( cd -P "$( dirname "${__SOURCE}" )" && pwd )"
#   eval $__RESULT=\${__DIR}
# }

# function trim() {
#   local __RESULT=$1
#   local __VAR="${*:2}"
#   # remove leading whitespace characters
#   __VAR="${__VAR#"${__VAR%%[![:space:]]*}"}"
#   # remove trailing whitespace characters
#   __VAR="${__VAR%"${__VAR##*[![:space:]]}"}"
#   eval $__RESULT=\${__VAR}
# }
                        
# findPath SCRIPTDIR "${BASH_SOURCE[0]}"
# SCRIPT="${SCRIPTDIR}/`basename $0`"

# # ----------------------------------------------------------------------------


# # ----- Check command line
# DOSGAMES=$1
# if [[ ! -d "${DOSGAMES}/!dos" && ! -d "${DOSGAMES}/!DOS" ]]; then
#   echo "Usage:  `basename $0` 'pathToExoDos'"
#   exit 1
# fi

# # ----- Start new gamelist.xml
# GAMELIST=~/.emulationstation/gamelists/pc/gamelist.xml
# if [[ -e "${GAMELIST}" ]]; then
#   cp -f "${GAMELIST}" "${GAMELIST}.bak"
# fi
# echo "<?xml version=\"1.0\"?>" > "${GAMELIST}"
# echo "<gameList>" >> "${GAMELIST}"

# # ----- Uppercase game directories before we start
# pushd "${DOSGAMES}" > /dev/null
# rename 'y/a-z/A-Z/' *

# # ----- Iterate over all game directories and add "!DOS" to the start of the list
# echo Reading and sorting `pwd`...
# unset DIRLIST i
# DIRLIST[i++]="!DOS"
# while IFS= read -rd '' DIR; do
#   DIRLIST[i++]="${DIR}"
# done < <(find . -type d -not \( -path "./\!dos" -prune \) -not \( -path "./\!DOS" -prune \) -print0 | sort -r -z)
# for DIR in "${DIRLIST[@]}"; do
#   pushd "${DIR}" > /dev/null

#   echo Working on `pwd`...

#   # ----- Is this the config directory?
#   if [[ "x${DIR^^}" == "x!DOS" ]]; then

#     # ----- Iterate over all config directories
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
        
#         # ----- Find title
#         TITLE=$(cat "${INI}" | grep -i ^Name= | head -n1 | tr -d '\r\n')
#         trim TITLE ${TITLE}
#         escapeXml TITLE ${TITLE:5}
        
#         # ----- Find description
#         DESCRIPTION=$(cat "${INI}" | grep -i ^About= | head -n1 | tr -d '\r\n')
#         trim DESCRIPTION ${DESCRIPTION:6}
#         escapeXml DESCRIPTION $(cat MEAGRE/ABOUT/${DESCRIPTION^^})
        
#         # ----- Find image (Box, title, then screen shot)
#         IMAGE=$(cat "${INI}" | grep -i ^Front01= | head -n1 | tr -d '\r\n')
#         trim IMAGE ${IMAGE:8}
#         WHERE="FRONT"
#         if [[ "x${IMAGE}" == "x" ]]; then
#           IMAGE=$(cat "${INI}" | grep -i ^Title01= | head -n1 | tr -d '\r\n')
#           trim IMAGE ${IMAGE:8}
#           WHERE="TITLE"
#           if [[ "x${IMAGE}" == "x" ]]; then
#             IMAGE=$(cat "${INI}" | grep -i ^Screen01= | head -n1 | tr -d '\r\n')
#             trim IMAGE ${IMAGE:9}
#             WHERE="SCREEN"
#           fi
#         fi
#         if [[ "x${IMAGE}" != "x" ]]; then
#           escapeXml IMAGE "${DOSGAMES}/!DOS/${GAME^^}/MEAGRE/${WHERE}/${IMAGE^^}"
#         fi
        
#         # ----- Find release date (only year)
#         RELEASE=$(cat "${INI}" | grep -i ^Year= | head -n1 | tr -d '\r\n')
#         trim RELEASE ${RELEASE:5}
#         escapeXml RELEASE ${RELEASE}0101T000000
        
#         # ----- Find Developer
#         DEVELOPER=$(cat "${INI}" | grep -i ^Developer= | head -n1 | tr -d '\r\n')
#         trim DEVELOPER ${DEVELOPER:10}
#         escapeXml DEVELOPER ${DEVELOPER}
        
#         # ----- Find Publisher
#         PUBLISHER=$(cat "${INI}" | grep -i ^Publisher= | head -n1 | tr -d '\r\n')
#         trim PUBLISHER ${PUBLISHER:10}
#         escapeXml PUBLISHER ${PUBLISHER}
        
#         # ----- Find Genre
#         GENRE=$(cat "${INI}" | grep -i ^Genre= | head -n1 | tr -d '\r\n')
#         trim GENRE ${GENRE:6}
#         escapeXml GENRE ${GENRE}
        
#         # ----- Add to gamelist.xml
#         echo -e "\t<game>" >> "${GAMELIST}"
#         echo -e "\t\t<path>./${GAME,,}.sh</path>" >> "${GAMELIST}"
#         echo -e "\t\t<name>${TITLE}</name>" >> "${GAMELIST}"
#         echo -e "\t\t<desc>${DESCRIPTION}</desc>" >> "${GAMELIST}"
#         echo -e "\t\t<releasedate>${RELEASE}</releasedate>" >> "${GAMELIST}"
#         echo -e "\t\t<developer>${DEVELOPER}</developer>" >> "${GAMELIST}"
#         echo -e "\t\t<publisher>${PUBLISHER}</publisher>" >> "${GAMELIST}"
#         echo -e "\t\t<genre>${GENRE}</genre>" >> "${GAMELIST}"
#         echo -e "\t\t<image>${IMAGE}</image>" >> "${GAMELIST}"
#         echo -e "\t</game>" >> "${GAMELIST}"
        
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
# popd > /dev/null

# # ----- End gamelist
# echo "</gameList>" >> "${GAMELIST}"

# echo Finished!