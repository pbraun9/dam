#!/bin/bash
set -e

source /etc/dam/dam.conf

output=`curl -fsSk "$endpoint/_plugins/_ism/policies?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.policies[] | ._id + "," + .policy.policy_id'`

echo "$output" | while read line; do
	_id=`echo $line | cut -f1 -d,`
	policy_id=`echo $line | cut -f1 -d,`

	[[ $_id != $policy_id ]] && echo something went wrong: _id $_id is not equal \
to policy_id $policy_id && exit 1

	echo $_id

	unset _id policy_id
done

