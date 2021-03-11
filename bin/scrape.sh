# Kill emulation station
killall emulationstation

for system in arcade c64 nes snes pc; do
  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $system -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$system" -s screenscraper --flags "unattend,skipped,videos"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $system -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$system" --flags "unattend,skipped,videos"
done
