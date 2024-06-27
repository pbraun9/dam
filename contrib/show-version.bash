#!/bin/bash
set -e

source /etc/dam/dam.conf

echo
echo VERSION
echo

curl -sk "$endpoint/?pretty" -u $user:$passwd

