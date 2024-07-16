#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -sk "$endpoint/_cat/indices/?v&pretty" -u $user:$passwd | sort -V -k3

