#!/bin/bash
set -e

[[ -z $1 ]] && echo datastream? && exit 1
datastream=$1

source /etc/dam/dam.conf

index=`curl -fsSk "$endpoint/_data_stream/$datastream?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[].indices[].index_name' | sort -V | tail -1`

# echos index
source lib/padding.bash

curl -fsSk "$endpoint/$index/_settings?pretty" -u $admin_user:$admin_passwd | grep number_of_shards

