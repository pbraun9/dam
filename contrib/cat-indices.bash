#!/bin/bash

# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-indices/

[[ -z $1 ]] && echo "sort order? health status index uuid pri rep docs.count docs.deleted store.size pri.store.size" \
	&& exit 1
sort=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/indices?s=$sort" -u $admin_user:$admin_passwd

