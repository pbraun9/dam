#!/bin/bash
set -e

source /data/dam/dam.conf

echo
echo VERSION
echo

curl -sk "$endpoint/?pretty" -u $user:$passwd

