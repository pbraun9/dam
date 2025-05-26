#!/bin/bash
set -e

# last col is node name
# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-allocation

source /etc/dam/dam.conf

# w/o header line (no &v)
curl -fsSk "$endpoint/_cat/allocation?s=shards" -u $user:$passwd | \
while read -r line; do
        shards=`echo $line | awk '{print $1}'`
        node=`echo $line | awk '{print $NF}' | sed 's/.mdb.yandexcloud.net$//'`

        cat <<EOF
{ "shards": $shards, "node": "$node" }
EOF

        unset shards node
done

