#!/usr/bin/env bash

################################################################################
# Usage:    A script to convert a move to a movebarcode
# Author:   Xiao Hanyu<xiaohanyu1988@gmail.com>
# Depends:
#   ffmpeg:     get basic info of a movie and convert it to a series of images
#   graphicsmagick:
#               convert, mogrify, blur images
#   bc:         shell calculator
################################################################################

function get_duration
{
    ## [0-9]{2}:[0-9]{2}:[0-9]{2}(|\.[0-9]{1,2}) matches:
    ##      hh:mm:ss.ms
    ##      hh:mm:ss
    duration=$(ffmpeg -i $1 2>&1 | grep 'Duration' | grep -E -o "[0-9]{2}:[0-9]{2}:[0-9]{2}(|\.[0-9]{1,2})")
    duration_h=$(echo $duration | awk -F: '{print $1}')
    duration_m=$(echo $duration | awk -F: '{print $2}')
    duration_s=$(echo $duration | awk -F: '{print $3}')
    movie_seconds=$(echo "$duration_h * 3600 + $duration_m * 60 + $duration_s" | bc)
}

function get_fps
{
    fps=$(ffmpeg -i $1 2>&1 | grep -E -o "[0-9]{2}\.[0-9]{2}\ fps" | grep -E -o "[0-9]{2}\.[0-9]{2}")
}

movie=$1

get_fps $movie
get_duration $movie

## use multi-cores of cpu to improve the speed of ffmpeg, see ffmpeg man page
cpu_cores=$(cat /proc/cpuinfo | grep processor | wc -l)

time ffmpeg -i $1 -r 1 -threads $cpu_cores image%d.png
time gm mogrify -resize 0.5%x100% *png
time gm convert $(for i in `seq 1 $movie_seconds`; do ls -l image$i.png; done | awk '{print $9}') +append result1.png
time gm convert result1.png -blur 50 result2.png

# resize result2.png with a proper size
# I set new width to 2000, while keep the height intact
new_width=2000
new_geometry=$(gm identify  result2.png | awk '{print $3}' | awk -F+ '{print $1}' | sed 's/[0-9]*x/2000x/g' | sed 's/$/!/g')
gm convert -resize $new_geometry result2.png result3.png

rm image*png

if [ -e $(which xdg-open) ]; then
    xdg-open result3.png
fi
