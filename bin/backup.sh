sudo dd bs=4M if=/dev/mmcblk0p2 | gzip | dd bs=4M of=/home/aaron/Downloads/Retropie/sd-retropie.iso
sudo dd bs=4M if=/dev/mmcblk0p1 | gzip | dd bs=4M of=/home/aaron/Downloads/Retropie/sd-retropie-boot.iso
