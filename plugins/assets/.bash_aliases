alias ll='ls -lah'
alias histgrep='history | grep'
alias apt='sudo $(which apt)'
alias reboot='sudo $(which reboot)'
alias halt='sudo $(which alias)'
alias poweroff='sudo $(which poweroff)'
alias grep='grep --color'
alias hgrep='grep --color=always -e "^" -e '

function negrep(){
	fileName="${1:--}"
	printf "fileName=${fileName}\n" 1>&2
	grep --color=always -e "^" -e "^E:" -e "^W:" "${fileName}" \
		| grep --color=always -i "error\|warning\|problem\|fail\|fatal\|panic\|not found\|missing\|could not"
}
