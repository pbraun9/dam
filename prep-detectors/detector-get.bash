#!/bin/bash

[[ -z $2 ]] && echo detector name and id? && exit 1
name=$1
id=$2

# load credentials and endpoint
source /data/dam/dam.conf

curl -sk "$endpoint/_plugins/_anomaly_detection/detectors/$id?pretty" -u $user:$passwd | tee /data/dam/traces/detector-get.$name.json

	# &task=true

