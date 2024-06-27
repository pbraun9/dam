#!/bin/bash
set -e

#[[ -z $1 ]] && echo ${0##*/} index/stream && exit 1
#index=$1

source /etc/dam/dam.conf

curl -sk "$endpoint/_cat/shards?pretty" -u $user:$passwd

