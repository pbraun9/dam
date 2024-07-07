#!/bin/bash

echo `date --rfc-email` - $0

# conf becomes the path if there's no .conf there - fix with ls instead of glob

# check that data-streams are alive
echo \ elk alive index alerts
for conf in `ls /etc/dam/alert-alive/*.conf 2>/dev/null`; do
	/data/dam/alerts/alert-alive.bash $conf
done; unset conf

echo \ elk count query alerts
for conf in `ls /etc/dam/alert-aggs/*.conf 2>/dev/null`; do
	/data/dam/alerts/alert-count.bash $conf
done; unset conf

echo \ elk search query alerts
for conf in `ls /etc/dam/alert-hits/*.conf 2>/dev/null`; do
        /data/dam/alerts/alert-hit.bash $conf
done; unset conf

echo \ elk search and count query alerts
for conf in `ls /etc/dam/alert-query-aggs/*.conf 2>/dev/null`; do
	/data/dam/alerts/alert-query-count.bash $conf
done; unset conf

echo

