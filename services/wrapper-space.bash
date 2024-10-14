#!/bin/bash

[[ ! -r /etc/dam/services/space.conf ]] && echo cannot read /etc/dam/services/space.conf && exit 1

echo `date --rfc-email` - $0

grep -vE '^#|^$' /etc/dam/services/space.conf | while read line; do
	host=`echo $line | awk '{print $1}'`
	trigger=`echo $line | awk '{print $2}'`

	/data/dam/services/check-space.ksh $host $trigger

	unset host trigger
done

echo

