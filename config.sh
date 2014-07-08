## shsh Config

# Kill children ourselves on exit?
TRAP_EXIT=true

# Server etc
declare -r pServer="irc.example.com"
declare -r pPort=6667
declare -r pNick="shsh"
declare -r pUser="shsh"
declare -r pRealname="Shadow Shell"
declare -r pPassword=""

# Channels to join
declare -r Channel="#shsh"

# Who can eval?
declare -r rootUsers="Joeasaurus"

# Dir to lock cd to
declare -r coprocPipe="/tmp/shsh"
declare -r CD_LOCK="/tmp/shshlock"
