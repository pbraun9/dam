#!/bin/bash

echo `date --rfc-email` - $0
/data/dam/detectors-config/list-detectors.bash | grep -vE '^#|^$' | grep ,RUNNING$ | while read line; do
	detector_name=`echo $line | cut -f1 -d,`
	detector_id=`echo $line | cut -f2 -d,`

	/data/dam/detectors/detector-results.ksh /etc/dam/detectors/$detector_name.conf $detector_id

	unset detector_name
done
echo

