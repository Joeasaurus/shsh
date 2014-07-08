# shsh::MagnetConverter

declare -A sshkey=(
	[name]="MagnetConverter",
	[version]="0.0.1"
)

function sshkey_init() {
	mkdir -p ${CD_LOCK}/.torrents
}

# onMessage ($1 = respondTo, $2 = from, $3 = msg)
function sshkey_onMessage() {
	WWWDIR="~/www"
	WWWURL="http://localhost"
	msg="$3"
	if [[ "${msg::1}" == "+" ]]; then
		msg="${msg:1}"
		cmd="not"
		link=""
		for param in $(echo "$msg" | tr " " "\n"); do
			if [[ "$cmd" == "not" ]]; then
				cmd="$param"
			elif [[ "x$link" == "x" ]]; then
				link="$param"
			elif [[ "x$link" != "x" ]]; then
				link="$link $param"
			fi
		done
		if [[ "$cmd" == "magnet" ]]; then
			if [[ "$link" =~ xt=urn:btih:([^&/]+) ]]; then
			        hashh=${BASH_REMATCH[1]}
			        if [[ "$link" =~ dn=([^&/]+) ]];then
			                filename=${BASH_REMATCH[1]}
			        else
			                filename=$hashh
			        fi
			        fn="meta-$filename.torrent"
			        lfn="${CD_LOCK}/.torrents/$fn"
			        touch $lfn
			        echo "d10:magnet-uri${#link}:${link}e" > $lfn
			        cp "$lfn" "$WWWDIR/$fn"
			        sendToServer PRIVMSG "$1" "Creation complete!"
			        sendToServer PRIVMSG "$1" "$WWWURL/$fn"
			else
			        sendToServer PRIVMSG "$1" "Invalid magnet link: xt=urn:btih:([^&/]+)"
			fi
		fi
	fi
}
