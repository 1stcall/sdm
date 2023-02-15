#!/usr/bin/env bash
set -e

export STARTBUILD=$(date +%s)
export BUILDONLY=${BUILDONLY:-false}

export RESTORE=$(echo -en '\033[0m')
export RED=$(echo -en '\033[00;31m')
export GREEN=$(echo -en '\033[00;32m')
export YELLOW=$(echo -en '\033[00;33m')
export BLUE=$(echo -en '\033[00;34m')
export MAGENTA=$(echo -en '\033[00;35m')
export PURPLE=$(echo -en '\033[00;35m')
export CYAN=$(echo -en '\033[00;36m')
export LIGHTGRAY=$(echo -en '\033[00;37m')
export LRED=$(echo -en '\033[01;31m')
export LGREEN=$(echo -en '\033[01;32m')
export LYELLOW=$(echo -en '\033[01;33m')
export LBLUE=$(echo -en '\033[01;34m')
export LMAGENTA=$(echo -en '\033[01;35m')
export LPURPLE=$(echo -en '\033[01;35m')
export LCYAN=$(echo -en '\033[01;36m')
export WHITE=$(echo -en '\033[01;37m')

export filename=$(basename -- "${0}")
export extension="${filename##*.}"
export filename="${filename%.*}"
export logname="${filename}.log"
export outname="${filename}.out"

debug(){
    while read line
    do
        echo $line | tee -a "${outname}"
    done
}
export debug

log(){
    LOGMG="${1}"
    printf "${GREEN}%s %s${RESTORE} ${LCYAN}%s : ${LBLUE}%s${RESTORE}\n" $(date +'%Y/%m/%d %T') ${LOGPREFIX} "${LOGMG}" | tee -a "${logname}"
}
export log

function displaytime {
  local T="${1}"
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}
export displaytime

function doCommand {
    local cmdToRun="${1}"
 
    log "Running ${cmdToRun}"
    stdbuf -oL "${cmdToRun}" | 
    while IFS= read -r line
    do
        log "$line"
    done
 }
 export doCommand
          
 function fDebugLog() {
    OLDIFS=${IFS}
    IFS=''
    pfx="*DBG ${scriptName}:"
    logLvl=${1:-99}             # Logging level to log message at.
    logMsg="${2:-"NO MSG"}"     # Messge to log.
    logWait="${3:-"nowait"}"    # wait="Press any key to continue."
                                # yesno="Do you wish to continue (Y/N)?"
                                # nowait=Don't wait.
    minDebugWait=${4:-5}        # Minimug debug level to wait for keypress.

    if [ $logLvl -le $DEBUG ]; then
        log "$pfx [${logLvl}/${DEBUG}] ${logMsg}"
        if [ "$logWait" == "wait" ] && [ "$DEBUG" -ge ${minDebugWait} ]; then
            log "$pfx Press any key to continue..."
            read -n 1 -s -r
        elif [ "$logWait" == "yesno" ]; then
            log "$pfx Do you wish to continue? (Y/N)"
            while true
                do
                    read -r -n 1 -s choice
                    case "$choice" in
                        n|N) exit 1;;
                        y|Y) break;;
                        *) log "Response not valid" ;;
                    esac
            done
        fi
    fi
    IFS=${OLDIFS}
}
export fDebugLog

function errexit() {
    echo -e "$1" 1>&2
    exit 1
}
export errexit
