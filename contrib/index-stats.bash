#!/bin/bash
set -e

# pass1 sort already
# pass2 convert to GiB and Mil

[[ -z $1 ]] && echo "datastream?" && exit 1
datastream=$1

source /etc/dam/dam.conf

output=`curl -fsSk "$endpoint/$datastream/_stats/store,docs?pretty" -u $user:$passwd | \
	jq -r '.indices | keys_unsorted[] as $k | .[$k] | $k + ","
	+ (.primaries.store.size_in_bytes|tostring) + ","
	+ (.primaries.docs.count|tostring)' | sort -V`

echo "$output" | while read line; do
	index=`echo $line | cut -f1 -d,`
	bytes=`echo $line | cut -f2 -d,`
	 docs=`echo $line | cut -f3 -d,`

        # echos index
        source lib/padding.bash

	echo -e "$(( bytes /1024 /1024 /1024 )) GiB\t$(( docs /1000 /1000 )) Mil"

	unset index bytes docs
done; unset line

