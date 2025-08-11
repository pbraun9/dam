#!/bin/bash
set -e

# pass1 sort already
# pass2 convert to GiB

source /etc/dam/dam.conf

output=`curl -fsSk "$endpoint/_data_stream/_stats?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[] | (.store_size_bytes|tostring) + "," + .data_stream' | \
	sort -V`

# note there's no docs count here
# note total_store_size_bytes == .data_streams.store_size_bytes

echo "$output" | while read line; do
	size=`echo $line | cut -f1 -d,`
	index=`echo $line | cut -f2 -d,`

	# echos index
	source lib/padding.bash

	echo $(( size /1024 /1024 /1024 )) GiB

	unset index size
done

