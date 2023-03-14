nextScript=test2.sh

printf "This is %s\n"               "${0}"
printf "BASH_SOURCE=%s\n"           ${BASH_SOURCE[*]}
printf "BASH_SUBSHELL=%s\n"         "${BASH_SUBSHELL}"
printf "SHLVL=%s\n"                 "${SHLVL}"
printf "%s\n\n"                     "-------------------"


"${nextScript}"

exit 0
