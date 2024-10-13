#!/bin/bash

debug=1

[[ ! -x `which jq` ]] && echo install jq first && exit 1

[[ -z $1 ]] && echo index pattern? && exit 1
index="$1"

# load credentials and endpoint
source /etc/dam/dam.conf

echo
echo show index mappings
echo

(( debug > 0 )) && echo curl -fsSk "$endpoint/$index/_mapping?pretty" -u $user:$passwd && echo

dest=/tmp/dam.show-mapping.full.json
echo -n writing to $dest ...
curl -sk "$endpoint/$index/_mapping?pretty" -u $user:$passwd > $dest && echo done
echo

dest=/tmp/dam.show-mapping.json
echo -n writing to $dest ...
cat /tmp/dam.show-mapping.full.json \
	| jq -r '.[].mappings.properties | delpaths([path(..) | select(length > 2)])' > $dest && echo done
echo

