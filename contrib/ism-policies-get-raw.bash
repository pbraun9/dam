#!/bin/bash
set -e

[[ -z $1 ]] && echo policy? && exit 1
policy=$1

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_plugins/_ism/policies/$policy?pretty" -u $admin_user:$admin_passwd

