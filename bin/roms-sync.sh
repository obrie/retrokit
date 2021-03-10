* [180](http://***REMOVED***games/418)
* [California Games](http://***REMOVED***games/94)
* [Frogger](http://***REMOVED***games/383)
* [Karateka](http://***REMOVED***games/354)
* [Paperboy](http://***REMOVED***games/157)
* [Pitfall](http://***REMOVED***games/269)
* [Pitstop](http://***REMOVED***games/271)
* [Popeye](http://***REMOVED***games/467)
* [Rampage](http://***REMOVED***games/160)
* [Summer Games](http://***REMOVED***games/295)
* [Winter Games](http://***REMOVED***games/310)

##############
# Commodore 64
##############

rsync -r -L platforms/c64/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/c64/
rsync -r -L platforms/c64/remaps/ pi@***REMOVED***:/opt/retropie/configs/all/retroarch/config/remaps/lr-vice/

wget -nc https://***REMOVED***California%20Games%20%281227%29.zip -O /home/pi/RetroPie/roms/c64/california\ games.zip

rsync -r -L platforms/nes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/nes/
rsync -r -L platforms/snes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/snes/
rsync -r -L platforms/nes/roms/installed/ pi@***REMOVED***:/home/pi/RetroPie/roms/nes/
