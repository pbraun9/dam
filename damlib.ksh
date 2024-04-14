
function bomb {
	echo
	echo "error: $@"
	echo
	exit 1
}

function check_var {
	tmp=`eval echo \\${$1}`
	[[ -z $tmp ]] && bomb define $1
	unset tmp
}

# requires delay frame total
# defines hits
function hits_per_second {
	int=`echo $delay | sed -r 's/([[:digit:]])[[:alpha:]]/\1/'`

	typeset -F2 hits

	if [[ $frame = m ]]; then
		(( hits = total / ( int * 60 ) ))
	elif [[ $frame = h ]]; then
		(( hits = total / ( int * 60 * 60 ) ))
	elif [[ $frame = h ]]; then
		(( hits = total / ( int * 24 * 60 * 60 ) ))
	elif [[ $frame = w ]]; then
		(( hits = total / ( int * 7 * 24 * 60 * 60 ) ))
	elif [[ $frame = M ]]; then
		(( hits = total / ( int * 52 * 7 * 24 * 60 * 60 ) ))
	else
		bomb $0 - unknown frame - $frame
	fi

	unset int
}

