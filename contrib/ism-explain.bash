#!/bin/bash
set -e

# note you can get policy details against a whole datastream, not just indices
[[ -z $1 ]] && echo index/datastream? && exit 1
index=$1

source /etc/dam/dam.conf

output=`curl -fsSk "$endpoint/_plugins/_ism/explain/$index?pretty" -u $admin_user:$admin_passwd | \
	jq -r 'keys_unsorted[] as $index |
	select($index != "total_managed_indices") |
	.[$index] | $index + ","
	+ .policy_id + ","
	+ .state.name + ","
	+ .action.name + ","
	+ (.action.failed|tostring)'`

echo "$output" | while read line; do
	 index=`echo $line | cut -f1 -d,`
	policy=`echo $line | cut -f2 -d,`
	 state=`echo $line | cut -f3 -d,`
	action=`echo $line | cut -f4 -d,`
	failed=`echo $line | cut -f5 -d,`

	# echos index
	source lib/padding.bash

	if [[ $failed = false ]]; then
		status=OK
	elif [[ $failed = true ]]; then
		status=FAIL
	else
		echo could not define \$failed
		exit 1
	fi

	echo -e "$policy\t$state\t$action\t$status"

	unset index policy state action failed status
done

