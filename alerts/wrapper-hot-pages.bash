#!/bin/bash

echo `date --rfc-email` - $0

for conf in `ls /etc/dam/hot-pages/*.conf 2>/dev/null`; do
	/data/dam/alerts/alert-query-count.ksh $conf
done; unset conf

echo

