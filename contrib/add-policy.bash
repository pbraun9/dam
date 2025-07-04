#!/bin/bash

# note you can add/update policies against a whole datastream, not just indices
[[ -z $2 ]] && echo policy index/datastream? && exit 1
policy=$1
index=$2

source /etc/dam/dam.conf

echo applying $policy policy for all $index indices
cat <<EOF | curl -fsSk -X POST -H "Content-Type: application/json" "$endpoint/_plugins/_ism/add/$index" \
	-u $user:$passwd -d@- && echo done
{
  "policy_id": "$policy"
}
EOF

echo

