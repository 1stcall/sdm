#!/usr/bin/env bash
#
declare STARTSEC
STARTSEC=$(date +%s)
declare STARTBUILD
STARTBUILD=$(date --date="@${STARTSEC}")
declare ENDBUILD
ENDBUILD=
declare DEBUG
DEBUG=${DEBUG:-0}
declare BASEIMG
BASEIMG=${BASEIMG:-""}
#
[ "$DEBUG" -ge 10 ]  && set -o errtrace         # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 10 ]  && set -o errexit          # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 10 ]  && set -o nounset          # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 10 ]  && set -o pipefail         # The return value of a pipeline is the status of the last command to exit with
                                                # a non-zero status, or zero if no command exited with a non-zero status.
[ "$DEBUG" -ge 20 ] && set -x                   
[ "$DEBUG" -ge 1 ]  && declare -x DEBUG         # Debugging 1=extra logging, 2= verbose to commands, 5= pauses, 11= set -x
#
declare baseDirectory           && baseDirectory=${baseDirectory:-/home/carl/dev/sdm}
declare baseImageDirectory      && baseImageDirectory=${baseImageDirectory:-"baseos"}
declare baseImage               
declare baseUrl                 && baseUrl=${baseUrl:-"https://downloads.raspberrypi.org/"}
declare hostName                && hostName=${hostName:-"rpicm4-1"}
declare downloadUrl
#
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
baseDir=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
scriptName=$(basename "$(realpath "${BASH_SOURCE[0]}")")
scriptName=${scriptName%%.*}
source "${baseDir}/assets/common.sh"
logname="${baseDir}/logs/${scriptName}.log"
#
fDebugLog 2 "Starting $scriptName at $STARTBUILD."
if [[ $BASEIMG == "" ]]; then
    fDebugLog 2 "Now calling get_latest_pios -t to get the download link."
    fDebugLog 3 "${LYELLOW}--------------------------------------------------"
    fDebugLog 3 "${LYELLOW}| Start Output from get_latest_pios.sh --test    |"
    fDebugLog 3 "${LYELLOW}--------------------------------------------------"
    downloadUrl="$("${baseDirectory}"/get_latest_pios.sh --test)"
    fDebugLog 3 "${LYELLOW}--------------------------------------------------"
    fDebugLog 3 "${LYELLOW}| End Output from get_latest_pios.sh --test      |"
    fDebugLog 3 "${LYELLOW}--------------------------------------------------"
# shellcheck disable=SC2001
    baseImage=$(echo "${downloadUrl}" | sed 's:.*/::')
    baseImage=${baseImage::-3}
else
    fDebugLog 2 "Skipping get_latest_pios because BASEIMG is set ($BASEIMG)"
    baseImage=${BASEIMG}
fi

fDebugLog 3 "${LYELLOW}--------------------------------------------------"
fDebugLog 3 "${LYELLOW}| Running with the following settings. :-        |"
fDebugLog 3 "${LYELLOW}--------------------------------------------------"
fDebugLog 3 "STARTSEC=${STARTSEC}"
fDebugLog 3 "STARTBUILD=${STARTBUILD}"
fDebugLog 3 "DEBUG=${DEBUG}"
fDebugLog 3 "baseDirectory=${baseDirectory}"
fDebugLog 3 "baseImageDirectory=${baseImageDirectory}"
fDebugLog 3 "baseImage=${baseImage}"
fDebugLog 3 "baseUrl=${baseUrl}"
fDebugLog 3 "hostName=${hostName}"
fDebugLog 3 "callingUser=${callingUser}"
fDebugLog 3 "downloadUrl=${downloadUrl}"
fDebugLog 3 "${LYELLOW}--------------------------------------------------"
fDebugLog 4 "Proceed with settings." yesno 4 || errexit "User aborted."

if [[ ! -d "${baseDirectory}/${baseImageDirectory}/" ]]
then
    fDebugLog 2 "Making directory ${baseDirectory}/${baseImageDirectory}/."
    su "${callingUser}" --command="$mkdirCmd ${baseDirectory}/${baseImageDirectory}/"
else
    fDebugLog 2 "Skipping Making directory ${baseDirectory}/${baseImageDirectory}/ because it already exists."
fi

if [[ ! -e "${baseDirectory}/${baseImageDirectory}/${baseImage}" ]] ; then
    echo "" 1>&2
    fDebugLog 0 "Downloading & extracting"
    fDebugLog 0 " ${downloadUrl}"
    fDebugLog 0 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
    fDebugLog 4 "Proceed with download." yesno 4 || errexit "User aborted."
    curlOps="" && [ "$DEBUG" -ge 2 ] && curlOps="--verbose"
    su "${callingUser}" --command="curl $curlOps $downloadUrl | unxz - > ${baseDirectory}/${baseImageDirectory}/${baseImage}"
else
    fDebugLog 2 "Skipping Downloading & extracting ${downloadUrl} because $baseImage alreay exists."
    fDebugLog 2 " to ${baseDirectory}/${baseImageDirectory}/${baseImage}"
fi

if [[ ! -d "${baseDirectory}/output/" ]]
then
    fDebugLog 2 "Making directory ${baseDirectory}/output/"
    su "${callingUser}" --command="$mkdirCmd ${baseDirectory}/output/"
else
    fDebugLog 2 "Skipping Making directory ${baseDirectory}/output/ because it alreay exists."
fi

fDebugLog 2 "Copying ${baseDirectory}/${baseImageDirectory}/${baseImage} to ${baseDirectory}/output/1stcall.uk-base.img"
$cpCmd "${baseDirectory}"/"${baseImageDirectory}"/"${baseImage}" "${baseDirectory}"/output/1stcall.uk-base.img

sdmCmd="${baseDirectory}/sdm --customize ${baseDirectory}/output/1stcall.uk-base.img"
sdmCmd="${sdmCmd} --logwidth 999"
sdmCmd="${sdmCmd} --apt-dist-upgrade"
sdmCmd="${sdmCmd} --disable piwiz,swap"
sdmCmd="${sdmCmd} --l10n"
sdmCmd="${sdmCmd} --restart 1"
#[[ $DEBUG -ge 3 ]] && sdmCmd="${sdmCmd} --showapt"
sdmCmd="${sdmCmd} --showapt"
[[ $DEBUG -ge 3 ]] && sdmCmd="${sdmCmd} --showpwd"
sdmCmd="${sdmCmd} --wpa ${baseDirectory}/assets/wpa_supplicant.conf"
sdmCmd="${sdmCmd} --batch"
sdmCmd="${sdmCmd} --extend"
sdmCmd="${sdmCmd} --xmb 2049"
sdmCmd="${sdmCmd} --poptions apps"
sdmCmd="${sdmCmd} --apps @${baseDirectory}/assets/1stcall.applist"
sdmCmd="${sdmCmd} --rename-pi carl"
sdmCmd="${sdmCmd} --password-pi letmein123"
#sdmCmd="${sdmCmd} --user carl"
#sdmCmd="${sdmCmd} --password-user letmein123"
#sdmCmd="${sdmCmd} --plugin apt-file"
# shellcheck disable=SC2089
sdmCmd="${sdmCmd} --plugin ${baseDirectory}/local-plugins/10mydotfiles:assetDir=\"${baseDirectory}/assets\"|DEBUG=${DEBUG}|LOGPREFIX=${scriptName}"
#sdmCmd="${sdmCmd} --plugin ${baseDirectory}/local-plugins/20bullseye-backports:assetDir=\"${baseDirectory}/assets\"|DEBUG=${DEBUG}|LOGPREFIX=${scriptName}"
sdmCmd="${sdmCmd} --plugin ${baseDirectory}/local-plugins/20bookworm-backports:assetDir=\"${baseDirectory}/assets\"|DEBUG=${DEBUG}|LOGPREFIX=${scriptName}"
sdmCmd="${sdmCmd} --plugin ${baseDirectory}/local-plugins/50btfix:assetDir=\"${baseDirectory}/assets\"|DEBUG=${DEBUG}|LOGPREFIX=${scriptName}"
[[ $DEBUG -ge 3 ]] && sdmCmd="${sdmCmd} --plugin-debug"
#sdmCmd="${sdmCmd} --aptcache 192.168.0.42"
sdmCmd="${sdmCmd} --aptcache rpicm4-1.1stcall.uk"
fDebugLog 1 "Running ${sdmCmd}"
fDebugLog 4 "Proceed running command." yesno 4 || errexit "User aborted."
fDebugLog 3 "${LYELLOW}--------------------------------------------------"
fDebugLog 3 "${LYELLOW}| Start Output from sdm --custmoize              |"
fDebugLog 3 "${LYELLOW}--------------------------------------------------"
# shellcheck disable=SC2090
${sdmCmd}
fDebugLog 3 "${LYELLOW}--------------------------------------------------"
fDebugLog 3 "${LYELLOW}| End Output from sdm --custmoize                |"
fDebugLog 3 "${LYELLOW}--------------------------------------------------"

ENDBUILD=$(date)
fDebugLog 1 "${scriptName} started at ${STARTBUILD} and compleated at ${ENDBUILD}."
echo 1>&2 "${scriptName} completed in $(displaytime $(( $(date +%s) - STARTSEC )))."
exit 0
