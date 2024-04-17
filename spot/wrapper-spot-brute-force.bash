#!/bin/bash

[[ -z $1 ]] && echo delay? && exit 1
delay=$1

cd /data/dam/spot/

if [[ $delay = 3m ]]; then
	./spot-brute-force.ksh conf.d/nginx-prod.conf
elif [[ $delay = 1h ]]; then
	./spot-brute-force.ksh conf.d/nginx-dev.conf
else
	echo unknown delay
fi

