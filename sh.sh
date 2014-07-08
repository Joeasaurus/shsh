# Load the irc lib
. "irc.sh"
# Load the config
. "config.sh"

# Make the fifo and set our traps
mkfifo $coprocPipe
trapFifo() {
	rm -rf "$coprocPipe"
}
trapSubshells() {
	echo "$$"
	eval "kill -- -${$}"
}
trapAll() {
	trapFifo; trapSubshells;
}
if [[ "$TRAP_EXIT" == "true" ]]; then
	trap trapAll EXIT
else
	trap trapFifo EXIT
fi

# Modules
declare -A modules=( [message]="" [init]="" )

# Eval environment
declare doThing_PID=""

# Add a module to the relevant array
addModule() {
	if [ "$2" == "function" ]; then
		if [ "${modules[$3]}" == "" ]; then
			modules["$3"]="$1_$4"
			if [[ "$3" == "init" ]]; then t=$("$1"_init); echo $t; fi
		else
			# Split by '+' because bash can't have 2d arrays
			modules["$3"]="${modules[$3]}+$1_$4"
		fi
	fi
}

# Callbacks / Overrides
onStartup() {
	# Load the modules.
	# Their functions *must* be named like 'modname_MesaageType'
	# Only loads onMessage functions
	# In truth it's all global namespace/shell env,
	#+ but we only call the ones in the array
	for module in $(ls modules | egrep '*.sh$'); do
		. "modules/$module"
		modName="${module%%.*}"
		addModule "$modName" "$(type -t "${modName}_init")" "init" "init"
		addModule "$modName" "$(type -t "${modName}_onMessage")" "message" "onMessage"
		
	done
	# Now we have to do all our inits
	for func in $(echo "${modules[init]}" | tr "+" "\n"); do
		$func
		sleep 1
	done
	# Without the sleep it tries the JOIN too quickly
	sleep 2
	sendToServer JOIN "$Channel"
	sleep 2
	newCoProc
}

# When we hear a PRIVMSG
onPRIVMSG() {
	[[ $# -ne 6 ]] && return
	local nick="$1"
	local target="$5"
	local message="$6"

	# Figure out where the response should go, and who to highlight
	respondTo=
	isChannel="true"
	if [[ "${target::1}" == "#" ]]; then
		respondTo="$target"
	else
		respondTo="$nick"
		isChannel=
	fi
	# '#' is the "eval the following" character
	if [[ "${message::1}" == "#" ]]; then
		message="${message:1}"
		if [[ $(echo "$rootUsers" | grep "$nick") ]]; then
			# Make a new coproc if someone did exit() etc
			# Else send the channel with control char '?'
			#+ and then the message
			if [[ ! $(ps -p $evalEnv_PID) ]];then
				newCoProc
				sleep 2
			fi
			echo "?$respondTo" >&${evalEnv[1]}
			echo "$message" >&${evalEnv[1]}
		else
			sendToServer PRIVMSG "$respondTo" "You are not a root user"
		fi
	else
		# Runs the relevant module functions (only message atm)
		local messageHandlers=${modules[message]}
		local privmsgHandlers=${modules[privmessage]}
		if [[ isChannel ]]; then
			for func in $(echo "$messageHandlers" | tr "+" "\n"); do
				$func "$respondTo" "$nick" "$message"
				sleep 1
			done
		else
			for func in $(echo "$privmsgHandlers" | tr "+" "\n"); do
				$func "$respondTo" "$nick" "$message"
				sleep 1
			done
		fi
	fi
}

# Create our new 'sandbox'
newCoProc() {
	# Kill this to start completely fresh
	kill -9 "$doThing_PID" 2>/dev/null
	coproc evalEnv {
		mkdir -p "$CD_LOCK";
		cd $CD_LOCK;
		cd() {
			echo "bash: You can't cd";
			return 0;
		}
		# We should be able to set up the shell env here
		#+ override 'rm' etc
		readLine() {
			read -u0 input
			if [[ "${input::1}" != "?" ]]; then
				if [[ $(expr "$input" : '.*cd()') -eq 0 ]]; then
					eval "$input"
				else 
					echo "bash: You can't cd"
				fi
			else
				echo "$input"
			fi
			readLine;
		};
		readLine;
        # doThing will get access to $coprocPipe but not ${evalEnv[0]}
        #+ which is why we do it this way with an extra fifo
	} 1>$coprocPipe 2>&1
        doThing() {
        	local chan=""
			while IFS= read x; do
				# Send the error without line info (not sophisticated)
				if [[  $(echo "$x" | cut -d':' -f1) == "./sh.sh" ]]; then
					sendToServer PRIVMSG "$chan" "$(echo $x | cut -d':' -f3-9)"
				elif [[ "${x::1}" == "?" ]]; then
					chan="${x:1}"
				else
					sendToServer PRIVMSG "$chan" "$x"
				fi
			done <$coprocPipe
        }
        doThing "$respondTo" &
        doThing_PID="$!"
}

# Connect to the server and start up the bot!
connect
onConnect
onStartup
while [[ $? -eq 0 ]]; do
    readFromServer onMessage
done
