##############
# Variables
##############

retropie_configs_dir="/opt/retropie/configs/all"
retroarch_config_dir="$retropie_configs_dir/retroarch/config"

##############
# Commodore 64
##############

# # Retrieve all:
# wget -m -np -c -U "eye02" -w 2 -R "index.html*" "https://***REMOVED***"

c64_system="VICE x64"
c64_retroarch_dir="$retroarch_config_dir/$c64_system"

scp ./platforms/c64/configs/* pi@***REMOVED***:"$c64_retroarch_dir/"

c64_source="https://***REMOVED***Commodore%2064"
c64_target="/home/pi/RetroPie/roms/c64/"

# Core Options (https://retropie.org.uk/docs/RetroArch-Core-Options/)
find "$c64_retroarch_dir" -iname "*overrides" | while read override_file; do
  opt_name=$(basename -s .overrides "$override_file")
  opt_file="$c64_retroarch_dir/$opt_name"
  cp $retropie_configs_dir/retroarch-core-options.cfg "$opt_file"
  crudini --merge "$opt_file" < "$override_file"
done

rsync -r platforms/c64/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/c64/
rsync -r platforms/c64/remaps/ pi@***REMOVED***:/opt/retropie/configs/all/retroarch/config/remaps/lr-vice/
