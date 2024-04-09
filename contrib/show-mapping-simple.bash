#!/bin/bash
set -e

[[ -z $1 ]] && echo ${0##*/} index/stream && exit 1
index=$1

source dam.conf

echo
echo MAPPINGS
echo

curl -sk "$endpoint/$index/_mappings?pretty" -u $user:$passwd

echo

