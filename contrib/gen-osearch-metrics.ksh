#!/bin/ksh
set -e

# w/o header line
allocation_output=`/data/dam/contrib/show-allocation.bash | sed 1d`

echo "$allocation_output" | while read -r line; do
	shards=`echo $line | awk '{print $1}'`
	node=`echo $line | awk '{print $NF}' | sed 's/.mdb.yandexcloud.net$//'`

	cat <<EOF
{ "shards": $shards, "node": "$node" }
EOF

	unset shards node
done

