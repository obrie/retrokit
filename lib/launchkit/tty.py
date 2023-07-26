import sys
from array import array
from fcntl import ioctl

if len(sys.argv) != 3:
  print('Usage: ioctl /dev/ttyX <graphics|text>')
  quit()

fd = open(sys.argv[1], 'wb')

if sys.argv[2] == 'graphics':
  # KDSETMODE, parameter 0x01 (KD_GRAPHICS)
  ioctl(fd, 0x4B3A, 0x01)
elif sys.argv[2] == 'text':
  # KDSETMODE, parameter 0x00 (KD_TEXT)
  ioctl(fd, 0x4B3A, 0x00)

  # Clear screen
  fd.write(b'\033c')

# VT_SETMODE (0x5602), parameter 0x00 (VT_AUTO)
buf = array('h', [0])
buf[0] = 0
ioctl(fd, 0x05602, buf)

fd.close()
