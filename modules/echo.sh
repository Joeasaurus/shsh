# shsh::Echo

declare -A echo=(
	[name]="Echo",
	[version]="0.0.1"
)

# onMessage ($1 = respondTo, $2 = from, $3 = message)
function echo_onMessage() {
	sendToServer PRIVMSG "$1" "It was stated that $2 once said: $3"
}
