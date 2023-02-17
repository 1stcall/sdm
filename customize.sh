#!/usr/bin/env bash

DEBUG=${DEBUG:-0}

[ "$DEBUG" -ge 1 ]  && set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 1 ]  && set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 1 ]  && set -o nounset                                      # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 1 ]  && set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
[ "$DEBUG" -ge 10 ] && set -x                                              # Debugging 1=extra logging, 2= verbose to commands, 3= pauses, 4= set -x
[ "$DEBUG" -ge 1 ]  && declare -x DEBUG
                                                    # a non-zero status, or zero if no command exited with a non-zero status.
declare baseDirectory           && baseDirectory=${baseDirectory:-/home/carl/dev/sdm}
declare baseImage               #&& baseImage=${baseImage:-2022-09-22-raspios-bullseye-arm64-lite.img}
declare baseImageDirectory      && baseImageDirectory=${baseImageDirectory:-"baseos"}
declare hostName                && hostName=${hostName:-"rpicm4-1"}
declare baseUrl                 && baseUrl=${baseUrl:-"https://downloads.raspberrypi.org/"}
declare downloadUrl

declare STARTBUILD=$(date)
declare STARTSEC=$(date +%s)
declare ENDBUILD=""
#
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
baseDir=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
scriptName=`basename "$(realpath ${BASH_SOURCE[0]})"`
source "${baseDir}/common.sh"
logname="${baseDir}/${scriptName}.log"
export logname
downloadUrl="$(${baseDirectory}/get_latest_pios.sh -t)"
baseImage=$(echo ${downloadUrl} | sed 's:.*/::')
baseImage=${baseImage::-3}

fDebugLog 1 "callingUser=${callingUser}"
fDebugLog 1 "downloadUrl=${downloadUrl}"
fDebugLog 1 "baseDirectory=${baseDirectory}"
fDebugLog 1 "baseImageDirectory=${baseImageDirectory}"
fDebugLog 1 "baseImage=${baseImage}"
fDebugLog 1 "hostName=${hostName}"

if [ ! -d "${baseDirectory}/${baseImageDirectory}/" ] ; then
    fDebugLog 1 "Making directory ${baseDirectory}/${baseImageDirectory}/"
    su ${callingUser} --command="mkdir -pv ${baseDirectory}/${baseImageDirectory}/"
else
    fDebugLog 1 "Skipping Making directory ${baseDirectory}/${baseImageDirectory}/"
fi

if [ ! -e "${baseDirectory}/${baseImageDirectory}/${baseImage}" ] ; then
    fDebugLog 0 "Downloading & extracting ${downloadUrl}"
    fDebugLog 5 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}" yesno
    curlOps="" && [ "$DEBUG" -ge 2 ] && curlOps="--verbose"
    su ${callingUser} --command="curl $curlOps $downloadUrl | unxz - > ${baseDirectory}/${baseImageDirectory}/${baseImage}"
else
    fDebugLog 1 "Skipping Downloading & extracting $downloadUrl"
    fDebugLog 1 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
fi

if [ ! -d "${baseDirectory}/output/" ] ; then
    fDebugLog 1 "Making directory ${baseDirectory}/output/"
    su ${callingUser} --command="mkdir -pv ${baseDirectory}/output/"
else
    fDebugLog 1 "Skipping Making directory ${baseDirectory}/output/"
fi

fDebugLog 1 "Copying ${baseDirectory}/${baseImageDirectory}/${baseImage} to ${baseDirectory}/output/${hostName}.img"
cp -av --reflink=auto "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}" "${baseDirectory}"/output/"${hostName}".img

fDebugLog 0 "Running ${baseDirectory}/sdm --customize"
"${baseDirectory}"/sdm --customize "${baseDirectory}"/output/"${hostName}".img \
    --logwidth 999 \
    --apt-dist-upgrade \
    --disable piwiz,swap \
    --dtoverlay i2c-rtc,pcf85063a,i2c_csi_dsi,dwc2,dr_mode=host \
    --dtparam i2c_vc=on \
    --l10n \
    --restart \
    --showapt \
    --showpwd \
    --svcdisable fake-hwclock \
    --wpa /etc/wpa_supplicant/wpa_supplicant.conf \
    --batch \
    --fstab "${baseDirectory}"/my-fstab \
    --plugin apt-file \
    --plugin 00mydotfiles:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 10bullseye-backports:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 20configgit \
    --plugin 50btfix:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 50enablenetfwd \
    --plugin 50instlvmxfs \
    --plugin 60pxehost:"netIface=eth1|ipAddr=192.168.1.1|dnsaddr=192.168.1.1|brdAddr=192.168.1.255|gwAddr=192.168.1.1|dhcpRange=192.168.1.2,192.168.1.10,255.255.255.0,6h|tftpRootDir=/srv/netboot/tftp/|nfsRootDir=/srv/netboot/nfs/" \
    --plugin 70devtools \
    --plugin-debug \
    --extend \
    --xmb 1024 \
    --poptions apps \
    --apps "zram-tools command-not-found bash-completion tmux systemd-container apt-transport-https" \
    --rename-pi carl \
    --password-pi letmein123 \
    --custom1=$DEBUG
#    --user carl \
#    --password-user letmein123 \
    
fDebugLog 0 "Running ${baseDirectory}/sdm --shrink ${baseDirectory}/output/${hostName}.img"
"${baseDirectory}"/sdm --shrink "${baseDirectory}"/output/"${hostName}".img || true
ENDBUILD=$(date)
fDebugLog 0 "${scriptName} started at ${STARTBUILD} and compleated at ${ENDBUILD}."
log "${scriptName} completed in $(displaytime $(( $(date +%s) - $STARTSEC )))"
exit 0
