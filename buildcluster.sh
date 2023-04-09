#!/usr/bin/env bash
#
SECONDS=0
export DEBUG=${DEBUG:-0}
printf "%s Started at %s.\n" "$(basename "$0")" "$(date +'%X')"
source ./assets/common.sh
#
./customize.sh
./bf_rpicm4-1.sh
./bf_rpi4b-1.sh
./bf_rpi4b-2.sh
./bf_rpi4b-3.sh
./bf-rpi4b-4.sh
#
./extfilesys.sh -v -v -o output/rpi4b-1-out.img /srv/netboot d21c0840
./extfilesys.sh -v -v -o output/rpi4b-1-out.img /srv/netboot acdce532
./extfilesys.sh -v -v -o output/rpi4b-1-out.img /srv/netboot 9fb41f35
./extfilesys.sh -v -v -o output/rpi4b-1-out.img /srv/netboot 9210668e
#
[[ -f /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img ]] && \
    mv -v /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-lite.img \
        /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-lite.img.prev

rsync --no-i-r --info=progress2 --verbose output/rpicm4-1-out.img \
    /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-lite.img

printf "$0 Completed in %s\n\n" "$(displaytime ${SECONDS})"
