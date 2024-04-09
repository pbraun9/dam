#!/bin/bash
set -e

[[ -z $1 ]] && echo ${0##*/} index/stream && exit 1
index=$1

source dam.conf

echo
echo SETTINGS
echo

curl -sk "$endpoint/$index/_settings?pretty" -u $user:$passwd

