#!/bin/bash

# note you can update policy of a whole datastream, not just indices
[[ -z $2 ]] && echo policy index/datastream? && exit 1
policy=$1
index=$2

source /etc/dam/dam.conf

cat <<EOF | curl -fsSk -X POST -H "Content-Type: application/json" "$endpoint/_plugins/_ism/change_policy/$index" -u $admin_user:$admin_passwd -d@-
{
  "policy_id": "$policy"
}
EOF

echo

