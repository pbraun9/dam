#!/bin/bash
set -e

[[ -z $1 ]] && echo ${0##*/} index/stream && exit 1
index=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/$index/_mappings?pretty" -u $user:$passwd

