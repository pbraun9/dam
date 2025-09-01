#!/bin/bash
set -e

source /etc/dam/dam.conf

datastreams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[].name'`

echo
for datastream in $datastreams; do
	echo $datastream
	./index-settings-date.bash $datastream
	echo
done; unset datastream
echo

