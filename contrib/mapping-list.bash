#!/bin/bash

index="logs-suricata1"

# load credentials and endpoint
source /data/dam/dam.conf

curl -sk "$endpoint/$index/_mapping" -u $user:$passwd | \
	jq -r '.[].mappings.properties | delpaths([path(..) | select(length > 2)])'

