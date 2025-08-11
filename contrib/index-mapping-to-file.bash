#!/bin/bash

# https://docs.opensearch.org/latest/api-reference/index-apis/put-mapping/

[[ -z $1 ]] && echo index pattern? && exit 1
index="$1"

source /etc/dam/dam.conf

# echo curl -fsSk "$endpoint/$index/_mapping?pretty" -u $user:$passwd && echo

tmp=/tmp/dam.show-mapping.full.json
dest=/tmp/dam.show-mapping.json

echo -n writing to $tmp ...
curl -sk "$endpoint/$index/_mapping?pretty" -u $user:$passwd > $tmp && echo done
echo

echo -n writing to $dest ...
cat $tmp | jq -r '.[].mappings.properties | delpaths([path(..) | select(length > 2)])' > $dest && echo done
echo

rm -f $tmp

echo check $dest for results
echo

