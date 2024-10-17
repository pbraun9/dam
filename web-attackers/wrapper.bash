#!/bin/bash

#debug=1

[[ -z $1 ]] && echo delay? && exit 1
delay=$1

echo `date --rfc-email` - $0 $delay

cd /data/dam/web-attackers/

for conf in /etc/dam/web-attackers/*.conf; do
	(( debug > 0 )) && echo ./spot-brute-force.ksh $conf $delay && continue
	./spot-brute-force.ksh $conf $delay
done; unset conf

echo

