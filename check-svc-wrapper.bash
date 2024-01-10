#!/bin/bash

echo `date --rfc-email` - ${0##*/}
grep -vE '^#|^$' /data/dam/check-svc-wrapper.conf | while read line; do
	host=`echo $line | awk '{print $1}'`
	svc=`echo $line | awk '{print $2}'`
	many=`echo $line | awk '{print $3}'`

	echo -n checking service $many $svc on ssh-host $host ...
	/data/dam/check-svc.bash $host $svc $many && echo OK || echo NOK

	unset host svc
done
echo

