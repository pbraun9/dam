#!/bin/bash
set -e

# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-indices/

source /etc/dam/dam.conf

# col7 is docs.count
# col9 is store.size
curl -fsSk "$endpoint/_cat/indices?expand_wildcards=hidden,open&pri=true&bytes=b" -u $user:$passwd

