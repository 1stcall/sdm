#!/usr/bin/env bash
#
declare DEBUG=${DEBUG:-0}
[ "$DEBUG" -ge 10 ]  && set -o errtrace         # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 10 ]  && set -o errexit          # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 10 ]  && set -o nounset          # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 10 ]  && set -o pipefail         # The return value of a pipeline is the status of the last command to exit with
                                                # a non-zero status, or zero if no command exited with a non-zero status.
[ "$DEBUG" -ge 20 ] && set -x                   
[ "$DEBUG" -ge 1 ]  && declare -x DEBUG         # Debugging 1=extra logging, 2= verbose to commands, 5= pauses, 11= set -x
#
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
baseDir=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
scriptName=`basename "$(realpath ${BASH_SOURCE[0]})"`
source "${baseDir}/assets/common.sh"
logname="${baseDir}/logs/${scriptName}.log"
#export logname

function printhelp() {
cat <<EOF  1>&2
Usage: ${scriptName} [options]

Options:
  -b, --baseUrl BASEURL         URL to download from.  
                                The default is "$baseUrl".
  -o, --os OS                   Operation System to download.  
                                Currently only "raspios" is supported.  
                                The default is "$os".
  -a, --arch ARCH               Architecture to download.  
                                "arm" and "arm64" are currently supported.  
                                The default is "$arch".
  -e, --edition EDITION         Eddition to download.  
                                "lite" & "full" are currently supported.  
                                The default is "$edition".
  -t, --test                    Lookup and return the download URL only.
  -h, --help                    Display this help and exit. 
  -v, --version                 Display ${scriptName} version number and exit.
EOF
}
#
# Initialize and Parse the command
#
#
version="V0.1.1dev"
#
# Set command line defaults
#
os=raspios
edition=lite
arch=arm64
baseUrl="https://downloads.raspberrypi.org/${os}_${edition}_${arch}/images/"
testing=0
pvers=0
#
# Parse the command line
#
cmdline="${scriptName} $*"
longopts="help,os:,edition:,arch:,baseUrl:,version,test"

OARGS=$(getopt -o o:e:a:u:vth --longoptions $longopts -n 'get_latest_pios.sh' -- "$@")
[ $? -ne 0 ] && errexit "? ${scriptName}: Unable to parse command"
eval set -- "$OARGS"

while true
do
    case "${1,,}" in
	# 'shift 2' if switch has argument, else just 'shift'
	-o|--os)          os=$2         ; shift 2 ;;
	-e|--edition)     edition=$2    ; shift 2 ;;
	-a|--arch)        arch=$2       ; shift 2 ;;
	-u|--url)         baseUrl="$2"  ; shift 2 ;;
	-v|--version)     pvers=1       ; shift 1 ;;
	-t|--test)        testing=1     ; shift 1 ;;
	--)               shift         ; break ;;
	-h|--help)        printhelp ; shift ; exit 0 ;;
	*)                errexit "? ${scriptName}: Internal error" ;;
    esac
done

[ $pvers -eq 1 ] && echo "${scriptName} Version $version" && exit 0

fDebugLog 1 "Starting $scriptName at $STARTBUILD."
fDebugLog 2 "DEBUG=${DEBUG} scriptName=${scriptName} LOGPREFIX=${LOGPREFIX}" wait
fDebugLog 2 "baseUrl=${baseUrl}" 
latestUrl=$(curl -s ${baseUrl} | sed -n 's/.*href="\([^"]*\).*/\1/p' | tail -1)

fDebugLog 2 "latestUrl=${latestUrl}" 
filename=$(curl -s ${baseUrl}${latestUrl} | sed -n 's/.*href="\([^"]*\).*/\1/p' | head -3 | tail -1)

fDebugLog 2 "filename=${filename}" 
downloadUrl="${baseUrl}${latestUrl}${filename}"

fDebugLog 1 "downloadUrl=${downloadUrl}"
extractedFilename=${filename::-3}

fDebugLog 1 "extractedFilename=${extractedFilename}"
if [[ ${testing} -eq 0 ]]; then
    fDebugLog 2 "About to download ${downloadUrl}" yesno || errexit "User aborted."
    curl ${downloadUrl} | unxz - > ./${extractedFilename}
else
    echo "${downloadUrl}" 2>&1
fi

exit 0
