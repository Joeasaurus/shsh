# shsh::Hash

declare -A hash=(
	[name]="Hash",
	[version]="0.0.1"
)

# onMessage ($1 = respondTo, $2 = from, $3 = msg)
function hash_onMessage() {
	msg="$3"
	if [[ "${msg::1}" == "+" ]]; then
		msg="${msg:1}"
		cmd="not"
		hash=""
		for param in $(echo "$msg" | tr " " "\n"); do
			if [[ "$cmd" == "not" ]]; then
				cmd="$param"
			elif [[ "x$hash" == "x" ]]; then
				hash="$param"
			elif [[ "x$hash" != "x" ]]; then
				hash="$hash $param"
			fi
		done
		if [[ "$cmd" == "hash" ]]; then
			sendToServer PRIVMSG "$1" "Hashing '$hash' ..."
			sendToServer PRIVMSG "$1" "MD5:    '$(echo -n $hash | md5sum)'"
			sendToServer PRIVMSG "$1" "SHA1:   '$(echo -n $hash | sha1sum)'"
			sendToServer PRIVMSG "$1" "SHA256: '$(echo -n $hash | sha256sum)'"
			sendToServer PRIVMSG "$1" "SHA512: '$(echo -n $hash | sha512sum)'"
		fi
	fi
}
