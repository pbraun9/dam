#!/bin/bash

debug=0

[[ ! -r /etc/dam/services/services.conf ]] && echo cannot read /etc/dam/services/services.conf && exit 1

echo `date --rfc-email` - $0

grep -vE '^#|^$' /etc/dam/services/services.conf | while read line; do
	host=`echo $line | awk '{print $1}'`
	svc=`echo $line | awk '{print $2}'`
	many=`echo $line | awk '{print $3}'`

	(( debug > 0 )) && echo host $host / svc $svc / many $many

	echo -n checking service $many $svc on $host ...
	/data/dam/check-svc.bash $host $svc $many && echo OK

	unset host svc many
done

echo

