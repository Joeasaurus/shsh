# shsh::SSHKey

declare -A sshkey=(
	[name]="SSHKey",
	[version]="0.0.1"
)

function sshkey_init() {
	mkdir -p ${CD_LOCK}/.sshkeys
}

# onMessage ($1 = respondTo, $2 = from, $3 = msg)
function sshkey_onMessage() {
	msg="$3"
	if [[ "${msg::1}" == "+" ]]; then
		msg="${msg:1}"
		cmd="not"
		for param in $(echo "$msg" | tr " " "\n"); do
			if [[ "$cmd" == "not" ]]; then
				cmd="$param"
			fi
		done
		if [[ "$cmd" == "sshkey" ]]; then
			passphrase="$(shuf -i 10000-99999 -n 1)"
			sendToServer PRIVMSG "$1" "Creating SSH key.." 
			ssh-keygen -N "$passphrase" -b 2048 -C "Created by shsh::SSHKey $(date +%s)" -t rsa -f ${CD_LOCK}/.sshkeys/key -q
			sendToServer PRIVMSG "$2" "+SSHKey::Public ----------------"
			sendToServer PRIVMSG "$2" "$(cat $CD_LOCK/.sshkeys/key.pub)"
			sendToServer PRIVMSG "$2" "+SSHKey::Private ---------------"
			while IFS= read x; do
				sendToServer PRIVMSG "$2" "$x"
			done < $CD_LOCK/.sshkeys/key
			sendToServer PRIVMSG "$2" "+SSHKey::Passphrase ----------"
			sendToServer PRIVMSG "$2" "$passphrase"
			sendToServer PRIVMSG "$1" "Created, check my private message."
			rm -rf ${CD_LOCK}/.sshkeys/key*
		fi
	fi
}