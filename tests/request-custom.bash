#!/bin/bash
set -e

[[ -z $2 ]] && echo "usage: ${0##*/} <index/stream> <json-file>" && exit 1
index=$1
file=$2

source /etc/dam/dam.conf

[[ ! -r $file ]] && echo cannot read file $file && exit 1

curl -fsSk -X POST -H "Content-Type: application/json" -u $user:$passwd \
        "$endpoint/$index/_search?pretty" \
	-d @$file

(( $? > 0 )) && echo error: curl request failed && exit 1

