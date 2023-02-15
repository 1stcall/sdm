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
declare RESTORE=$(echo -en '\033[0m')
declare RED=$(echo -en '\033[00;31m')
declare GREEN=$(echo -en '\033[00;32m')
declare YELLOW=$(echo -en '\033[00;33m')
declare BLUE=$(echo -en '\033[00;34m')
declare MAGENTA=$(echo -en '\033[00;35m')
declare PURPLE=$(echo -en '\033[00;35m')
declare CYAN=$(echo -en '\033[00;36m')
declare LIGHTGRAY=$(echo -en '\033[00;37m')
declare LRED=$(echo -en '\033[01;31m')
declare LGREEN=$(echo -en '\033[01;32m')
declare LYELLOW=$(echo -en '\033[01;33m')
declare LBLUE=$(echo -en '\033[01;34m')
declare LMAGENTA=$(echo -en '\033[01;35m')
declare LPURPLE=$(echo -en '\033[01;35m')
declare LCYAN=$(echo -en '\033[01;36m')
declare WHITE=$(echo -en '\033[01;37m')
declare scriptName=$(basename -- "${0}")
declare LOGPREFIX=${LOGPREFIX:-${scriptName}}

callingUser=$(who am i | awk '{print $1}')
downloadUrl=$(su ${callingUser} --command "${baseDirectory}/get_latest_pios.sh -t")
baseImage=$(echo ${downloadUrl} | sed 's:.*/::')
baseImage=${baseImage::-3}

source common.sh

IFS=''
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
    --plugin 60pxehost:"netIface=eth1|ipAddr=192.168.1.1|dnsaddr=192.168.1.1|brdAddr=192.168.1.255|gwAddr=192.168.1.1|dhcpRange=192.168.1.2,192.168.1.10,255.255.255.0,6h|tftpRoorDir=/srv/netboot/tftp/|nfsRoorDir=/srv/netboot/nfs/" \
    --plugin-debug \
    --extend \
    --xmb 1024 \
    --poptions apps \
    --apps "zram-tools command-not-found bash-completion tmux systemd-container" \
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
