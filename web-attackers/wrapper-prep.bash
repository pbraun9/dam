#!/bin/bash

# log format generated within
#echo `date --rfc-email` - $0

cd /data/dam/web-attackers/

for conf in /etc/dam/web-attackers/*.conf; do

	./spot-brute-force-prep.ksh $conf 1w
	./spot-brute-force-prep.ksh $conf 1h
	./spot-brute-force-prep.ksh $conf 3m

done; unset conf

#echo

