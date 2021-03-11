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
wget -nc $c64_source/180%20%2813%29.zip -O $c64_target/180.zip
wget -nc $c64_source/California%20Games%20%281227%29.zip -O $c64_target/california\ games.zip
wget -nc $c64_source/Frogger%20%2812717%29.zip -O $c64_target/frogger.zip
wget -nc $c64_source/Karateka%20%284049%29.zip -O $c64_target/karateka.zip
wget -nc $c64_source/Paperboy%20%285549%29.zip -O $c64_target/paperboy.zip
wget -nc $c64_source/Pitfall%20-%20Pitfall%20Harry%27s%20Jungle%20Adventure%20%285731%29.zip -O $c64_target/pitfall.zip
wget -nc $c64_source/Pitstop%20%285734%29.zip -O $c64_target/pitstop.zip
wget -nc $c64_source/Popeye%20%285829%29.zip -O $c64_target/popeye.zip
wget -nc $c64_source/Rampage%20%286200%29.zip -O $c64_target/rampage.zip
wget -nc $c64_source/Summer%20Games%20%287545%29.zip -O $c64_target/summer\ games.zip
wget -nc $c64_source/Winter%20Games%20%288620%29.zip -O $c64_target/winter\ games.zip

# Core Options (https://retropie.org.uk/docs/RetroArch-Core-Options/)
find "$c64_retroarch_dir" -iname "*overrides" | while read override_file; do
  opt_name=$(basename -s .overrides "$override_file")
  opt_file="$c64_retroarch_dir/$opt_name"
  cp $retropie_configs_dir/retroarch-core-options.cfg "$opt_file"
  crudini --merge "$opt_file" < "$override_file"
done

rsync -r platforms/c64/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/c64/
rsync -r platforms/c64/remaps/ pi@***REMOVED***:/opt/retropie/configs/all/retroarch/config/remaps/lr-vice/

###############
# NES
###############

rsync -r platforms/nes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/nes/
rsync -r platforms/snes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/snes/
rsync -r platforms/nes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/nes/

###############
# Playstation
###############

https://***REMOVED***