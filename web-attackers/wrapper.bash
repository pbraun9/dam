#!/bin/bash

[[ -z $1 ]] && echo delay? && exit 1
delay=$1

# log format generated within
#echo `date --rfc-email` - $0

cd /data/dam/web-attackers/

for conf in /etc/dam/web-attackers/*.conf; do

	./spot-brute-force.ksh $conf $delay

done; unset conf

#echo

