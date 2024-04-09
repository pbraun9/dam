#!/bin/bash

[[ -z $1 ]] && echo delay? && exit 1
delay=$1

for conf in /data/dam/spot/conf.d/*.conf; do

	/data/dam/spot/spot-brute-force-overall.ksh $conf $delay

done; unset conf

