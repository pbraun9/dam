#!/bin/ksh
set -e

LC_NUMERIC=C

[[ -z $1 ]] && echo -e \\n usage: ${0##*/} vmetrics-conftype/config.conf \\n && exit 1
conf=$1
confshort=${conf##*/}
confshort=${confshort%\.conf}

source /data/dam/dam.conf

[[ -z $vmetrics_webhook ]] && echo \$vmetrics_webhook not defined && exit 1

source $conf

[[ -z $query ]] && echo \$query not defined && exit 1
[[ -z $max_value ]] && echo \$max_value not defined && exit 1

day=`date +%Y-%m-%d`

curl -s "http://localhost:8428/api/v1/query?query=$query" | \
	jq -r '.data.result[] | .metric.sensor + "," + .value[1]' | \
	while read line; do
		sensor=`echo $line | cut -f1 -d,`
		value=`echo $line | cut -f2 -d,`

		lock=/var/lock/$confshort.$day.$sensor.lock
		[[ -f $lock ]] && echo $confshort $sensor - there is a lock already for today \($lock\) && continue

		(( value > max_value )) && text="$confshort ALARM - sensor $sensor value $value is above $max_value"

		[[ -z $text ]] && continue

		text="$text
(throttle for today)"

		if (( dummy == 1 )); then
			echo the following would be sent to vmetrics_webhook $vmetrics_webhook
			echo "$text"
		else
			echo -n $confshort $sensor - sending vmetrics_webhook to slack ...
			curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $vmetrics_webhook; echo
			touch $lock
		fi

		unset sensor value lock text
	done

