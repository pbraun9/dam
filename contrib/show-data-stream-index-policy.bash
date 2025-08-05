#!/bin/bash
set -e

source /etc/dam/dam.conf

data_streams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | jq -r '.data_streams[].name'`

echo

for data_stream in $data_streams; do
	ds_indices=`curl -fsSk "$endpoint/_data_stream/$data_stream?pretty" -u $admin_user:$admin_passwd | \
		jq -r '.data_streams[].indices[].index_name' | sort -V`

	for index in $ds_indices; do

		chars_num=`echo -n $index | wc -c`
		#echo debug: $chars_num chars
		if (( chars_num < 24 )); then
			echo -ne "$index\t\t\t\t\t\t\t\t\t"
		elif (( chars_num < 32 )); then
			echo -ne "$index\t\t\t\t\t\t\t\t"
		elif (( chars_num < 40 )); then
			echo -ne "$index\t\t\t\t\t\t\t"
		elif (( chars_num < 48 )); then
			echo -ne "$index\t\t\t\t\t\t"
		elif (( chars_num < 56 )); then
			echo -ne "$index\t\t\t\t\t"
		elif (( chars_num < 64 )); then
			echo -ne "$index\t\t\t\t"
		elif (( chars_num < 72 )); then
			echo -ne "$index\t\t\t"
		elif (( chars_num < 80 )); then
			echo -ne "$index\t\t"
		else
			echo -ne "$index\t"
		fi

		curl -fsSk "$endpoint/_plugins/_ism/explain/$index" -u $admin_user:$admin_passwd | jq -r ".\"$index\".policy_id"

	done; unset index

	unset ds_indices chars_num
done; unset data_stream
echo

