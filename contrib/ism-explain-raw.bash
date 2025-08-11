#!/bin/bash
set -e

# note you can get policy details against a whole datastream, not just indices
[[ -z $1 ]] && echo index/datastream? && exit 1
index=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_plugins/_ism/explain/$index?pretty" -u $admin_user:$admin_passwd

