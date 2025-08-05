#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_data_stream/_stats?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[] | (.store_size_bytes|tostring) + "," + .data_stream'

