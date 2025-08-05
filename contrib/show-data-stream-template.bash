#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | \
	tee /tmp/dam.contrib.show-data-streams.json | \
	jq -r '.data_streams[] | [ .name, .template ] | @tsv' \
	| column -t

# https://baeldung.com/linux/json-string-table-convert

