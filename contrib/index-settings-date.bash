#!/bin/bash
set -e

[[ -z $1 ]] && echo datastream? && exit 1
datastream=$1

source /etc/dam/dam.conf

dsindices=`curl -fsSk "$endpoint/_data_stream/$datastream?pretty" -u $admin_user:$admin_passwd | \
                jq -r '.data_streams[].indices[].index_name' | sort -V`

for dsindex in $dsindices; do
	echo -en "$dsindex\t"
	unixtime=`curl -fsSk "$endpoint/$dsindex/_settings?pretty" -u $admin_user:$admin_passwd | grep creation_date | cut -f4 -d'"' | sed -r 's/[[:digit:]]{3}$//'`
	date -R -d@$unixtime
	unset unixtime
done; unset dsindex

