
function check_var {
	tmp=`eval echo \\${$1}`
	[[ -z $tmp ]] && echo error: define $1 && exit 1
	unset tmp
}

# defines hits globally
hits_per_second() {
	[[ -z $delay ]] && echo error: $0 misses delay && exit 1
	[[ -z $frame ]] && echo error: $0 misses frame && exit 1
	[[ -z $total ]] && echo error: $0 misses total && exit 1

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
	elif [[ $frame = d ]]; then
		(( hits = total / ( int * 24 * 60 * 60 ) ))
	elif [[ $frame = w ]]; then
		(( hits = total / ( int * 7 * 24 * 60 * 60 ) ))
	elif [[ $frame = M ]]; then
		(( hits = total / ( int * 52 * 7 * 24 * 60 * 60 ) ))
	else
		echo error: $0 - unknown frame - $frame && exit 1
	fi

	unset int

	(( debug > 1 )) && echo debug: hits is $hits

	[[ -z $hits ]] && echo error: $0 failed to define hits && exit 1
}

