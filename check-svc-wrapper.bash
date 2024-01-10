#!/bin/bash

echo `date --rfc-email` - ${0##*/}
grep -vE '^#|^$' /data/dam/check-svc.conf | while read line; do
	host=`echo $line | awk '{print $1}'`
	svc=`echo $line | awk '{print $2}'`

	echo -n checking service $svc on ssh-host $host ...
	/data/dam/check-svc.bash $host $svc && echo OK || echo NOK

	unset host svc
done
echo

