# Arcade

Prefer MAME 2003 Plus or Fast Burn Neo for Arcade, then MAME if neither of those work

### FBNeo

Source: https://***REMOVED***

DAT files (https://github.com/libretro/FBNeo/tree/master/dats):

```
wget "https://github.com/libretro/FBNeo/raw/master/dats/FinalBurn%20Neo%20(ClrMame%20Pro%20XML%2C%20Arcade%20only).dat"
```

cp samples/* /home/pi/RetroPie/BIOS/fbneo/samples/
cp roms/* /home/pi/RetroPie/roms/arcade/
cp cheats/* /home/pi/RetroPie/fbneo/cheats/

scp * pi@***REMOVED***:/home/pi/RetroPie/BIOS/fbneo/samples/

Filtering:
* https://www.progettosnaps.net/catver/


### MAME

Mame 2003 DAT: https://raw.githubusercontent.com/libretro/mame2003-libretro
Mame 2003 Plus DAT: https://www.progettosnaps.net/dats/MAME/

Install lr-mame2003-plus in optional packages.

Source: https://***REMOVED***

mkdir -p /home/pi/RetroPie/BIOS/mame2003-plus/samples/

```
scp samples/* pi@***REMOVED***:/home/pi/RetroPie/BIOS/mame2003-plus/samples/
scp roms/* pi@***REMOVED***:/home/pi/RetroPie/roms/arcade/
```