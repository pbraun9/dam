#!/bin/ksh
set -e

# 0|1|2
debug=1

#
# overall
# - count overall http codes 2xx
# - count overall http codes non-2xx
# - report on non-2xx precent above overall_fib
#
# per client
# - search for currently active remote_addr
# - count http codes 2xx per IP
# - count http codes non-2xx per IP
# - report on non-2xx precent above score_trigger
#
# assuming conf relative path /data/dam/spot/
#

[[ -z $2 ]] && echo -e \\n \ usage: ${0##*/} conf.d/conf delay \\n && exit 1
conf=/data/dam/spot/$1
delay=$2
frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

[[ ! -r /data/dam/damlib.ksh ]] && echo cannot read /data/dam/damlib.ksh && exit 1
[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
[[ ! -r $conf ]] && echo cannot read $conf && exit 1

source /data/dam/dam.conf
source /data/dam/damlib.ksh
source $conf

[[ -z $endpoint ]]	&& echo define endpoint in /data/dam/dam.conf && exit 1
[[ -z $user ]]		&& echo define user in /data/dam/dam.conf && exit 1
[[ -z $passwd ]]	&& echo define passwd in /data/dam/dam.conf && exit 1
[[ -z $webhook ]]       && echo define webhook in /data/dam/dam.conf && exit 1

[[ -z $index ]]		&& echo define index in $conf && exit 1
[[ -z $query_total ]]	&& echo define query_total in $conf && exit 1
[[ -z $query_nok ]]	&& echo define query_nok in $conf && exit 1
[[ -z $ref_delay ]]	&& echo define ref_delay in $conf && exit 1
[[ -z $ref_percent ]]	&& echo define ref_percent in $conf && exit 1
[[ -z $score_trigger ]]	&& echo define score_trigger in $conf && exit 1
[[ -z $overall_fib ]]   && echo define overall_fib in $conf && exit 1

[[ ! -x `whence jq` ]]	&& echo install jq first && exit 1
[[ ! -x `whence host` ]] && echo install host command first && exit 1

function count_overall {
	# less than 100 entries overall isn't really relevant
	# TODO make that dynamic/proportional
	(( total < 100 )) && echo \ overall - skip $total entries && return

	(( debug > 1 )) && echo "debug: (( $total < 100 ))"

	nok=`/data/dam/bin/count.bash $index "$query_nok" $delay`

	(( debug > 1 )) && echo "debug: nok $nok"

	# total and nok remain integers
	# avoid integer division with 1. float
	typeset -F 2 percent
	(( percent = nok * 1. / total * 100 ))

	(( debug > 1 )) && echo "debug: (( $percent = $nok * 1. / $total * 100 ))"

	typeset -F 3 result_fib
	(( result_fib = percent / ref_percent ))

	(( debug > 1 )) && echo "debug: (( $result_fib = $percent / $ref_percent ))"

	(( debug > 1 )) && echo "debug: (( $result_fib = $percent / $ref_percent ))"

	echo \ overall - nok http status $percent% out of $total entries as fib $result_fib

	if (( result_fib >= overall_fib )); then
		# $ref_delay $ref_percent $overall_fib
		text="$index $delay overall - nok http status $percent% out of $total entries ($result_fib)"

		echo " ALARM - $text"

		(( debug < 1 )) && echo -n \ sending webhook to slack ...
		(( debug < 1 )) && curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
		# do not exit here
	fi
}

function count_per_ip {
	[[ -z $ip ]] && echo func need ip && exit 1

	total=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "remote_addr:\"$ip\" AND $query_total"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now/$frame"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	# less than 10 entries per client isn't really relevant
	# TODO make that dynamic/proportional
	(( total < 10 )) && echo \ $ip - skip $total entries && return

	(( debug > 1 )) && echo debug: $ip - total $total

	nok=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "remote_addr:\"$ip\" AND $query_nok"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now/$frame"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	# total and nok remain integers
	# ref_percent remains untouched
	typeset -F 2 percent
	typeset -F 3 result_fib

	# avoid integer division with 1. float
	(( percent = nok * 1. / total * 100 ))

	(( debug > 1 )) && echo "debug: $ip - (( $percent = $nok * 1. / $total * 100 ))"

	(( result_fib = percent / ref_percent ))

	(( debug > 1 )) && echo "debug: $ip - (( $result_fib = $percent / $ref_percent ))"

	echo -e \ $ip - nok http status $percent% out of $total entries as fib $result_fib

	if (( result_fib > 1.000 )); then
		hits_per_second

		(( debug > 1 )) && echo debug: $ip - hits $hits

		typeset -F2 score

		(( score = hits * percent * result_fib ))

		(( debug > 1 )) && echo "debug: $ip - (( $score = $hits * $percent * $result_fib ))"

		if (( score > score_trigger )); then
			# $ref_delay $ref_percent $client_fib
			text="$index $delay $ip - nok http status $percent% out of $total entries as fib $result_fib for $hits hits per second and score $score"

			ptr=`host $ip | awk '{print $NF}'`
			text="$text - \`$ptr\`"

			echo " ALARM - $text"

			(( debug < 1 )) && echo -n \ sending webhook to slack ...
			(( debug < 1 )) && curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
			# do not exit here

			unset ptr
		else
			echo \ $ip - score $score below score_trigger $score_trigger
		fi

		unset score
	fi

	unset total nok percent result_fib hits
}

LC_NUMERIC=C

echo `date --rfc-email` - ${0##*/} - $index - $delay

#
# overall
#

# this variable we need thereafter
total=`/data/dam/bin/count.bash $index "$query_total" $delay`

(( debug > 1 )) && echo "debug: total $total"

typeset -F 2 ref_percent

(( debug > 1 )) && echo ref_percent $ref_percent

# variables in function are local
count_overall

#
# per client
#

ips=`/data/dam/bin/query.bash $index "$query_total" $delay | jq -r '.hits.hits[]._source.remote_addr'`

(( debug > 0 )) && echo debug: active ips are $ips

for ip in $ips; do
        count_per_ip
done; unset ip

echo

