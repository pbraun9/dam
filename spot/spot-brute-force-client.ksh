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

source /data/dam/dam.conf
source $conf

function count_per_ip {
	[[ -z $endpoint ]]	&& echo func need endpoint && exit 1
	[[ -z $user ]]		&& echo func need user && exit 1
	[[ -z $passwd ]]	&& echo func need passwd && exit 1
	[[ -z $webhook ]]	&& echo func need webhook && exit 1

	[[ -z $index ]]		&& echo func need index && exit 1
	[[ -z $ip ]]		&& echo func need ip && exit 1
	[[ -z $delay ]]		&& echo func need delay && exit 1
	[[ -z $frame ]]		&& echo func need frame && exit 1

	typeset -F 4 total nok percent

	total=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "remote_addr:\"$ip\" AND status:*"
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

	nok=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "remote_addr:\"$ip\" AND status:* AND !status:[200 TO 304]"
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

	(( percent = nok / total * 100 ))

	echo -e \ $ip \\t\\t $percent vs. $trigger

	text="$index $ip - nok http status $delay $percent% vs. $trigger% (ref $ref_delay $ref_percent% @$client_fib)"

	(( debug > 0 )) && echo "DEBUG - $text"

	if (( percent >= trigger )); then
		echo "ALARM - $text"

		echo -n sending webhook to slack ...
		curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
		# do not exit here
	fi

	unset total nok percent
}

[[ ! -x `whence jq` ]] && echo install jq first && exit 1

LC_NUMERIC=C

echo $0 $delay - $index

# set trigger level above the reference
(( trigger = client_fib * ref_percent ))

ips=`/data/dam/bin/query.bash $index 'status:* AND !remote_addr:\"10.0.0.0/8\"' 1m | jq -r '.hits.hits[]._source.remote_addr'`

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 0 )) && echo -e \\n active ips \\n $ips \\n

for ip in $ips; do
        count_per_ip
done; unset ip

