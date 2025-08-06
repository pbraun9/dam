#!/bin/bash
set -e

[[ -z $1 ]] && echo datastream? && exit 1
data_stream=$1

source /etc/dam/dam.conf

dsindices=`curl -fsSk "$endpoint/_data_stream/$data_stream?pretty" -u $admin_user:$admin_passwd | \
                jq -r '.data_streams[].indices[].index_name' | sort -V`

for dsindex in $dsindices; do
	echo -en "$dsindex\t"
	tmp_json=`curl -fsSk "$endpoint/_plugins/_ism/explain/$dsindex?pretty" -u $admin_user:$admin_passwd | \
		sed -r 's/^[[:alnum:].-]+[[:space:]]+\{/{/;
			s/^  \"[[:alnum:].-]+\"[[:space:]]*:[[:space:]]+\{/"index": {/'`
	action=`echo "$tmp_json" | jq -r '.index.action.name'`
	failed=`echo "$tmp_json" | jq -r '.index.action.failed'`
	#retry_failed=`echo "$tmp_json" | jq -r '.index.retry_info.failed'`
	# .index.index

	#echo -e "\t$action\tfailed:$failed\tretry failed:$retry_failed"
	echo -e "\t$action\tfailed:$failed"

	unset tmp_json
done; unset dsindex

