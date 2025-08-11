#!/bin/bash
set -e

# https://docs.opensearch.org/latest/api-reference/cat/cat-nodes/

[[ -z $1 ]] && echo "sort order? ip heap.percent ram.percent cpu load_1m load_5m load_15m node.role node.roles \
cluster_manager name" && exit 1
sort=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/nodes?v&s=$sort" -u $user:$passwd

