# NES

## Emulators

Preferred:

1. lr-fbneo
2. lr-fceumm

## ROMs

Primary Sources:

* https://***REMOVED***
* https://***REMOVED***

Secondary Sources:

* https://***REMOVED***
* https://***REMOVED***
* https://***REMOVED***

### FBNeo

Script:

```
wget "https://github.com/libretro/FBNeo/raw/master/dats/FinalBurn%20Neo%20(ClrMame%20Pro%20XML%2C%20NES%20Games%20only).dat"
https://***REMOVED***
```

Filter list regex:

```
^ +<(game|year|manufacturer|rom|drive|/game).+$\n| +<description>|</description>
```

### Installation

* [Arkanoid](../platforms/nes/roms/fbneo/arkanoid.zip)
* [Arkanoid II](../platforms/nes/roms/fbneo/arkanoidii.zip)
* [Bubble Bobble](../platforms/nes/roms/fbneo/bubblebobble.zip)
* [California games](../platforms/nes/roms/fbneo/californiagames.zip)
* [Contra](../platforms/nes/roms/fbneo/contra.zip)
* [Double Dragon](../platforms/nes/roms/fbneo/doubledragon.zip)
* [Double Dragon II](../platforms/nes/roms/fbneo/doubldraii.zip)
* [Double Dragon III](../platforms/nes/roms/fbneo/doubldraiii.zip)
* [Double Dribble](../platforms/nes/roms/fbneo/doubledribble.zip)
* [Duck Hunt](../platforms/nes/roms/fbneo/duckhunt.zip)
* [Karateka](../platforms/nes/roms/fbneo/karateka.zip)
* [Little Mermaid](../platforms/nes/roms/fbneo/littlmer.zip)
* [Mike Tyson's Punch-Out!!!](../platforms/nes/roms/fbneo/miketysspunout.zip)
* [Ms. Pac Man](../platforms/nes/roms/fbneo/mspacman.zip)
* [Pac Man](../platforms/nes/roms/fbneo/pacman.zip)
* [Popeye](../platforms/nes/roms/fbneo/popeye.zip)
* [Punch-Out!!](../platforms/nes/roms/fbneo/punchout.zip)
* [Rampage](../platforms/nes/roms/fbneo/rampage.zip)
* [Paperboy](../platforms/nes/roms/fbneo/paperboy.zip)
* [R.C. Pro-Am](../platforms/nes/roms/fbneo/rcproam.zip)
* [Simpsons, The - Bart vs. the Space Mutants](../platforms/nes/roms/fbneo/simpsbarvsspamu.zip)
* [Simpsons, The - Bart vs. the World](../platforms/nes/roms/fbneo/simpsbarvswor.zip)
* [Simpsons, The - Bartman Meets Radioactive Man](../platforms/nes/roms/fbneo/simpsbarmeeradman.zip)
* [Skate or Die](../platforms/nes/roms/fbneo/skateordie.zip)
* [Skate or Die 2 - The Search for Double Trouble](../platforms/nes/roms/fbneo/skateordie2.zip)
* [Super Mario Bros.](../platforms/nes/roms/fbneo/smb.zip)
* [Super Mario Bros. 2](../platforms/nes/roms/fbneo/smb2.zip)
* [Super Mario Bros. 3](../platforms/nes/roms/fbneo/smb3.zip)
* [Teenage Mutant Ninja Turtles](../platforms/nes/roms/fbneo/tmnt.zip)
* [Teenage Mutant Ninja Turtles II - The Arcade Game](../platforms/nes/roms/fbneo/tmntiiarcgam.zip)
* [Teenage Mutant Ninja Turtles III - The Manhattan Project](../platforms/nes/roms/fbneo/tmntiii.zip)
* [Tetris](../platforms/nes/roms/fbneo/tetris.zip)
* [Track & Field](../platforms/nes/roms/fbneo/trackfield.zip)
* [Winter Games](../platforms/nes/roms/fbneo/wintergames.zip)

Command:

```
ln -s ../fbneo/arkanoid.zip installed/arkanoid.zip
ln -s ../fbneo/bubblebobble.zip installed/bubblebobble.zip
ln -s ../fbneo/californiagames.zip installed/californiagames.zip
ln -s ../fbneo/contra.zip installed/contra.zip
ln -s ../fbneo/doubledragon.zip installed/doubledragon.zip
ln -s ../fbneo/doubldraii.zip installed/doubldraii.zip
ln -s ../fbneo/doubldraiii.zip installed/doubldraiii.zip
ln -s ../fbneo/doubledribble.zip installed/doubledribble.zip
ln -s ../fbneo/duckhunt.zip installed/duckhunt.zip
ln -s ../fbneo/littlmer.zip installed/littlmer.zip
ln -s ../fbneo/miketysspunout.zip installed/miketysspunout.zip
ln -s ../fbneo/mspacman.zip installed/mspacman.zip
ln -s ../fbneo/pacman.zip installed/pacman.zip
ln -s ../fbneo/popeye.zip installed/popeye.zip
ln -s ../fbneo/punchout.zip installed/punchout.zip
ln -s ../fbneo/rampage.zip installed/rampage.zip
ln -s ../fbneo/paperboy.zip installed/paperboy.zip
ln -s ../fbneo/rcproam.zip installed/rcproam.zip
ln -s ../fbneo/simpsbarvsspamu.zip installed/simpsbarvsspamu.zip
ln -s ../fbneo/simpsbarvswor.zip installed/simpsbarvswor.zip
ln -s ../fbneo/simpsbarmeeradman.zip installed/simpsbarmeeradman.zip
ln -s ../fbneo/skateordie.zip installed/skateordie.zip
ln -s ../fbneo/skateordie2.zip installed/skateordie2.zip
ln -s ../fbneo/smb.zip installed/smb.zip
ln -s ../fbneo/smb2.zip installed/smb2.zip
ln -s ../fbneo/smb3.zip installed/smb3.zip
ln -s ../fbneo/tmnt.zip installed/tmnt.zip
ln -s ../fbneo/tmntiiarcgam.zip installed/tmntiiarcgam.zip
ln -s ../fbneo/tmntiii.zip installed/tmntiii.zip
ln -s ../fbneo/tetris.zip installed/tetris.zip
ln -s ../fbneo/trackfield.zip installed/trackfield.zip
ln -s ../fbneo/wintergames.zip installed/wintergames.zip
```