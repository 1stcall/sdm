#!/usr/bin/env bash

set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
set -o nounset                                      # Treat unset variables as an error when substituting.
set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
                                                    # a non-zero status, or zero if no command exited with a non-zero status.
declare baseDirectory="/home/carl/dev/sdm"
declare baseImage="2022-09-22-raspios-bullseye-arm64-lite.img"
declare baseImageDirectory="baseos"
declare hostName="rpicm4-1"

if [ ! -d "${baseDirectory}/${baseImageDirectory}/" ] ; then
    mkdir -pv "${baseDirectory}/${baseImageDirectory}/"
fi

if [ ! -e "${baseDirectory}/${baseImageDirectory}/${baseImage}" ] ; then
    curl --verbose https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/${baseImage}.xz | unxz - > ${baseDirectory}/${baseImageDirectory}/${baseImage}
fi

if [ ! -d "${baseDirectory}/output/" ] ; then
    mkdir -pv "${baseDirectory}/output/"
fi

rsync -ah --progress ${baseDirectory}/${baseImageDirectory}/${baseImage} ${baseDirectory}/output/${hostName}.img

${baseDirectory}/sdm --customize ${baseDirectory}/output/${hostName}.img \
    --apps "zram-tools nmap tmux git command-not-found bash-completion gparted btrfs-progs systemd-container jq" \
    --apt-dist-upgrade \
    --disable piwiz,swap \
    --dtoverlay i2c-rtc,pcf85063a,i2c_csi_dsi,dwc2,dr_mode=host \
    --dtparam i2c_vc=on \
    --l10n --password-user Manager09 \
    --poptions apps \
    --restart \
    --showapt \
    --showpwd \
    --svcdisable fake-hwclock \
    --user carl \
    --wpa /etc/wpa_supplicant/wpa_supplicant.conf \
    --extend \
    --xmb 2049 \
    --batch \
    --fstab ${baseDirectory}/my-fstab \
    --cscript ${baseDirectory}/sdm-customphase
    
${baseDirectory}/sdm --shrink ${baseDirectory}/output/${hostName}.img
