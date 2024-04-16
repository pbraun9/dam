
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

# defines hits
hits_per_second() {
	[[ -z $delay ]] && bomb $0 misses delay
	[[ -z $frame ]] && bomb $0 misses frame
	[[ -z $total ]] && bomb $0 misses total

	(( debug > 1 )) && echo debug: delay is $delay
	(( debug > 1 )) && echo debug: frame is $frame
	(( debug > 1 )) && echo debug: total is $total

	typeset -F2 int=`echo $delay | sed -r 's/([[:digit:]])[[:alpha:]]/\1/'`

	(( debug > 1 )) && echo debug: int is $int

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

	(( debug > 1 )) && echo debug: hits is $hits

	[[ -z $hits ]] && bomb $0 failed to define hits
}

