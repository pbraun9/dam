#!/bin/bash
set -e

[[ -z $2 ]] && echo "<ds prefix> <1d|1w|1m|3m> [exclude_file]" && exit 1
dsprefix=$1
delay=$2
exclude_file=$3

[[ -n $exclude_file ]] && echo $exclude_file is defined
[[ -n $exclude_file && -f $exclude_file ]] && echo $exclude_file is there

time1d=86400
# 7d
time1w=604800
# 30d
time1m=2592000
# 90d
time3m=7776000

source /etc/dam/dam.conf

function index_unixtime {
	[[ -z $1 ]] && echo function $0 index? && exit 1

	curl -fsSk "$endpoint/$1/_settings?pretty" -u $admin_user:$admin_passwd | grep creation_date | cut -f4 -d'"' | sed -r 's/[[:digit:]]{3}$//'
}

datastreams=`curl -fsSk "$endpoint/_data_stream/?pretty" -u $admin_user:$admin_passwd | \
	jq -r '.data_streams[].name' | grep ^$dsprefix`

time=`date +%s`

if [[ $delay = 1d ]]; then
	(( trigger_time = time - time1d ))
elif [[ $delay = 1w ]]; then
	(( trigger_time = time - time1w ))
elif [[ $delay = 1m ]]; then
	(( trigger_time = time - time1m ))
elif [[ $delay = 3m ]]; then
	(( trigger_time = time - time3m ))
else
	echo choose 1d 1w 1m 3m as for delay
	exit 1
fi

echo trigger_time goes `date -R -d@$trigger_time`

echo
for datastream in $datastreams; do
	echo $datastream

	if [[ -n $exclude_file && -f $exclude_file ]]; then
		tmp=`grep ^$datastream $exclude_file` || true
		[[ -n $tmp ]] && echo SKIP && continue
		unset tmp
	fi

	dsindices=`curl -fsSk "$endpoint/_data_stream/$datastream?pretty" -u $admin_user:$admin_passwd | \
		jq -r '.data_streams[].indices[].index_name' | sort -V`

	if (( `echo "$dsindices" | wc -l` < 2 )); then
		echo warn: $datastream has only one index

		# no need to rollover recent indices
		unixtime_single=`index_unixtime $dsindices`
		if (( unixtime_single <= trigger_time )); then
			echo warn: index is `date -R -d@$unixtime_single` - rolling over
			# breaks when rollover fails - we want to continue seeking for eligible deletions
			../datastream-rollover.bash $datastream || true
		fi

		continue
	fi

	oldest=`echo "$dsindices" | head -1`
	second_oldest=`echo "$dsindices" | sed -n 2p`

	unixtime_oldest=`index_unixtime $oldest`
	unixtime_second_oldest=`index_unixtime $second_oldest`

	if (( unixtime_second_oldest <= trigger_time )); then
		echo -ne "we are good to delete $oldest\t"
		date -R -d@$unixtime_oldest

		echo -ne "second oldest index $second_oldest\t"
		date -R -d@$unixtime_second_oldest

		../index-delete.bash $oldest
	fi
done; unset datastream
echo

