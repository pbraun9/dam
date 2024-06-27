#!/bin/bash
set -e

source /etc/dam/dam.conf

echo
echo UNASSIGNED SHARDS
echo

curl -sk "$endpoint/_cat/shards?h=index,shard,prirep,state,unassigned.reason&pretty" -u $user:$passwd \
	| grep UNASSIGNED

# https://repost.aws/knowledge-center/opensearch-unassigned-shards

