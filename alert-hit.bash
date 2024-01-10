#!/bin/bash

function prep_alert {
        # beware of escapes for "`"
        cat <<EOF
$alert - $title

\`\`\`
$index
Lucene> $query
\`\`\`

found $hits hits within last $delay_minutes minutes
$saved_search_url
EOF
	[[ -n $details ]] && echo "$details"
	echo

	# that is in regards to the first 100 hits
	# output as one-liners
	echo sensors: $sensors
	echo source names: $src_names
	echo destination names: $dest_names

	cat <<EOF

(throttle for today $day)
EOF
}

[[ ! -x `which jq` ]] && echo install jq first && exit 1

[[ -z $1 ]] && echo what alert.conf? && exit 1
alert_conf=$1
alert=${alert_conf%\.conf}

[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
source /data/dam/dam.conf

[[ ! -r /data/dam/$alert_conf ]] && echo cannot read /data/dam/$alert_conf && exit 1
source /data/dam/$alert_conf

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo $alert_conf - there is a lock already for today \($lock\) && exit 0

result=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
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

hits=`echo "$result" | jq -r ".hits.total.value"`

(( hits < 1 )) && echo $alert_conf - no hits \($hits\) - all good && exit 0

sensors=`echo "$result" | jq -r ".hits.hits[]._source.sensor" | sort -uV`

# no idea yet why this returns null
#src_names=`echo "$result" | jq -r ".hits.hits[]._source.source.geo.name" | sort -uV`
src_names=`echo "$result" | grep source.geo.name | sort -uV | cut -f4 -d'"'`

# no idea yet why this returns null
#dest_names=`echo "$result" | jq -r ".hits.hits[]._source.destination.geo.name" | sort -uV`
dest_names=`echo "$result" | grep destination.geo.name | sort -uV | cut -f4 -d'"'`

# TODO show IPs when there is no src.name nor dest.name
# (this would require to fix the null answer from jq)

text=`prep_alert`

if (( dummy == 1 )); then
        echo "$result" > /data/dam/result.debug.json && echo wrote to /data/dam/result.debug.json
	echo the following would be sent to $webhook
	echo "$text"
else
	echo -n sending webhook to slack ...
	curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
	touch $lock
	exit 1
fi

