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
lock=/data/dam/$alert.$day.lock

[[ -f $lock ]] && echo $alert_conf - there is a lock already for today \($day\) && exit 0

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

(( hits < 1 )) && echo no hits \($hits\) - all good && exit 0

sensors=`echo "$result" | jq -r ".hits.hits[]._source.sensor" | sort -uV`

# no idea yet why this returns null
#src_names=`echo "$result" | jq -r ".hits.hits[]._source.src.name" | sort -uV`
src_names=`echo "$result" | grep src.name | sort -uV | cut -f4 -d'"'`

# no idea yet why this returns null
#dest_names=`echo "$result" | jq -r ".hits.hits[]._source.dest.name" | sort -uV`
dest_names=`echo "$result" | grep dest.name | sort -uV | cut -f4 -d'"'`

# TODO show IPs when there is no src.name nor dest.name
# (this would require to fix the null answer from jq)

text=`prep_alert`

touch $lock
if (( dummy == 1 )); then
	echo the following would be sent to $webhook
	echo "$text"
else
	echo -n sending webhook to slack ...
	curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook
	echo
fi

