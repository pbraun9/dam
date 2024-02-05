#!/bin/bash

function prep_alert {
        # beware of escapes for "`"
        cat <<EOF
$alert - $title - found $hits hits within last $delay_minutes minutes

\`\`\`
$index
Lucene> $query
EOF

	# that is in regards to the first 100 hits
	for show_field in $show_fields; do
		echo $show_field
		echo "$result" | jq -r ".hits.hits[]._source.$show_field" | sort -uV | sed 's/^/\t/'
	done; unset show_field

	# TODO show IPs when there is no src.name nor dest.name
	# (this would require to fix the null answer from jq)

	cat <<EOF
\`\`\`

$saved_search_url
EOF
	[[ -n $details ]] && echo "$details"
	cat <<EOF
(throttle for today $day)
EOF
}

[[ ! -x `which jq` ]] && echo install jq first && exit 1

[[ -z $1 ]] && echo what alert.conf? && exit 1
alert_conf=$1
alert=${alert_conf%\.conf}
alert=${alert#*/}

[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
source /data/dam/dam.conf

[[ ! -r /data/dam/$alert_conf ]] && echo cannot read /data/dam/$alert_conf && exit 1
source /data/dam/$alert_conf

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo $alert - there is a lock already for today \($lock\) && exit 0

result=`cat <<EOF | tee /data/dam/traces/request.$alert.json | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd -d @-
{
    "size": 100,
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-${delay_minutes}m/m",
                            "to": "now/m"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

(( $? > 0 )) && echo -e "$alert - error: request exited abormally:\n$result" && exit 1

[[ -z $result ]] && echo $alert - error: result is empty && exit 1

# keep last trace for parsing manually and enhancing the requests
# no log rotation required, override every time
echo "$result" > /data/dam/traces/result.$alert.json

hits=`echo "$result" | jq -r ".hits.total.value"`

(( hits < 1 )) && echo $alert - no hits - all good && exit 0

text=`prep_alert`

if (( dummy == 1 )); then
	echo the following would be sent to $webhook
	echo "$text"
else
	echo -n $alert - sending webhook to slack ...
	curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
	touch $lock
	exit 1
fi

