#!/bin/bash

echo `date --rfc-email` - $0

cd /data/dam/vmetrics/

for conf in /etc/dam/vmetrics/*.conf; do
	./vmetrics-gauge.ksh $conf
done; unset conf

echo

