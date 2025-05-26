#!/bin/bash

# show detector configuration
# helps rebuild detectors from json

[[ -z $1 ]] && echo detector id? && exit 1
id=$1

# load credentials and endpoint
source /etc/dam/dam.conf

curl -sk --fail "$endpoint/_plugins/_anomaly_detection/detectors/$id?pretty" -u $user:$passwd

# &task=true

