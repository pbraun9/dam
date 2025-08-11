#!/bin/bash
set -e

# pass1 sort already
# pass2 convert to GiB and Mil

[[ -z $1 ]] && echo "datastream?" && exit 1
datastream=$1

source /etc/dam/dam.conf

output=`curl -fsSk "$endpoint/$datastream/_stats/store,docs?pretty&level=shards" -u $user:$passwd | \
	jq -r '.indices | keys_unsorted[] as $index | .[$index] | .shards |
        keys_unsorted[] as $shard | .[$shard][] |
        select(.routing.primary == true) |
        $index + ","
        + ($shard|tostring) + ","
        + .routing.node + ","
        + (.store.size_in_bytes | tostring) + ","
        + (.docs.count | tostring)' | sort -V`
        #+ (.routing.primary | tostring) + ","

echo "$output" | while read line; do
        index=`echo $line | cut -f1 -d,`
	shard=`echo $line | cut -f2 -d,`
	index=$index/$shard
        bytes=`echo $line | cut -f4 -d,`
         docs=`echo $line | cut -f5 -d,`

	# echos index
	source lib/padding.bash

	echo -e "$(( bytes /1024 /1024 /1024 )) GiB\t$(( docs /1000 /1000 )) Mil"

	unset index shard bytes docs
done; unset line

