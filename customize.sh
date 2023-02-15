#!/usr/bin/env bash

<<<<<<< HEAD
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
=======
[ "$DEBUG" -ge 1 ] && set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 1 ] && set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 1 ] && set -o nounset                                      # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 1 ] && set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
#[ $DEBUG -ge 2 ] && set -x                                               # Debugging
[ $DEBUG -ge 1 ] && export DEBUG
                                                    # a non-zero status, or zero if no command exited with a non-zero status.
declare -x baseDirectory           && baseDirectory=${baseDirectory:-/home/carl/dev/sdm}
declare -x baseImage               #&& baseImage=${baseImage:-2022-09-22-raspios-bullseye-arm64-lite.img}
declare -x baseImageDirectory      && baseImageDirectory=${baseImageDirectory:-"baseos"}
declare -x hostName                && hostName=${hostName:-"rpicm4-1"}
declare -x baseUrl                 && baseUrl=${baseUrl:-"https://downloads.raspberrypi.org/"}
declare -x downloadUrl
>>>>>>> c4fdbf5e8e6d315e90e6f14b77689a68ba94d3f4

downloadUrl="$("${baseDirectory}"/get_latest_pios.sh -t)"
baseImage=$(echo ${downloadUrl} | sed 's:.*/::')
baseImage=${baseImage::-3}

function fDebugLog() {
    OLDIFS=${IFS}
    IFS=''
    logLvl=${1:-99}             # Logging level to log message at. Default 99.
    logMsg="${2:-"NO MSG"}"     # Messge to log.
    logWait="${3:-"nowait"}"    # wait="Press any key to continue."
                                # yesno="Do you wish to continue (Y/N)?"
                                # nowait=Don't wait.

<<<<<<< HEAD
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
=======
    if [ $logLvl -le $DEBUG ]; then
        printf "[${logLvl}/${DEBUG}] %s\n" ${logMsg}
        if [ "$logWait" == "wait" ]; then
            printf "Press any key to continue...\n"
            read -n 1 -s -r
        elif [ "$logWait" == "yesno" ]; then
            printf "Do you wish to continue? (Y/N)\n"
            while true
                do
                    read -r -n 1 -s choice
                    case "$choice" in
                        n|N) exit 1;;
                        y|Y) break;;
                        *) echo 'Response not valid';;
                    esac
            done
        fi
    fi
    IFS=${OLDIFS}
}
export -f fDebugLog

IFS=''
fDebugLog 1 "downloadUrl=${downloadUrl}"
fDebugLog 1 "baseDirectory=${baseDirectory}"
fDebugLog 1 "baseImageDirectory=${baseImageDirectory}"
fDebugLog 1 "baseImage=${baseImage}"
fDebugLog 1 "hostName=${hostName}"

if [ ! -d "${baseDirectory}/${baseImageDirectory}/" ] ; then
    fDebugLog 1 "Making directory ${baseDirectory}/${baseImageDirectory}/"
    mkdir -pv "${baseDirectory}/${baseImageDirectory}/"
else
    fDebugLog 1 "Skipping Making directory ${baseDirectory}/${baseImageDirectory}/"
fi

if [ ! -e "${baseDirectory}/${baseImageDirectory}/${baseImage}" ] ; then
    fDebugLog 0 "Downloading & extracting ${downloadUrl}"
    fDebugLog 0 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}" yesno
    curlOps="" && [ "$DEBUG" -ge 2 ] && curlOps="--verbose"
    curl $curlOps $downloadUrl | unxz - > "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}"
else
    fDebugLog 1 "Skipping Downloading & extracting $downloadUrl"
    fDebugLog 1 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
fi

if [ ! -d "${baseDirectory}/output/" ] ; then
    fDebugLog 1 "Making directory ${baseDirectory}/output/"
    mkdir -pv "${baseDirectory}/output/"
else
    fDebugLog 1 "Skipping Making directory ${baseDirectory}/output/"
fi

fDebugLog 1 "Syncing ${baseDirectory}/${baseImageDirectory}/${baseImage} to ${baseDirectory}/output/${hostName}.img"
cp -av --reflink "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}" "${baseDirectory}"/output/"${hostName}".img

fDebugLog 0 "Running ${baseDirectory}/sdm --customize"
"${baseDirectory}"/sdm --customize "${baseDirectory}"/output/"${hostName}".img \
>>>>>>> c4fdbf5e8e6d315e90e6f14b77689a68ba94d3f4
    --apt-dist-upgrade \
    --disable piwiz,swap \
    --dtoverlay i2c-rtc,pcf85063a,i2c_csi_dsi,dwc2,dr_mode=host \
    --dtparam i2c_vc=on \
    --l10n --password-user Manager09 \
    --restart \
    --showapt \
    --showpwd \
    --svcdisable fake-hwclock \
    --user carl \
    --wpa /etc/wpa_supplicant/wpa_supplicant.conf \
    --batch \
    --fstab "${baseDirectory}"/my-fstab \
<<<<<<< HEAD
    --cscript "${baseDirectory}"/sdm-customphase
    
[ "$DEBUG" -ge 1 ] && logtoboth "[DEBUG=$DEBUG] Running ${baseDirectory}/sdm --shrink ${baseDirectory}/output/${hostName}.img"
"${baseDirectory}"/sdm --shrink "${baseDirectory}"/output/"${hostName}".img
=======
    --plugin apt-file \
    --plugin btfix:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin bullseye-backports:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin mydotfiles:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin configgit \
    --plugin enablenetfwd \
    --plugin instlvmxfs \
    --plugin-debug \
    --extend \
    --xmb 1024 \
    --poptions apps \
    --apps "zram-tools command-not-found bash-completion tmux"
    
fDebugLog 0 "Running ${baseDirectory}/sdm --shrink ${baseDirectory}/output/${hostName}.img" yesno
"${baseDirectory}"/sdm --shrink "${baseDirectory}"/output/"${hostName}".img || true

exit 0
>>>>>>> c4fdbf5e8e6d315e90e6f14b77689a68ba94d3f4
