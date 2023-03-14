#!/usr/bin/env bash
#
OLDIFS=$IFS
SECONDS=0
./customize.sh
IFS=$OLDIFS
./bf_rpicm4-1.sh
IFS=$OLDIFS
#mv -v /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img.prev
#rsync --no-i-r --info=progress2 --verbose output/rpicm4-1-out.img /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img
printf "Completed in %s mins.\n\n" $(awk -vx=${SECONDS} 'BEGIN{printf("%.2f\n",x/60)}')
