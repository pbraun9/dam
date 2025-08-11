#!/bin/bash
set -e

[[ -z $2 ]] && echo index document-id ? && exit 1
index=$1
doc=$2

source /etc/dam/dam.conf

curl -fsSk -X DELETE "$endpoint/$index/_doc/$doc?pretty" -u $admin_user:$admin_passwd

echo

