#!/bin/bash
CURRENT_PID=$$
PROCESS_NAME=$(basename $0)
LOGFILE=${PROCESS_NAME}.log

[ -n "${*}" ] || MESSAGE=$(tee) && MESSAGE="${*}"
echo -e "$(date)\t$PROCESS_NAME\t$CURRENT_PID\t$MESSAGE" | tee -a $LOGFILE
