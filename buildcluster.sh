#!/usr/bin/env bash
#
set -e
#
SECONDS=0
export DEBUG=${DEBUG:-0}
printf "%s Started at %s.\n" "$(basename "$0")" "$(date +'%X')"
# shellcheck source=./assets/common.sh
source ./assets/common.sh
#
export RELEASE=${RELEASE:-bullseye}
export DEBUG=1
#
./customize.sh
./bf_rpicm4-1.sh
[[ -f /mnt/rescuedata/$(date +'%Y-%m-%d')-rpicm4-1-lite.img ]] && \
    mv -v /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-"${RELEASE}"-lite.img \
        /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-"${RELEASE}"-lite.img.prev

rsync --no-i-r --info=progress2 --verbose output/rpicm4-1-"${RELEASE}"-out.img \
    /mnt/rescuedata/"$(date +'%Y-%m-%d')"-rpicm4-1-"${RELEASE}"-lite.img &

./bf_rpi4b-1.sh
./extfilesys.sh -o output/rpi4b-1-"${RELEASE}"-out.img /srv/netboot d21c0840 &
./bf_rpi4b-2.sh
./extfilesys.sh -o output/rpi4b-2-"${RELEASE}"-out.img /srv/netboot acdce532 &
./bf_rpi4b-3.sh
./extfilesys.sh -o output/rpi4b-3-"${RELEASE}"-out.img /srv/netboot 9fb41f35 &
./bf_rpi4b-4.sh
./extfilesys.sh -o output/rpi4b-4-"${RELEASE}"-out.img /srv/netboot 9210668e &
#
wait
#
printf "$0 Completed in %s\n\n" "$(displaytime ${SECONDS})."
