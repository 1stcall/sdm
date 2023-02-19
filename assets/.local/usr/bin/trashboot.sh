#!/usr/bin/env bash
#
#   - Script to trash the pi boot partition and reboot into the rescue environment.
#
[[ ! $EUID -eq 0 ]] && printf "? Please run as root: sudo $0 $*\n" && exit 1
mkdir /boot/_startfiles/
mv -v /boot/start* /boot/_startfiles/
reboot
exit 0
