#!/bin/bash
set -e

#debug=1

source /etc/dam/dam.conf

(( debug > 0 )) && echo "curl -fsSk \"$endpoint/_cat/nodes?v&s=load_1m\" -u $user:$passwd" && exit

curl -fsSk "$endpoint/_cat/nodes?v&s=load_1m" -u $user:$passwd

