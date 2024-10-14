#!/bin/bash
set -e

[[ -z $1 ]] && echo index/data-stream ? && exit 1
index=$1

source /etc/dam/dam.conf

curl -fsSk -X POST "$endpoint/$index/_rollover/?pretty" -u $admin_user:$admin_passwd 

