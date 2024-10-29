#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/allocation?v&s=shards" -u $user:$passwd
# s=disk.avail

