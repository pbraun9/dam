#!/bin/bash
set -e

[[ -z $1 ]] && echo datastream? && exit 1
ds=$1

source /etc/dam/dam.conf

curl -fsSk -X POST "$endpoint/$ds/_rollover/?pretty" -u $admin_user:$admin_passwd

