#!/bin/ksh
set -e

# 0|1|2
debug=0

#
# - search for currently active remote_addr
# - count http codes 2xx per IP
# - count http codes non-2xx per IP
# - report on non-2xx precent above trigger
#
# assuming conf full path
#

[[ -z $2 ]] && echo conf delay? && exit 1
conf=$1
delay=$2
frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

source /data/dam/dam.conf
source /data/dam/damlib.ksh
source $conf

[[ -z $endpoint ]]	&& echo need endpoint && exit 1
[[ -z $user ]]		&& echo need user && exit 1
[[ -z $passwd ]]	&& echo need passwd && exit 1
[[ -z $webhook ]]	&& echo need webhook && exit 1

[[ -z $index ]]		&& echo need index && exit 1
[[ -z $query_total ]]	&& echo need query_total && exit 1
[[ -z $query_nok ]]	&& echo need query_nok && exit 1
[[ -z $ref_delay ]]	&& echo need ref_delay && exit 1
[[ -z $ref_percent ]]	&& echo need ref_percent && exit 1
#[[ -z $client_fib ]]	&& echo need client_fib && exit 1
[[ -z $score_trigger ]]	&& echo need score_trigger && exit 1


[[ ! -x `whence jq` ]]	&& echo install jq first && exit 1
[[ ! -x `whence host` ]] && echo install host command first && exit 1

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

	(( debug > 0 )) && echo debug: $ip - total $total

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

	(( debug > 0 )) && echo "debug: $ip - (( $percent = $nok * 1. / $total * 100 ))"

	(( result_fib = percent / ref_percent ))

	(( debug > 0 )) && echo "debug: $ip - (( $result_fib = $percent / $ref_percent ))"

	echo -e \ $ip - nok http status $percent% out of $total entries as fib $result_fib

	if (( result_fib > 1.000 )); then
		hits_per_second

		(( debug > 0 )) && echo debug: $ip - hits $hits

		typeset -F2 score

		(( score = hits * percent * result_fib ))

		(( debug > 0 )) && echo "debug: $ip - (( $score = $hits * $percent * $result_fib ))"

		if (( score > score_trigger )); then
			# $ref_delay $ref_percent $client_fib
			text="$index $delay $ip - nok http status $percent% out of $total entries as fib $result_fib for $hits hits per second and score $score"

			ptr=`host $ip | awk '{print $NF}'`
			text="$text - \`$ptr\`"

			echo " ALARM - $text"

			echo -n \ sending webhook to slack ...
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

ips=`/data/dam/bin/query.bash $index "$query_total" $delay | jq -r '.hits.hits[]._source.remote_addr'`

(( debug > 0 )) && echo debug: active ips: $ips

for ip in $ips; do
        count_per_ip
done; unset ip

echo

