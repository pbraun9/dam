#!/bin/bash
set -e

[[ -z $1 ]] && echo datastream? && exit 1
datastream=$1

source /etc/dam/dam.conf

index=`curl -fsSk "$endpoint/_data_stream/$datastream?pretty" -u $admin_user:$admin_passwd | \
		jq -r '.data_streams[].indices[].index_name' | sort -V | tail -1`

output=`curl -fsSk "$endpoint/_plugins/_ism/explain/$index" -u $admin_user:$admin_passwd | \
        jq -r 'keys_unsorted[] as $index |
        select($index != "total_managed_indices") |
        .[$index] | $index + ","
        + .policy_id + ","
        + .state.name + ","
        + .action.name + ","
        + (.action.failed|tostring)'`

# we do not need a loop here (supposedly a single line of output) but it does the job
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

