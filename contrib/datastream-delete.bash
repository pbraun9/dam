#!/bin/bash
set -e

# https://docs.opensearch.org/latest/im-plugin/data-streams/

source /etc/dam/dam.conf

[[ -z $1 ]] && echo datastream? && exit 1
ds=$1

curl -fsSk -X DELETE "$endpoint/_data_stream/$ds" -u $admin_user:$admin_passwd
echo

