#!/bin/bash
set -e

# is there no way to do this using _cat?
# http://docs.opensearch.org/docs/latest/api-reference/cat/index/

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[].name'

