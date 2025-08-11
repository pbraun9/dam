#!/bin/bash
set -e

source /etc/dam/dam.conf

datastreams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

for datastream in $datastreams; do
	./ism-explain-ds-policy-leaf.bash $datastream
done; unset datastream

