#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -sk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd > /tmp/dam.contrib.data-streams.json

cat /tmp/dam.contrib.data-streams.json | jq -r '.data_streams[].name'

