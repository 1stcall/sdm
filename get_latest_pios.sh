#!/usr/bin/env bash  
#
DEBUG=${DEBUG:-0}

[ "$DEBUG" -ge 1 ]  && set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
[ "$DEBUG" -ge 1 ]  && set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
[ "$DEBUG" -ge 1 ]  && set -o nounset                                      # Treat unset variables as an error when substituting.
[ "$DEBUG" -ge 1 ]  && set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with
[ "$DEBUG" -ge 10 ] && set -x                                               # Debugging
[ "$DEBUG" -ge 1 ]  && export DEBUG
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
logname="${baseDir}scriptName.log"
export logname

function printhelp() {
    echo $"${scriptName} $version
Usage:
 ${scriptName} --baseUrl baseUrl --os|-o os --arch|-a arch --edition|-e edition --version|-v --help|-h --test|-t
   Download the most recent raspios from the internet to the current directory.

Command Switches
 --os os                Operation System to download.  Currently only raspios is supported.  Default \"raspios\".
 --edition edition      Eddition to download.  \"lite\" & \"full\" are currently supported.  Default \"lite\".
 --arch arch            Architecture to download.  \"arm\" and \arm64\" are currently supported.  Default \"arm64\".
 --baseUrl baseUrl      URL to download from.  Default \"https://downloads.raspberrypi.org/\${os}_\${edition}_\${arch}/images/\".
 --test                 Lookup and show the download URL only, without downloading anything.
 --version              Print ${scriptName} version number and exit.
 --help                 Display this help and exit." 1>&2

}
#
# Initialize and Parse the command
#
#
version="V0.0.1dev"
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

fDebugLog 0 "DEBUG=${DEBUG}"
fDebugLog 1 "baseUrl=${baseUrl}" 
latestUrl=$(curl -s ${baseUrl} | sed -n 's/.*href="\([^"]*\).*/\1/p' | tail -1)

fDebugLog 1 "latestUrl=${latestUrl}" 
filename=$(curl -s ${baseUrl}${latestUrl} | sed -n 's/.*href="\([^"]*\).*/\1/p' | head -3 | tail -1)

fDebugLog 1 "filename=${filename}" 
downloadUrl="${baseUrl}${latestUrl}${filename}"

fDebugLog 0 "downloadUrl=${downloadUrl}"
extractedFilename=${filename::-3}

fDebugLog 0 "extractedFilename=${extractedFilename}"
if [ ${testing} -eq 0 ]; then
    fDebugLog 1 "About to download ${downloadUrl}" yesno && curl ${downloadUrl} | unxz - > ./${extractedFilename}
else
    echo "${downloadUrl}" 2>&1
fi
exit 0
