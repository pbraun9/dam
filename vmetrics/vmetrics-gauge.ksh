#!/bin/ksh
set -e

function send_alarm {
	# || true - let the lock happen thereafter, whatever happens with the alarm
	echo -n sending vmetrics_webhook ...
	cat <<EOF | curl -sX POST -H 'Content-type: application/json' -d@- $vmetrics_webhook || true; echo
{
  "text": "$sensor [$confshort]($url) $value $value_hint NOK",
  "username": "$vmetrics_webhook_username",
  "icon_url": "$vmetrics_webhook_icon_url"
}
EOF
  #"channel": "$vmetrics_webhook_channel",
}

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

echo -n " $confshort triggers at $max_value $value_hint "

# handle various labels
# - sensor comes from flb
# - cluster+host comes from yandex metrics
# - cluster+resource_id comes from yandex metrics
# - instance comes from yandex metrics

curl -s "$vmetrics_endpoint" -d "query=$query" | \
	tee /tmp/dam.$confshort.json | \
	jq -r '.data.result[] | .value[1] + "," + .metric.cluster + "," + .metric.sensor + "," + .metric.host + "," + .metric.resource_id + "," + .metric.instance + "," + .metric.index' | \
	while read line; do
		typeset -F 2 value

		value=`echo $line | cut -f1 -d,`
		cluster=`echo $line | cut -f2 -d,`
		resource_id=`echo $line | cut -f5 -d,`

		# special case for opensearch metrics, they also add 'sensor' which conflicts with ours
		[[ ! $resource_id = opensearch ]] && sensor=`echo $line | cut -f3 -d,`

		# we already checked field 3 (.sensor) selectively
		(( i = 4 ))
		while [[ -z $sensor ]]; do
			sensor=`echo $line | cut -f$i -d,`
			(( i++ ))
			(( i > 10 )) && echo error: cycled through more than 10 keys && exit 1
		done
		unset i

		# hotfix for blackbox-exporter - strip url crap
		sensor=`echo $sensor | sed -r 's@^https?://([^/]+).*@\1@'`

		lock=/var/lock/$confshort.$day.$sensor.lock

		if [[ -f $lock ]]; then
			echo -n \($lock\)
		else
			# after lock filename definition
			[[ -n $cluster ]] && sensor="$cluster/$sensor"

			if (( value >= max_value )); then
				echo " $sensor [$confshort]($url) $value $value_hint NOK"

				(( ! debug > 0 )) && send_alarm
				(( ! debug > 0 )) && touch $lock
			else
				(( debug > 0 )) && echo " $confshort $sensor $value $value_hint OK" || echo -n .
			fi
		fi

		unset value cluster resource_id sensor lock
	done

