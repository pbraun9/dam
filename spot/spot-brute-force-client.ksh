#!/bin/ksh
set -e

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
[[ -z $client_fib ]]	&& echo need client_fib && exit 1


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
	(( total < 10 )) && echo -e \ $ip \\t\\t skip \($total\) && return

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

	(( result_fib = percent / ref_percent ))

	(( debug > 0 )) && echo " DEBUG (( $result_fib = $percent / $ref_percent ))"

	echo -e \ $ip \\t\\t $percent \($total\) as fib $result_fib

	if (( result_fib >= client_fib )); then
		# $ref_delay $ref_percent $client_fib
		text="$index $delay $ip - nok http status $percent% out of $total entries ($result_fib)"

		ptr=`host $ip | awk '{print $NF}'`
		text="$text - \`$ptr\`"

		echo "ALARM - $text"

		echo -n sending webhook to slack ...
		(( debug < 1 )) && curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
		# do not exit here

		unset ptr
	fi

	unset total nok percent result_fib
}

LC_NUMERIC=C

echo $0 $delay - $index

ips=`/data/dam/bin/query.bash $index "$query_total" $delay | jq -r '.hits.hits[]._source.remote_addr'`

(( debug > 0 )) && echo -e \\n DEBUG active ips \\n $ips \\n

for ip in $ips; do
        count_per_ip
done; unset ip

