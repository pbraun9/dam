#!/bin/ksh
set -e

#(( debug = 1 ))

LC_NUMERIC=C

[[ -z $1 ]] && echo -e \\n usage: ${0##*/} /etc/dam/vmetrics/RESOURCE.conf \\n && exit 1
conf=$1
confshort=${conf##*/}
confshort=${confshort%\.conf}

source /etc/dam/dam.conf

[[ -z $vmetrics_webhook ]]  && echo vmetrics_webhook not defined && exit 1
[[ -z $vmetrics_endpoint ]] && echo vmetrics_endpoint not defined && exit 1

source $conf

[[ -z $query ]]		&& echo query not defined && exit 1
[[ -z $value_hint ]]	&& echo value_hint not defined && exit 1
[[ -z $max_value ]]	&& echo max_value not defined && exit 1
[[ -z $url ]]		&& echo url not defined && exit 1

day=`date +%Y-%m-%d`

echo \ $confshort triggers at $max_value $value_hint

# handle various labels
# - sensor comes from flb
# - cluster+host comes from yandex metrics
# - cluster+resource_id comes from yandex metrics
# - instance comes from yandex metrics

curl -s "$vmetrics_endpoint" -d "query=$query" | \
	tee /tmp/dam.$confshort.json | \
	jq -r '.data.result[] | .value[1] + "," + .metric.cluster + "," + .metric.sensor + "," + .metric.host + "," + .metric.resource_id + "," + .metric.instance' | \
	while read line; do
		typeset -F 2 value

		value=`echo $line | cut -f1 -d,`
		cluster=`echo $line | cut -f2 -d,`
		sensor=`echo $line | cut -f3 -d,`

		(( i = 4 ))
		while [[ -z $sensor ]]; do
			sensor=`echo $line | cut -f$i -d,`
			(( i++ ))
		done
		unset i

		lock=/var/lock/$confshort.$day.$sensor.lock
		[[ -f $lock ]] && echo \ $confshort $sensor - there is a lock already for today \($lock\) && continue

		# after lock filename definition
		[[ -n $cluster ]] && sensor="$cluster/$sensor"

		if (( value >= max_value )); then
			text="$confshort $sensor $value $value_hint NOK"
			echo " $text"
		else
			(( debug > 0 )) && echo " $confshort $sensor $value $value_hint OK" || echo -n .
			continue
		fi

		(( debug > 0 )) && continue

		text="$text - $url
(throttle for today $day)"

		echo -n sending vmetrics_webhook ...
		curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $vmetrics_webhook; echo
		touch $lock

		unset sensor value lock text
	done

