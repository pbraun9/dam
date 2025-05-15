#!/bin/bash
set -e

# col7 is docs.count
# col9 is store.size
# https://docs.opensearch.org/docs/latest/api-reference/cat/cat-indices/

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/indices?expand_wildcards=hidden,open&pri=true&bytes=b" -u $user:$passwd
# &v

