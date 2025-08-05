#!/bin/bash
set -e

source /etc/dam/dam.conf

[[ -z $1 ]] && echo index? && exit 1
index=$1

curl -fsSk -X DELETE "$endpoint/$index" -u $admin_user:$admin_passwd
echo

