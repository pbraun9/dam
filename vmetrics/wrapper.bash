#!/bin/bash

#debug=1

echo `date --rfc-email` - $0

cd /data/dam/vmetrics/

for conf in /etc/dam/vmetrics/*.conf; do
	(( debug > 0 )) && echo ./vmetrics-gauge.ksh $conf && continue
	./vmetrics-gauge.ksh $conf
	echo
done; unset conf

echo

