#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/indices?h=index,creation.date,docs.count,health&format=json&pretty" -u $user:$passwd \
	| jq -r '.[] | .index + "," + ."docs.count"' | grep ',0$' | sed 's/,0$//'

# https://opster.com/guides/opensearch/opensearch-capacity-planning/opensearch-oversharding/

