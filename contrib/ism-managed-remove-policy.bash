#!/bin/bash
set -e

# works for both indices and datastreams
[[ -z $1 ]] && echo index/datastream? && exit 1
index=$1

source /etc/dam/dam.conf

curl -fsSk -X POST "$endpoint/_plugins/_ism/remove/$index?pretty" -u $admin_user:$admin_passwd

