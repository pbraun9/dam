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

[[ ! -x `which jq` ]] && echo error: install jq first && exit 1

[[ ! -r /data/dam/lib/send_webhook_sev.bash ]] && echo error: cannot read /data/dam/lib/send_webhook_sev.bash && exit 1
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

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo \ $alert - there is a lock already for today \($lock\) && exit 0

result=`cat <<EOF | tee /tmp/dam.alerts.$alert.request.json | \
	curl -sk --fail -X POST -H "Content-Type: application/json" "$endpoint/$index/_search?pretty" -u $user:$passwd -d @- | \
	tee /tmp/dam.alerts.$alert.result.json
{
    "size": 0,
    "query": {
        "bool": {
            "filter": [
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

(( $? > 0 )) && echo " $alert - error: request exited abormally (see /tmp/dam.alerts.$alert.*.json)" && exit 1

[[ -z $result ]] && echo \ $alert - error: result is empty && exit 1

# only get the most encountered field content (order desc): [0] instead of []
doc_count=`echo "$result" | jq -r ".aggregations.count.buckets[0].doc_count"`

(( doc_count < count_trigger )) && echo \ $alert - doc_count less than $count_trigger - all good && exit 0

# get all encountered field contents (according to aggs size)
keys=`echo "$result" | jq -r ".aggregations.count.buckets[] | (.doc_count|tostring) + \"\t\" + .key"`

text=`prep_alert`

send_webhook_sev

