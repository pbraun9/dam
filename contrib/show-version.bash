#!/bin/bash
set -e

source dam.conf

echo
echo VERSION
echo

curl -sk "$endpoint/?pretty" -u $user:$passwd

