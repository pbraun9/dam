#!/bin/bash
set -e

[[ -z $1 ]] && echo index? && exit 1
index=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_plugins/_ism/explain/$index?pretty" -u $admin_user:$admin_passwd

