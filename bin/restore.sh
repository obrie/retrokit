gunzip --stdout PiOS.img.gz | sudo dd bs=4M of=/dev/mmcblk0p2
