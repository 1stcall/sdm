#!/usr/bin/env bash
#
# Set safe mode for bash.
#
set -o errtrace                                 # If set, the ERR trap is inherited by shell functions.
set -o errexit                                  # Exit immediately if a command exits with a non-zero status.
set -o nounset                                  # Treat unset variables as an error when substituting.
set -o pipefail                                 # The return value of a pipeline is the status of the last command to exit.
#
# Set script information.
#
scriptVersion="V0.03.dev"                       # Script information.
scriptFileName=$(basename "$(realpath "${BASH_SOURCE[0]}")")
scriptName=${scriptFileName%%.*}
scriptLongName="${scriptName} Version: ${scriptVersion}"
#
# Set constants
#
BASE_ERR_NO=64                                  # Starting error number for custom errors.
ERR_USER_ABORT=$((BASE_ERR_NO+1))               # Error triggered by answering No to a 'Do you wish to continue?'.
ERR_USAGE_SHOWN=$((BASE_ERR_NO+2))              # Triggered after showing the scripts help information.
ERR_VERSION_SHOWN=$((BASE_ERR_NO+3))            # Triggered after showing the scripts version information.
ERR_BASEFILE_DNE=$((BASE_ERR_NO+4))             # Error triggered when the supplied raw image file does not exist.
ERR_OUTDIR_DNE=$((BASE_ERR_NO+5))               # Error triggered when the output directory does not exist.
ERR_CTRLC_PRESSED=$((BASE_ERR_NO+6))            # Triggered by CTRL+C during execution.
ERR_NO_SERIALNO=$((BASE_ERR_NO+7))              # Error triggered when no serial number is specified on the command line.
ERR_GETOPT_CANNOT_PARSE=$((BASE_ERR_NO+8))      # Error triggered when processCommandLine function cannot parse the command line.
ERR_DEBUG_STOP=$((BASE_ERR_NO+9))               # Triggered when DEBUG is set and a breakpoint has been reached.
ERR_NO_ROOT=$((BASE_ERR_NO+10))                 # Error triggered when the script is not run as the root user.
#
# Set traps
#
trap 'doCtrlCExit $LINENO' SIGINT               # Trap CTRL+C to clean up.
trap 'doExit $? $LINENO' EXIT                   # Trap exit to clean up. 
trap 'doError $? $LINENO' ERR                   # Trap errors to report & clean up.
#
# Set command line defaults to environment variables if set, else sane defaults.
#
OVERWRITE=${OVERWRITE:-0}                       # Default not to overwrite if output directories allready exist.
VERBOSE=${VERBOSE:-0}                           # Default verbosity level of output.
DRYRUN=${DRYRUN:-0}                             # Default to extract files & not to do a dry run.
SHOWHELP=${SHOWHELP:-0}                         # Default to not show script usage information.
SHOWVERSION=${SHOWVERSION:-0}                   # Default to not show script version information.
BASEIMAGE=${BASEIMAGE:-"**unset**"}             # Default to no raw image.
OUTDIR=${OUTDIR:-"**unset**"}                   # Default to no output directory.
SERIALNO=${SERIALNO:-"**unset**"}               # Default to no serial number set.
DEBUG=${DEBUG:-0}                               # Default to no debugging information or breakpoints.
#
# Set working variable defaults
#
errNo=0
#
# Declare functions used within the script.
#
function doCtrlCExit(){                         # Handle CTRL+C. $1=Line Number CTRL+C was triggered from.
    trap - SIGINT
#    doError $ERR_CTRLC_PRESSED "${1:-99}"
    return $ERR_CTRLC_PRESSED
}
#
[[ 2 -eq 1 ]] && doCtrlCExit 99                 # NOP to perswade shellcheck the function can be reached.
#
function doExit(){                              # Function to handle SIGEXIT signals.  $1=Line Number exit was triggered from.
    trap - EXIT
    cleanUp
    exit "${1:-99}"
}
[[ 2 -eq 1 ]] && doExit 99                      # NOP to perswade shellcheck the function can be reached.
#
function doError(){                             # Function to handle SIGERR signals $1=Error Number, $2=Line number where error occured.
    #
    trap - ERR
    #
    local errNo=${1:-"**UNKNOWN**"}
    local errLine=${2:-"**UNKNOWN**"}
    #
    case ${errNo} in
        "$ERR_USER_ABORT")                      errorExit "$errNo" "User Abort trapped on line no. $errLine of $scriptFileName." ;;
        "$ERR_USAGE_SHOWN")                     [[ $VERBOSE -ge 3 ]] && errorExit "$errNo" "Usage information of $scriptFileName displayed." ;;
        "$ERR_VERSION_SHOWN")                   [[ $VERBOSE -ge 3 ]] && errorExit "$errNo" "Version information of $scriptFileName displayed." ;;
        "$ERR_BASEFILE_DNE")          doHelp;   errorExit "$errNo" "BASEFILE does not exist! Aborting." ;;
        "$ERR_CTRLC_PRESSED")                   errorExit "$errNo" "CTRL+C Caught on line no. $errLine!  Aborting." ;;
        "$ERR_NO_SERIALNO")           doHelp;   errorExit "$errNo" "No SERIALNO specified!  Aborting." ;;
        "$ERR_GETOPT_CANNOT_PARSE")   doHelp;   errorExit "$errNo" "Cannot parse commandline! Aborting." ;;
        "$ERR_DEBUG_STOP")                      errorExit "$errNo" "DEBUG STOP reached on line no. $errLine." ;;
        "$ERR_NO_ROOT")                         errorExit "$errNo" "Please run as root. try 'sudo $cmdLine'" ;;
        *)                                      errorExit "$errNo" "Unknown error ($errNo) trapped on line $errLine of $scriptFileName." ;;
    esac
#
    exit "$errNo"
}
[[ 2 -eq 1 ]] && doError 99 99                  # NOP to perswade shellcheck the function can be reached.
#
function errorExit() {                          # Function to trigger an error with a message & exit.  $1=Error Number $2=Error message.
    local errNo=${1:-99}
    local errMsg=${2:-"**UNKNOWN ERROR**"}
    #
    log "E: ${errMsg} (${errNo})"
    exit "$errNo"
}
#
function flushInputBuffer(){                    # Function to empty the keyboard buffer prior to accepting input.
    [[ $VERBOSE -ge 5 || $DEBUG -ge 3 ]] && log "Flushing Keyboard buffer if a terminal."
    if [[ -t 0 ]]; then                         # If STDIN is a terminal.
        [[ $VERBOSE -ge 5 || $DEBUG -ge 2 ]] && log "Flushing Keyboard buffer we are a terminal."
        while read -t 0 input; do               # Read the keyboard buffer until its empty.
            read -r input
            [[ $VERBOSE -ge 2 || $DEBUG -ge 1 ]] && log "Flushing Keyboard buffer.  Ignoring $input"
        done
    fi
}
#
function log(){                                 # Function to log output to the STDERR. $1(Optional)=wait,nowait or yesno.
                                                # When set to wait, Press any key to continue.
                                                # When set to yesno, Do you wish to continue? (Y/N), where N will abort the script.
                                                # When set to nowait or unset, log the message only
                                                # All remaining paramiters will be concaternated into the message.

    doWait="nowait"                             # Default to nowait 
    msg=${*:-""}                                # Default to all paramerers as the message or an empty message if no paramerers passed.
    
    if [[ -n ${1+x} ]]; then                    # If >1 parameter passed, ie wait or yesno required.
        if [[ ${1} == "wait" ]] || [[ ${1} == "yesno" ]] || [[ ${1} == "nowait" ]]
        then
            doWait=${1}
            shift 1
            msg=${*:-"Please confirm"}
        fi
    fi
    if (( DEBUG > 0 )); then
        echo -e "${scriptName}: ${msg}" 1>&2    # Display the message.
    else
        echo -e "${msg}" 1>&2                   # Display the message.
    fi

    if [[ ${doWait} == "wait" ]]                # If wait requested, Display "Press any key to continue..." and wait for a keypress.
    then
        flushInputBuffer                        # Flush the keyboard buffer.
        echo -e "\nPress any key to continue..." 1>&2
        read -n 1 -s -r                         # Wait for a key press.
    elif [[ ${doWait} == "yesno" ]]
    then
        flushInputBuffer                        # Flush the keyboard buffer.
        echo -e "\nDo you wish to continue? (Y/N)" 1>&2
        while true
        do
            read -r -n 1 -s choice              # Wait for a key press.
            case "$choice" in
#                n|N) doError $ERR_USER_ABORT $LINENO ;;     # Abort if answer is No.
                n|N) return $ERR_USER_ABORT ;;              # Abort if answer is No.
                y|Y) break;;                                # Continue if answer is Yes.
                *) log "Response not valid" ;;              # Report an invalid response.
            esac
        done
    fi
}
#
#function getSource(){                               # Function to find the real source if symlinked.
#    #
#    local SOURCE
#    local DIR
#    #
#    SOURCE=${BASH_SOURCE[0]}
#    while [ -L "$SOURCE" ]; do                      # resolve $SOURCE until the file is no longer a symlink
#      DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
#      SOURCE=$(readlink "$SOURCE")
#      [[ ${SOURCE} != /* ]] && SOURCE=$DIR/$SOURCE  # if $SOURCE was a relative symlink, we need to resolve it relative to the path 
#                                                    # where the symlink file was located.
#    done
#    #
#    echo "${SOURCE}"
#}
#
function isMounted() {                              # Test if device is mounted, or if a folder is a mount.
    ret=0
    grep -qs "${1}" /proc/mounts || ret=${?}
 	return ${ret}
}
#
function cleanUp(){                                 # Cleanup mounts and loop devices used within the script.
    [[ $VERBOSE -ge 1 || $DEBUG -ge 2 ]] && log "Cleaning up..."
    if [[ -n ${temporyMountPoint+x} ]] && [[ "${temporyMountPoint}" != "**unset**" ]]; then     # Check if mount points are set.
        isMounted "${temporyMountPoint}/rootfs" && \
            $umountCommand "${temporyMountPoint}/rootfs" > /dev/null && \
            [[ $VERBOSE -ge 2 ]] && log "${temporyMountPoint}/rootfs unmounted"
        isMounted "${temporyMountPoint}/bootfs" && \
            $umountCommand "${temporyMountPoint}/bootfs" > /dev/null && \
            [[ $VERBOSE -ge 2 ]] && log "${temporyMountPoint}/bootfs unmounted"
        (( VERBOSE >= 1 )) && log "Removing existing tempory mount directory: '${temporyMountPoint}'."
        $rmCommand "${temporyMountPoint}"
    fi
    if [[ -n ${loopDevice+x} ]] && [[ ! "${loopDevice}" == "**unset**" ]]; then                 # Check if loop device is set then unset if so.
        $losetupCommand -d "${loopDevice}" && log "${loopDevice} detached." && loopDevice=""
    fi
    trap - ERR EXIT SIGINT                          # Clear traps.
    return 0
}
#
function doVersion(){                               # Display version and exit.
    echo "${scriptLongName}" 1>&2
    errNo=$ERR_VERSION_SHOWN
}
#
function doHelp(){                                  # Display usage information and exit.
    cat <<EOF 1>&2

${scriptLongName}

Description:    ${scriptName} is used to extract a multipart raw image file to:-
                    partition 1 to OUTDIR/tftp/SERIALNO bootfs directory
                  & partition 2 to OUTDIR/nfs/SERIALNO rootfs directory.

Usage:          ${scriptFileName} [OPTIONS...] IMAGEFILE OUTDIR SERIALNO

Where:          IMAGEFILE (Required):   Raw multipart image file to extract.
                OUTDIR (Required):      Base output directory for the extracted files.
                SERIALNO (Required):    Serial number for the PI that will boot from the files.

Options:
  -o, --overwrite               Overwite output directories without checking.  
                                The default is not set.
  -v[LEVEL], --verbose[=LEVEL]  Sets or incriments the verbosity level. The default level is 0.
                                Can be set with -v[LEVEL] | --verbose=LEVEL or incrimented by 1 if 
                                no LEVEL is not specified.  May be specified multiple times ie.
                                -vvv is the same as -v3, -v=3 or --verbose=3.
  -d, --dryrun                  Don't extract any files. Show what would be done only.
  -h, --help                    Display this help and exit. 
  -V, --version                 Display ${scriptName} version number and exit.

EOF
    #
}
#
function processCommandLine(){
    #
    # Parse the command line
    #
    local longopts="verbose::,overwrite,dryrun,help,version"
    local shortopts="Vodhv::"
    local getoptArgs=${*}
    #
    # shellcheck disable=SC2086
    OARGS=$(getopt --options $shortopts --longoptions $longopts --name "'${scriptFileName}'" -- $getoptArgs)
    getoptErr=$?
    [[ $getoptErr -ne 0 ]] && doError $getoptErr $LINENO
    #
    eval set -- "$OARGS"
    [[ $DEBUG -ge 2 ]] || [[ $VERBOSE -ge 4 ]] && log "Processing OARGS - '$OARGS'"
    while true
    do
        if [[ $DEBUG -gt 0 ]]; then
            log "processCommandLine is processing ${1}"
        fi

        if  [[ $VERBOSE -ge 3 ]] || [[ $DEBUG -ge 2 ]] ; then
            log "processCommandLine is processing ${1}"
        fi
        #
        case "${1}" in
	        # 'shift 2' if switch has argument, else just 'shift'
	        -v|--verbose)
                OPTARG=${2:-""}
                if [[ -z ${OPTARG} ]]; then
                    VERBOSE=$(( VERBOSE+1 ))
                    shift 2
                else
                    VERBOSE=${OPTARG##}
                    shift 2
                fi ;;
	        -o|--overwrite)   OVERWRITE=1       ; shift 1 ;;
	        -d|--dryrun)      DRYRUN=1          ; shift 1 ;;
	        -h|--help)        SHOWHELP=1        ; shift 1 ;;
	        -V|--version)     SHOWVERSION=1     ; shift 1 ;;
	        --)               shift             ; break ;;
	        *)                :                 ; return ${ERR_GETOPT_CANNOT_PARSE} ;;
        esac
    done

    if [[ -n ${1+x} ]] 
    then
        BASEIMAGE=${1}
        shift 1
    else
        doHelp
        errorExit ${ERR_GETOPT_CANNOT_PARSE} "BASEIMAGE is required."
    fi

    if [[ -n ${1+x} ]] 
    then
        OUTDIR=${1}
        shift 1
    else
        doHelp
        errorExit ${ERR_GETOPT_CANNOT_PARSE} "OUTDIR is required."
    fi
    if [[ -n ${1+x} ]] 
    then
        SERIALNO=${1}
        shift
    else
        doHelp
        errorExit ${ERR_GETOPT_CANNOT_PARSE} "SERIALNO is required."
    fi
}
#
# ------------------------- Main processing starts here. --------------------------------------
#
# Set script base directory.
#
#scriptBaseDir=$( cd -P "$( dirname "$(getSource)" )" >/dev/null 2>&1 && pwd )
#
# Initialize and Parse the command line
#
cmdLine="${scriptFileName} $*"
[[ $VERBOSE -ge 2 ]] && log "Processing command line '${cmdLine}'..."
processCommandLine "$@"
#
serialNo=${SERIALNO}
imgToExtract=${BASEIMAGE}
temporyMountPoint=$(mktemp --directory)
outputDir=${OUTDIR}
outputRootDir=${outputDir}/nfs/${serialNo}
outputBootDir=${outputDir}/tftp/${serialNo}
dryRun=${DRYRUN}
overwrite=${OVERWRITE}

if (( VERBOSE >=3 ))
then
    cpCommand="cp -av"
    mountCommand="mount -v"
    umountCommand="umount"
    mkdirCommand="mkdir -vp"
    losetupCommand="losetup -v"
    findOps="-depth -print"
else
    cpCommand="cp -a"
    mountCommand="mount"
    umountCommand="umount"
    mkdirCommand="mkdir -p"
    losetupCommand="losetup"
    findOps="-depth"
fi
if (( VERBOSE >=4 )); then
    rmCommand="rm -vrf"
    rsyncCommand="rsync --recursive --archive --mkpath --no-i-r --info=progress2 --verbose"
else
    rmCommand="rm -rf"
    rsyncCommand="rsync --recursive --archive --mkpath --no-i-r --info=progress2"
fi

if [[ $dryRun -ne 0 ]]; then
    rsyncCommand="${rsyncCommand} --dry-run"
else
    findOps="${findOps} -delete"
fi

if [[ $VERBOSE -ge 4 || $DEBUG -ge 2 ]]; then
    log "###########################################################"
    log "#                      Constants                          #"
    log "###########################################################"
    log "ERR_USER_ABORT=$ERR_USER_ABORT"
    log "ERR_USAGE_SHOWN=$ERR_USAGE_SHOWN"
    log "ERR_VERSION_SHOWN=$ERR_VERSION_SHOWN"
    log "ERR_BASEFILE_DNE=$ERR_BASEFILE_DNE"
    log "ERR_OUTDIR_DNE=$ERR_OUTDIR_DNE"
    log "ERR_CTRLC_PRESSED=$ERR_CTRLC_PRESSED"
    log "ERR_NO_SERIALNO=$ERR_NO_SERIALNO"
    log "ERR_GETOPT_CANNOT_PARSE=$ERR_GETOPT_CANNOT_PARSE"
    log "ERR_DEBUG_STOP=$ERR_DEBUG_STOP"
    log "ERR_NO_ROOT=$ERR_NO_ROOT"
    (( DEBUG > 3 )) && log yesno "DEBUG=$DEBUG  -  VERBOSE=$VERBOSE  -  DRYRUN=$DRYRUN"
    log
    log "###########################################################"
    log "#                        Traps                            #"
    log "###########################################################"
    trap -p 1>&2
    (( DEBUG > 3 )) && log yesno "DEBUG=$DEBUG  -  VERBOSE=$VERBOSE  -  DRYRUN=$DRYRUN"
    log
fi
if [[ $VERBOSE -ge 3 || $DEBUG -ge 2 ]]; then
    log "###########################################################"
    log "#                    Command Line                         #"
    log "###########################################################"
    log "Command line : ${cmdLine}"
    log "OVERWRITE=$OVERWRITE"
    log "VERBOSE=$VERBOSE"
    log "DRYRUN=$DRYRUN"
    log "SHOWHELP=$SHOWHELP"
    log "SHOWVERSION=$SHOWVERSION"
    log "BASEIMAGE=$BASEIMAGE"
    log "OUTDIR=$OUTDIR"
    log "SERIALNO=$SERIALNO"
    log "###########################################################"
    (( DEBUG > 3 )) && log yesno "DEBUG=$DEBUG  -  VERBOSE=$VERBOSE  -  DRYRUN=$DRYRUN"
    log
    log "###########################################################"
    log "#                  Working variables                      #"
    log "###########################################################"
    log "serialNo=${serialNo}"
    log "imgToExtract=${imgToExtract}"
    log "temporyMountPoint=${temporyMountPoint}"
    log "outputDir=${outputDir}"
    log "outputRootDir=${outputRootDir}"
    log "outputBootDir=${outputBootDir}"
    log "dryRun=${dryRun}"
    log "overwrite=${overwrite}"
    log "###########################################################"
    (( DEBUG > 3 )) && log yesno "DEBUG=$DEBUG  -  VERBOSE=$VERBOSE  -  DRYRUN=$DRYRUN"
    log 
fi
if [[ $VERBOSE -ge 4 || $DEBUG -ge 2 ]]; then
    log "###########################################################"
    log "#                   Commands to use                       #"
    log "###########################################################"
    log "cpCommand=$cpCommand"
    log "mountCommand=$mountCommand"
    log "umountCommand=$umountCommand"
    log "rmCommand=$rmCommand"
    log "mkdirCommand=$mkdirCommand"
    log "losetupCommand=$losetupCommand"
    log "rsyncCommand=$rsyncCommand"
    log "findOps=$findOps"
    log "###########################################################"
    (( DEBUG > 3 )) && log yesno "DEBUG=$DEBUG  -  VERBOSE=$VERBOSE  -  DRYRUN=$DRYRUN"
    log
fi

[[ SHOWVERSION -ne 0 ]]     && doVersion && doError $ERR_VERSION_SHOWN $LINENO
[[ SHOWHELP -ne 0 ]]        && doHelp && doError $ERR_USAGE_SHOWN $LINENO
[[ $EUID -ne 0 ]]           && doError $ERR_NO_ROOT $LINENO 
[[ ! -f "$imgToExtract" ]]  && doError $ERR_BASEFILE_DNE
[[ ! -d "$outputDir" ]]     && doError $ERR_OUTDIR_DNE
[[ -z "$serialNo" ]]        && doError $ERR_NO_SERIALNO

loopDevice=$($losetupCommand --show -P -f "$imgToExtract")

(( VERBOSE >= 2 )) && log "loop device ${loopDevice} is attached to ${imgToExtract}."

if [[ -d $outputRootDir ]]
then
    if (( dryRun > 0 )); then
        log "Root output directory ${outputRootDir} exists but will not be overwritten becase dryRun is set."
    else
        if (( overwrite == 0 )); then
            log yesno "Root output directory ${outputRootDir} exists & will be overwritten."
        fi
        (( VERBOSE >= 1 )) && log "Removing existing root directory: '${outputRootDir}'."
        $rmCommand "${outputRootDir}"
    fi
fi
if [[ -d $outputBootDir ]]
then
    if (( dryRun > 0 )); then
        log "Root output directory ${outputBootDir} exists but will not be overwritten becase dryRun is set."
    else
        if (( overwrite = 0 )); then
            log yesno "Boot output directory ${outputBootDir} exists & will be overwritten."
        fi
        (( VERBOSE >= 1 )) && log "Removing existing boot directory: '${outputBootDir}'."
        $rmCommand "$outputBootDir"
    fi
fi

if (( dryRun > 0 )); then
    log "Skipping creation of output directorys '$outputRootDir'"
    log "                   &                   '$outputBootDir',"
    log "because dryRun is set."
else
    if (( VERBOSE >=2 )); then 
        log nowait "Creating output directorys '$outputRootDir'"
        log nowait "          &                '$outputBootDir'."
    fi
    (( VERBOSE >= 1 )) && log "(Re)creating boot & root output directories."
    $mkdirCommand "$outputRootDir" "$outputBootDir"
fi

$mkdirCommand "${temporyMountPoint}"/{rootfs,bootfs}

if (( VERBOSE >= 2 )); then
    log nowait "Mounting '${loopDevice}p2' on '$temporyMountPoint/rootfs'"
    log nowait "    &    '${loopDevice}p1' on '$temporyMountPoint/bootfs'."
fi

$mountCommand "${loopDevice}p2" "$temporyMountPoint/rootfs"
isMounted "$temporyMountPoint/rootfs" || errorExit "Error mounting IMG '$imgToExtract' on '$temporyMountPoint/rootfs'."
$mountCommand "${loopDevice}p1" "$temporyMountPoint/bootfs"
isMounted "$temporyMountPoint/bootfs" || errorExit "Error mounting IMG '$imgToExtract' on '$temporyMountPoint/bootfs'."

(( DEBUG >= 1 )) && log "$rsyncCommand $temporyMountPoint/rootfs/ ${outputRootDir}"
log nowait "Copying '$temporyMountPoint/bootfs' to '${outputBootDir}/'"
log nowait "    &   '$temporyMountPoint/rootfs' to '${outputRootDir}/'."

$rsyncCommand "$temporyMountPoint/rootfs"/ "${outputRootDir}" || errorExit "Error copying '$temporyMountPoint/rootfs' to '${outputRootDir}/'."
$rsyncCommand "$temporyMountPoint/bootfs"/ "${outputBootDir}" || errorExit "Error copying '$temporyMountPoint/bootfs' to '${outputBootDir}/'."

cleanUp
(( VERBOSE >= 1 )) && log "${scriptLongName} exiting cleanly & without any errors."

exit 0
################################################################################################################################################
#[[ $DEBUG -gt 0 ]] && doError "$ERR_DEBUG_STOP" "$LINENO"######################################################################################
################################################################################################################################################
