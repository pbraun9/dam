#!/bin/bash
set -e

source /etc/dam/dam.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

echo
for data_stream in $data_streams; do
	tmp=`./show-dsindices-date.bash $data_stream`
	if (( `echo "$tmp" | wc -l` == 1 )); then
		echo $data_stream
		./rollover.bash $data_stream
		echo
	fi
done; unset data_stream
echo

