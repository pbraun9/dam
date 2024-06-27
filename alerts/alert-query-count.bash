#!/bin/bash

function prep_alert {
        # beware of escapes for "`"
        cat <<EOF
$alert - $title

\`\`\`
$index
aggs $count_field (desc)
.aggregations.sig.buckets.0.doc_count > $count_trigger
\`\`\`

found $doc_count doc_count within last $delay_minutes minutes
$saved_dashboard_url --> ${count_field%\.keyword}
$saved_search_url

EOF

	# that is in regards to aggs size
	# multi-words multi-cols and multi-line
	cat <<EOF
$keys

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

result=`cat <<EOF | tee /tmp/dam.$alert.request.json | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd -d @-
{
    "size": 0,
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
    },
    "aggregations": {
        "count": {
            "terms": {
                "field": "$count_field",
                "size": 3,
                "order": [
                    {
                        "_count": "desc"
                    }
                ]
            }
        }
    }
}
EOF`

(( $? > 0 )) && echo -e "$alert - error: request exited abormally:\n$result" && exit 1

[[ -z $result ]] && echo $alert - error: result is empty && exit 1

# keep last trace for parsing manually and enhancing the requests
# no log rotation required, override every time
echo "$result" > /tmp/dam.$alert.result.json

# only get the most encountered field content (order desc): [0] instead of []
doc_count=`echo "$result" | jq -r ".aggregations.count.buckets[0].doc_count"`

(( doc_count < count_trigger )) && echo $alert - doc_count less than $count_trigger - all good && exit 0

# get all encountered field contents (according to aggs size)
keys=`echo "$result" | jq -r ".aggregations.count.buckets[] | (.doc_count|tostring) + \"\t\" + .key"`

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

