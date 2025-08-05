#!/bin/bash
set -e

source /etc/dam/dam.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

echo

for data_stream in $data_streams; do
	leaf_index=`curl -fsSk "$endpoint/_data_stream/$data_stream?pretty" -u $admin_user:$admin_passwd | \
		jq -r '.data_streams[].indices[].index_name' | sort -V | tail -1`

	chars_num=`echo -n $leaf_index | wc -c`
	#echo debug: $chars_num chars
	if (( chars_num < 24 )); then
		echo -ne "$leaf_index\t\t\t\t\t\t\t\t\t"
	elif (( chars_num < 32 )); then
		echo -ne "$leaf_index\t\t\t\t\t\t\t\t"
	elif (( chars_num < 40 )); then
		echo -ne "$leaf_index\t\t\t\t\t\t\t"
	elif (( chars_num < 48 )); then
		echo -ne "$leaf_index\t\t\t\t\t\t"
	elif (( chars_num < 56 )); then
		echo -ne "$leaf_index\t\t\t\t\t"
	elif (( chars_num < 64 )); then
		echo -ne "$leaf_index\t\t\t\t"
	elif (( chars_num < 72 )); then
		echo -ne "$leaf_index\t\t\t"
	elif (( chars_num < 80 )); then
		echo -ne "$leaf_index\t\t"
	else
		echo -ne "$leaf_index\t"
	fi

	curl -fsSk "$endpoint/$leaf_index/_settings?pretty" -u $admin_user:$admin_passwd | grep number_of_shards

	unset leaf_index chars_num
done; unset data_stream
echo

# index to datastream
# echo $idx | sed -r 's/^.ds-//; s/-[[:digit:]]+$//'`

