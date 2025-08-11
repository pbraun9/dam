#!/bin/bash
set -e

# https://docs.opensearch.org/latest/api-reference/cat/cat-shards/

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/shards" -u $admin_user:$admin_passwd

