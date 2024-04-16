#!/bin/ksh

debug=0

#
# assuming conf full path
#

[[ -z $2 ]] && echo conf delay? && exit 1
conf=$1
delay=$2

[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
[[ ! -r $conf ]] && echo cannot read $conf && exit 1

source /data/dam/dam.conf
source $conf

[[ -z $webhook ]]	&& echo define webhook in /data/dam/dam.conf && exit 1

[[ -z $index ]]		&& echo define index in $conf && exit 1
[[ -z $ref_delay ]]	&& echo define ref_delay in $conf && exit 1
[[ -z $ref_percent ]]	&& echo define ref_percent in $conf && exit 1
[[ -z $overall_fib ]]	&& echo define overall_fib in $conf && exit 1

LC_NUMERIC=C

echo `date --rfc-email` - ${0##*/} - $index - $delay

total=`/data/dam/bin/count.bash $index "$query_total" $delay`

# less than 100 entries overall isn't really relevant
# TODO make that dynamic/proportional
(( total < 100 )) && echo -e \ overall \\t\\t skip \($total\) && exit

nok=`/data/dam/bin/count.bash $index "$query_nok" $delay`

# total and nok remain integers
# (ref_percent survives here)
typeset -F 2 ref_percent percent
typeset -F 3 result_fib

# avoid integer division with 1. float
(( percent = nok * 1. / total * 100 ))

(( result_fib = percent / ref_percent ))

(( debug > 0 )) && echo "debug: (( $result_fib = $percent / $ref_percent ))"

echo \ overall - nok http status $percent% out of $total entries as fib $result_fib

if (( result_fib >= overall_fib )); then
	# $ref_delay $ref_percent $overall_fib
	text="$index $delay overall - nok http status $percent% out of $total entries ($result_fib)"

	echo " ALARM - $text"

        echo -n \ sending webhook to slack ...
        (( debug < 1 )) && curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
        exit 1
fi

echo

