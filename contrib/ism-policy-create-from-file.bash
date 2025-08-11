#!/bin/bash
set -e

[[ -z $2 ]] && echo policy json_file? && exit 1
policy=$1
json_file=$2

[[ ! -r $json_file ]] && echo cannot read json file $json_file && exit 1

source /etc/dam/dam.conf

curl -fsSk -X PUT -H "Content-Type: application/json" \
	"$endpoint/_plugins/_ism/policies/$policy?pretty" \
	-u $admin_user:$admin_passwd -d@$json_file

echo

