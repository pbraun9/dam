#!/bin/bash

function prep_alert {
        # beware of escapes for "`"
        cat <<EOF
$alert - $title

\`\`\`
$index
DQL> $query
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
alert=${alert#*/}

[[ ! -r /data/dam/$alert_conf ]] && echo cannot read /data/dam/$alert_conf && exit 1
source /data/dam/$alert_conf

# eventually override dummy=1
[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1
source /etc/dam/dam.conf

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo $alert - there is a lock already for today \($lock\) && exit 0

# with DQL we need a full json entry in place of the query
# e.g. source.ip:x.x.x.x/x becomes "source.ip": "x.x.x.x/x"
match_query=`echo $query | sed -r 's/^([^:]+):([^:]+)$/"\1": "\2"/'`

result=`cat <<EOF | tee /tmp/dam.$alert.request.json | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd -d @-
{
    "size": 100,
    "query": {
        "bool": {
            "filter": [
                {
                    "bool": {
                        "should": [
                            {
                                "match": {
                                    $match_query
                                }
                            }
                        ],
                        "minimum_should_match": 1
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
echo "$result" > /tmp/dam.$alert.result.json

hits=`echo "$result" | jq -r ".hits.total.value"`

(( hits < 1 )) && echo $alert - no hits - all good && exit 0

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
	echo the following would be sent to $webhook
	echo "$text"
else
	echo -n $alert - sending webhook to slack ...
	curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
	touch $lock
	exit 1
fi

