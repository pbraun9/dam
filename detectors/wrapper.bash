#!/bin/bash

echo `date --rfc-email` - $0

source /etc/dam/dam.conf

for conf in /etc/dam/detectors/*.conf; do

	# avoid sourcing the whole alert conf in the wrapper
	detector_id=`grep ^detector_id $conf | cut -f2 -d=`

        state=`curl -fsSk "$endpoint/_plugins/_anomaly_detection/detectors/$detector_id/_profile" -u $user:$passwd | jq -r '.state'`

	if [[ $state = RUNNING ]]; then
		/data/dam/detectors/detector-results.ksh $conf
	elif [[ $state = DISABLED ]]; then
		echo warn: detector id $detector_id is $state
	else
		echo error: could not define detector id $detector_id state
		exit 1
	fi

	unset detector_id state
done; unset conf

