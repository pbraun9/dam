#!/bin/bash

# assuming full path for alert_conf_path

function prep_alert {
        # beware of escapes for "`"
        cat <<EOF
$alert - $title
\`\`\`
$index
\`\`\`
$saved_search_url
EOF
	[[ -n $details ]] && echo "$details"
	echo "(throttle for today $day)"
}

[[ ! -x `which jq` ]] && echo install jq first && exit 1

[[ ! -r /data/dam/lib/send_webhook_sev.bash ]] && echo cannot read /data/dam/lib/send_webhook_sev.bash && exit 1
source /data/dam/lib/send_webhook_sev.bash

[[ -z $1 ]] && echo usage: ${0##*/} alert.conf && exit 1
alert_conf_path=$1
alert_conf=${alert_conf_path##*/}
alert=${alert_conf%\.conf}
alert=${alert#*/}

[[ ! -r $alert_conf_path ]] && echo cannot read $alert_conf_path && exit 1
source $alert_conf_path

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
    "size": 1,
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
    }
}
EOF`

(( $? > 0 )) && echo " $alert - error: request exited abormally (see /tmp/dam.alerts.$alert.*.json)" && exit 1

[[ -z $result ]] && echo \ $alert - error: result is empty && exit 1

hits=`echo "$result" | jq -r ".hits.total.value"`

# search query above returns max 1 hit anyway
(( hits > 0 )) && echo \ $alert - index/stream is alive \($hits hits\) - all good && exit 0

text=`prep_alert`

send_webhook_sev

