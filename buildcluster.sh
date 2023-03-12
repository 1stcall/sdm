#!/usr/bin/env bash
#
SECONDS=0
./customize.sh
./bf_rpicm4-1.sh
./bf_rpi4b-1.sh
./extfilesys.sh -v -v -o output/rpi4b-1-out.img /srv/netboot d21c0840
mv -v /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img /mnt/rescuedata/$(date +'%Y-%M-%d')-rpicm4-1-lite.img.prev
rsync --no-i-r --info=progress2 --verbose output/rpicm4-1-out.img /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img
printf "Completed in %s mins.\n\n" $(awk -vx=${SECONDS} 'BEGIN{printf("%.2f\n",x/60)}')
