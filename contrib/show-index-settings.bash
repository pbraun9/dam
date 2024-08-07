#!/bin/bash
set -e

[[ -z $1 ]] && echo "usage: ${0##*/} <index/stream>" && exit 1
index=$1

source /etc/dam/dam.conf

echo
echo SETTINGS
echo

curl -sk "$endpoint/$index/_settings?pretty" -u $user:$passwd

