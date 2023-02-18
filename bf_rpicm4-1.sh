#!/usr/bin/env bash

DEBUG=${DEBUG:-0}

[ "$DEBUG" -ge 1 ]  && set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 1 ]  && set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 1 ]  && set -o nounset                                      # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 1 ]  && set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
[ "$DEBUG" -ge 10 ] && set -x                                              # Debugging 1=extra logging, 2= verbose to commands, 3= pauses, 4= set -x
[ "$DEBUG" -ge 1 ]  && declare -x DEBUG

declare baseDirectory           && baseDirectory=${baseDirectory:-/home/carl/dev/sdm}
#declare baseImage="2022-09-22-raspios-bullseye-arm64-lite.img"
#declare baseImageDirectory="baseos"
declare hostName="rpicm4-1"

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
scriptName=$(basename "$(realpath ${BASH_SOURCE[0]})")
scriptName=${scriptName%%.*}
source "${baseDir}/common.sh"
logname="${baseDir}/logs/${scriptName}.log"
#export logname

fDebugLog 1 "callingUser=${callingUser}"
fDebugLog 1 "baseDirectory=${baseDirectory}"
fDebugLog 1 "hostName=${hostName}"

if [ -f "${baseDirectory}/output/${hostName}-out.img" ] ; then
    if [ -f "${baseDirectory}/output/${hostName}-out.img.old" ] ; then
        fDebugLog 1 "Removing old backup file ${baseDirectory}/output/${hostName}-out.img.old"
        rm -f "${baseDirectory}/output/${hostName}-out.img.old"
    fi
    fDebugLog 1 "Backing up existing image ${baseDirectory}/output/${hostName}-out.img"
    mv -v "${baseDirectory}/output/${hostName}-out.img" "${baseDirectory}/output/${hostName}-out.img.old"
fi

fDebugLog 1 "${scriptName} is Running ${baseDirectory}/sdm --burnfile" wait 3
${baseDirectory}/sdm --burnfile ${baseDirectory}/output/${hostName}-out.img \
    --host ${hostName}.1stcall.uk \
    --regen-ssh-host-keys \
    --logwidth 999 \
    --apt-dist-upgrade \
    --showapt \
    --showpwd \
    --batch \
    --plugin 00test:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 30configgit:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 50enablenetfwd:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 50instlvmxfs:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin 60pxehost:"assetDir=${baseDirectory}/plugins/assets|netIface=eth1|ipAddr=192.168.1.1|dnsaddr=192.168.1.1|brdAddr=192.168.1.255|gwAddr=192.168.1.1|dhcpRange=192.168.1.2,192.168.1.10,255.255.255.0,6h|tftpRootDir=/srv/netboot/tftp/|nfsRootDir=/srv/netboot/nfs/" \
    --plugin 70devtools:"assetDir=${baseDirectory}/plugins/assets" \
    --plugin-debug \
    --custom1=$DEBUG \
    --custom2=${scriptName%%.*} \
    "${baseDirectory}/output/1stcall.uk-base.img"

ENDBUILD=$(date)
fDebugLog 1 "${scriptName} started at ${STARTBUILD} and compleated at ${ENDBUILD}."
log "${scriptName} completed in $(displaytime $(( $(date +%s) - $STARTSEC )))"
exit 0
