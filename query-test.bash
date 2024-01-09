#!/bin/bash
set -e

[[ -z $2 ]] && echo ${0##*/} index/stream json-file && exit 1
index=$1
file=$2

source dam.conf

[[ ! -r $file ]] && echo cannot read file $file && exit 1

curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd -d @$file

