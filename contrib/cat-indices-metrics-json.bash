#!/bin/bash
set -e

# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-indices/

source /etc/dam/dam.conf

# col7 is docs.count
# col9 is store.size
# w/o header line (no &v)
curl -fsSk "$endpoint/_cat/indices?expand_wildcards=hidden,open&pri=true&bytes=b" -u $user:$passwd | \
while read -r line; do
        index=`echo $line | awk '{print $3}'`
        docs_count=`echo $line | awk '{print $7}'`
        primary_store_size=`echo $line | awk '{print $10}'`

	(( docs_count == 0 )) && continue
	(( primary_store_size < 512 )) && continue

        cat <<EOF
{ "index": "$index", "docs_count": $docs_count, "primary_store_size": $primary_store_size }
EOF

        unset index docs size
done

