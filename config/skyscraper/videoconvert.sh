#!/bin/bash

echo 'Converting video...'
echo "Source: $1"
echo "Target: $2"

# Check if the video is already in 420p format
has_yuv420p=$(ffprobe "$1" 2>&1 | grep -c yuv420p)

if [ "$has_yuv420p" -eq 0 ]; then
  echo 'Incorrect source video format detected. Converting video to 420p format...'
  ffmpeg -i "$1" -y -pix_fmt yuv420p -acodec copy -strict experimental "$2"
else
  echo 'Video is in correct 420p format. Copying as is...'
  cp -v "$1" "$2"
fi
