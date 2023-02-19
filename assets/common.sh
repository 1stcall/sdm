#!/usr/bin/env bash
#
#set -e
declare RESTORE=$(echo -en '\033[0m')
declare GRAY=$(echo -en '\033[00;37m')
declare RED=$(echo -en '\033[00;31m')
declare GREEN=$(echo -en '\033[00;32m')
declare YELLOW=$(echo -en '\033[00;33m')
declare BLUE=$(echo -en '\033[00;34m')
declare MAGENTA=$(echo -en '\033[00;95m')
declare PURPLE=$(echo -en '\033[00;35m')
declare CYAN=$(echo -en '\033[00;36m')
declare LGRAY=$(echo -en '\033[01;37m')
declare LRED=$(echo -en '\033[01;31m')
declare LGREEN=$(echo -en '\033[01;32m')
declare LYELLOW=$(echo -en '\033[01;33m')
declare LBLUE=$(echo -en '\033[01;34m')
declare LMAGENTA=$(echo -en '\033[01;95m')
declare LPURPLE=$(echo -en '\033[01;35m')
declare LCYAN=$(echo -en '\033[01;36m')
declare WHITE=$(echo -en '\033[01;37m')
declare scriptName=${scriptName:-$(basename -- "${0}")}
declare LOGPREFIX=${LOGPREFIX:-${scriptName%%.*}}
#
declare callingUser=$(who am i | awk '{print $1}')
#
function fRunAs(){
    local slCmdToRun="${1:-:}"
    local slUserToRunAs="${2:-${callingUser}}"
    printf "Running command ${slCmdToRun}    As ${slUserToRunAs}\n" 1>&2
    su ${callingUser} --command="${slCmdToRun}"
    return ${!}
}
declare -fx fRunAs
#
debug(){
    while read line
    do
        echo $line | tee -a "${outname}"
    done
}
#export debug
#
log(){
    LOGMG="${1}"
    LOGLVL="${2:-0}"
    case  ${LOGLVL} in 
        0)  LOGCOLOR=$LGREEN ;;
        1)  LOGCOLOR=$GRAY ;;
        2)  LOGCOLOR=$LCYAN ;;
        3)  LOGCOLOR=$CYAN ;;
        4)  LOGCOLOR=$LYELLOW ;;
        5)  LOGCOLOR=$YELLOW ;;
        6)  LOGCOLOR=$LMAGENTA ;;
        7)  LOGCOLOR=$MAGENTA ;;
        *)  LOGCOLOR=$RED;;
    esac

    printf "${GREEN}%s${RESTORE} : ${LCYAN}%s${RESTORE} : ${LOGCOLOR}%s${RESTORE}\n" \
        "$(date +'%Y/%m/%d %T')" \
        "${LOGPREFIX}" \
        "${LOGMG}" \
        | tee -a ${logname}
}
#export log
#
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
#export displaytime

function doCommand {
    local cmdToRun="${1}"
 
    log "Running ${cmdToRun}"
    stdbuf -oL "${cmdToRun}" | 
    while IFS= read -r line
    do
        log "$line"
    done
 }
 #export doCommand
          
function fDebugLog() {
    DEBUG=${DEBUG:-0}
    OLDIFS=${IFS}
    IFS=''
    pfx="${scriptName:-"NO SCRIPTNAME"}"
    logLvl=${1:-99}             # Logging level to log message at.
    logMsg="${2:-"NO LOGMSG"}"     # Messge to log.
    logWait="${3:-"nowait"}"    # wait="Press any key to continue."
                                # yesno="Do you wish to continue (Y/N)?"
                                # nowait=Don't wait.
    minDebugWait=${4:-5}        # Minimug debug level to wait for keypress.

    if [[ $logLvl -le $DEBUG ]]; then
        log "[${logLvl}/${DEBUG}/${minDebugWait}] ${logMsg}" $logLvl 1>&2
        if [[ "$logWait" == "wait" ]] && [[ "$DEBUG" -ge ${minDebugWait} ]]; then
            log "[${logLvl}/${DEBUG}/${minDebugWait}] Press any key to continue..." $logLvl 1>&2
            read -n 1 -s -r
        elif [[ "$logWait" == "yesno" ]] && [[ "$DEBUG" -ge ${minDebugWait} ]]; then
            log "[${logLvl}/${DEBUG}/${minDebugWait}] Do you wish to continue? (Y/N)" $logLvl 1>&2
            while true
                do
                    read -r -n 1 -s choice
                    case "$choice" in
                        n|N) return 1;;
                        y|Y) break;;
                        *) log "Response not valid"  1>&2 ;;
                    esac
            done
        fi
    fi
    IFS=${OLDIFS}
}
#export fDebugLog

function errexit() {
    echo -e "$1" 1>&2
    exit 1
}
#export errexit
