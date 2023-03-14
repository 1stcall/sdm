#!/bin/bash
CURRENT_PID=$$
PROCESS_NAME=$(basename $0)

LOGFILE=${PROCESS_NAME}.log
function log_message {
  if [ -n "$1" ]; then
      MESSAGE="$1"
      echo -e "$(date)\t$PROCESS_NAME\t$CURRENT_PID\t$MESSAGE" | tee -a $LOGFILE
  else
      MESSAGE=$(tee)
      echo -e "$(date)\t$PROCESS_NAME\t$CURRENT_PID\t$MESSAGE" | tee -a $LOGFILE
  fi
}

log_message "${*}"
