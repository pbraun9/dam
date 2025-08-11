#!/bin/bash
set -e

source /etc/dam/dam.conf

indices=`curl -fsSk "$endpoint/_cat/indices?s=index" -u $user:$passwd | awk '{print $3}'`

echo
for index in $indices; do
	echo $index
	curl -sk "$endpoint/_cat/shards/$index?v" -u $user:$passwd
	echo
done; unset index

