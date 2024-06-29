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

[[ -z $1 ]] && echo path/to/alert.conf? && exit 1
alert_conf_path=$1
alert_conf=${alert_conf_path##*/}
alert=${alert_conf%\.conf}
alert=${alert#*/}

[[ ! -r $alert_conf_path ]] && echo cannot read $alert_conf_path && exit 1
source $alert_conf_path

# eventually override dummy=1
[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1
source /etc/dam/dam.conf

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo $alert - there is a lock already for today \($lock\) && exit 0

result=`cat <<EOF | tee /tmp/dam.$alert.request.json | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd -d @-
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

(( $? > 0 )) && echo -e "$alert - error: request exited abormally:\n$result" && exit 1

[[ -z $result ]] && echo $alert - error: result is empty && exit 1

# keep last trace for parsing manually and enhancing the requests
# no log rotation required, override every time
echo "$result" > /tmp/dam.$alert.result.json

hits=`echo "$result" | jq -r ".hits.total.value"`

# search query above returns max 1 hit anyway
(( hits > 1 )) && echo $alert - index/stream is alive \($hits hits\) - all good && exit 0

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

