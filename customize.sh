#!/usr/bin/env bash

#[ $DEBUG -ge 1 ] && set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
#[ $DEBUG -ge 3 ] && set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
#[ $DEBUG -ge 3 ] && set -o nounset                                      # Treat unset variables as an error when substituting.
#[ $DEBUG -ge 1 ] && set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
#[ $DEBUG -ge 2 ] && set -x                                               # Debugging
#[ $DEBUG -ge 1 ] && export DEBUG
                                                    # a non-zero status, or zero if no command exited with a non-zero status.
declare baseDirectory           && baseDirectory=${baseDirectory:-/home/carl/dev/sdm}
declare baseImage               && baseImage=${baseImage:-2022-09-22-raspios-bullseye-arm64-lite.img}
declare baseImageDirectory      && baseImageDirectory=${baseImageDirectory:-"baseos"}
declare hostName                && hostName=${hostName:-"rpicm4-1"}
declare downloadUrl             && downloadUrl="$("${baseDirectory}"/get_lasest_pios.py https://downloads.raspberrypi.org/ raspios full arm64 bullseye)"

declare -x logwidth
logwidth=150

source "${baseDirectory}/sdm-cparse"

logtoboth "downloadUrl=${downloadUrl}  baseDirectory=${baseDirectory} baseImage=${baseImage} baseImageDirectory=${baseImageDirectory} hostName=${hostName}"

if [ ! -d "${baseDirectory}/${baseImageDirectory}/" ] ; then
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Making directory ${baseDirectory}/${baseImageDirectory}/"
    mkdir -pv "${baseDirectory}/${baseImageDirectory}/"
else
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Skipping Making directory ${baseDirectory}/${baseImageDirectory}/"
fi

if [ ! -e "${baseDirectory}/${baseImageDirectory}/${baseImage}" ] ; then
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Downloading & extracting https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/${baseImage}.xz to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
    curlOps="" && [ "$DEBUG" -ge 3 ] && curlOps="--verbose"
    curl $curlOps https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/"${baseImage}".xz | unxz - > "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}"
else
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Skipping Downloading & extracting https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-09-26/${baseImage}.xz to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
fi

if [ ! -d "${baseDirectory}/output/" ] ; then
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Making directory ${baseDirectory}/output/"
    mkdir -pv "${baseDirectory}/output/"
else
    [ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Skipping Making directory ${baseDirectory}/output/"
fi

[ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Syncing ${baseDirectory}/${baseImageDirectory}/${baseImage} to ${baseDirectory}/output/${hostName}.img"
rsync -ah --progress "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}" "${baseDirectory}"/output/"${hostName}".img

[ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Running ${baseDirectory}/sdm --customize"
"${baseDirectory}"/sdm --customize "${baseDirectory}"/output/"${hostName}".img \
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
    --fstab "${baseDirectory}"/my-fstab \
    --cscript "${baseDirectory}"/sdm-customphase
    
[ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Running ${baseDirectory}/sdm --shrink ${baseDirectory}/output/${hostName}.img"
"${baseDirectory}"/sdm --shrink "${baseDirectory}"/output/"${hostName}".img
