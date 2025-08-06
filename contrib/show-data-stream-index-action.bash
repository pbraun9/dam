#!/bin/bash
set -e

source /etc/dam/dam.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

echo
for data_stream in $data_streams; do
	echo $data_stream
	./show-indices-action.bash $data_stream
	echo
done; unset data_stream
echo

