#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -sk "$endpoint/_cat/shards?pretty" -u $admin_user:$admin_passwd

