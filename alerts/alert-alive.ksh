#!/bin/ksh

# assuming full path for alert_conf_path

function prep_alert {
        # beware escapes are in there
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

[[ ! -r /data/dam/lib/send_webhook_sev.ksh ]] && echo cannot read /data/dam/lib/send_webhook_sev.ksh && exit 1
source /data/dam/lib/send_webhook_sev.ksh

[[ -z $1 ]] && echo usage: ${0##*/} alert.conf && exit 1
alert_conf_path=$1
alert_conf=${alert_conf_path##*/}
alert=${alert_conf%\.conf}
alert=${alert#*/}

[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1
[[ ! -r $alert_conf_path ]] && echo cannot read $alert_conf_path && exit 1

source /etc/dam/dam.conf
source $alert_conf_path

day=`date +%Y-%m-%d`
lock=/var/lock/$alert.$day.lock

[[ -f $lock ]] && echo \ $alert - there is a lock already for today \($lock\) && exit 0

request=`cat <<EOF9
{
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
EOF9`

(( debug > 0 )) && echo -e "curl -fsSk -X POST -H \"Content-Type: application/json\" $endpoint/$index/_count?pretty -u $user:$passwd -d @-\n$request" || true

result=`cat <<EOF | curl -fsSk -X POST -H "Content-Type: application/json" \
	"$endpoint/$index/_count?pretty" -u $user:$passwd -d @-
$request
EOF`

(( $? > 0 )) && echo " $alert - error: request exited abormally (see /tmp/dam.alerts.$alert.*.json)" && exit 1

[[ -z $result ]] && echo \ $alert - error: result is empty && exit 1

(( debug > 0 )) && echo -e "\nresult is\n$result" || true

# search api
#hits=`echo "$result" | jq -r ".hits.total.value"`

# count api
hits=`echo "$result" | jq -r ".count"`

(( debug > 0 )) && echo hits is $hits || true

# search query above returns max 1 hit anyway
(( hits > 0 )) && echo \ $alert - index/stream is alive \($hits hits\) - all good && exit 0

text=`prep_alert`

send_webhook_sev

