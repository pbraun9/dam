#!/bin/bash
set -e

# https://repost.aws/knowledge-center/opensearch-unassigned-shards

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/shards?h=index,shard,prirep,state,unassigned.reason&pretty" -u $user:$passwd \
	| grep UNASSIGNED

