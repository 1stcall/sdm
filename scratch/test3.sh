#!/usr/bin/env bash

printf "This is %s\n"               "${0}"
printf "BASH_SOURCE=%s\n"           ${BASH_SOURCE[*]}
printf "BASH_SUBSHELL=%s\n"         "${BASH_SUBSHELL}"
printf "SHLVL=%s\n"                 "${SHLVL}"
printf "%s\n\n"                     "-------------------"

exit 0
