#!/bin/bash
set -e

source /etc/dam/dam.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

for data_stream in $data_streams; do
	./index-settings-shard-num-leaf.bash
done; unset data_stream

