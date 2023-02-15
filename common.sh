#!/usr/bin/env bash
#
set -e
#
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
        log "$pfx [${logLvl}/${DEBUG}] ${logMsg}" 1>&2
        if [ "$logWait" == "wait" ] && [ "$DEBUG" -ge ${minDebugWait} ]; then
            log "$pfx Press any key to continue..." 1>&2
            read -n 1 -s -r
        elif [ "$logWait" == "yesno" ]; then
            log "$pfx Do you wish to continue? (Y/N)" 1>&2
            while true
                do
                    read -r -n 1 -s choice
                    case "$choice" in
                        n|N) exit 1;;
                        y|Y) break;;
                        *) log "Response not valid"  1>&2 ;;
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
