for system in arcade c64 nes snes pc; do
  /opt/retropie/supplementary/skyscraper/Skyscraper --flags "unattend,skipped,videos" -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$system"
done
