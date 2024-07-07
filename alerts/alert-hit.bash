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

[[ ! -r /data/dam/lib/send_webhook_sev.bash ]] && echo cannot read /data/dam/lib/send_webhook_sev.bash && exit 1
source /data/dam/lib/send_webhook_sev.bash

[[ -z $1 ]] && echo usage: ${0##*/} alert.conf && exit 1
alert_conf=$1
alert=${alert_conf%\.conf}
alert=${alert##*/}

[[ ! -r $alert_conf ]] && echo cannot read $alert_conf && exit 1
source $alert_conf

# load overall settings after conf - eventually override dummy=1
[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1
source /etc/dam/dam.conf

(( dummy > 0 )) && echo DEBUG MODE ENABLED

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo \ $alert - there is a lock already for today \($lock\) && exit 0

result=`cat <<EOF | tee /tmp/dam.alerts.$alert.request.json | \
	curl -sk --fail -X POST -H "Content-Type: application/json" "$endpoint/$index/_search?pretty" -u $user:$passwd -d @- | \
	tee /tmp/dam.alerts.$alert.request.json
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

(( $? > 0 )) && echo " $alert - error: request exited abormally (see /tmp/dam.$alert.*.json)" && exit 1

[[ -z $result ]] && echo \ $alert - error: result is empty && exit 1

# keep last trace for parsing manually and enhancing the requests
# no log rotation required, override every time
echo "$result" > /tmp/dam.$alert.result.json

hits=`echo "$result" | jq -r ".hits.total.value"`

(( hits < 1 )) && echo \ $alert - no hits - all good && exit 0

text=`prep_alert`

send_webhook_sev

