#!/bin/bash
set -e

# last col is node name
# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-allocation

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/allocation?s=shards" -u $user:$passwd
# &v
# s=disk.avail

