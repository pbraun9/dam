#!/bin/ksh
set -e

LC_NUMERIC=C

[[ -z $1 ]] && echo -e \\n usage: ${0##*/} vmetrics-conftype/config.conf \\n && exit 1
conf=$1
confshort=${conf##*/}
confshort=${confshort%\.conf}

source /data/dam/dam.conf

[[ -z $vmetrics_webhook ]] && echo ERROR \$vmetrics_webhook not defined && exit 1
[[ -z $vmetrics_endpoint ]] && echo ERROR \$vmetrics_endpoint not defined && exit 1
[[ -z $vmetrics_url ]] && echo ERROR \$vmetrics_url not defined && exit 1

source $conf

[[ -z $query ]] && echo ERROR \$query not defined && exit 1
[[ -z $max_value ]] && echo ERROR \$max_value not defined && exit 1
[[ -z $url_suffix ]] && echo ERROR \$url_suffix not defined && exit 1

day=`date +%Y-%m-%d`

curl -s "$vmetrics_endpoint" -d "query=$query" | \
	tee /data/dam/traces/$confshort.json | \
	jq -r '.data.result[] | .metric.sensor + "," + .value[1]' | \
	while read line; do
		typeset -F 2 value

		sensor=`echo $line | cut -f1 -d,`
		value=`echo $line | cut -f2 -d,`

		lock=/var/lock/$confshort.$day.$sensor.lock
		[[ -f $lock ]] && echo $confshort $sensor - there is a lock already for today \($lock\) && continue

		if (( value > max_value )); then
			text="$confshort ALARM - sensor $sensor value $value is above $max_value"
		else
			echo $confshort $sensor - value $value is fine, nothing to report
			continue
		fi

		text="$text
${vmetrics_url}${url_suffix}
(throttle for today $day)"

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

