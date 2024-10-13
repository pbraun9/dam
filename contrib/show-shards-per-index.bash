#!/bin/bash
set -e

source /etc/dam/dam.conf

indices=`curl -fsSk "$endpoint/_cat/indices/?v" -u $user:$passwd | sed 1d | sort -V -k3 | awk '{print $3}'`

echo
for index in $indices; do
	echo === $index ===
	curl -sk "$endpoint/_cat/shards/$index?v" -u $user:$passwd
	echo
done; unset index

