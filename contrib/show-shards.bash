#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/shards" -u $admin_user:$admin_passwd

