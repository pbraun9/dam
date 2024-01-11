#!/bin/bash

# remains silent if everything is good

[[ -z $2 ]] && echo "usage: ${0##*/} host service [expected-pids]" && exit 1
host=$1
svc=$2
many=$3

source /data/dam/dam.conf

function check_pid {
	# works against suricata and websocat
	# multi-line required with multiple pids
	pids=`ssh -n $host pidof $svc | tr ' ' '\n'`

	# works against fluent-bit
	[[ -z $pids ]] && pids=`ssh -n $host pgrep $svc`
}

function send_webhook {
	text=$@

	echo "$text"
        echo -n sending webhook to slack ...
        curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $svc_webhook; echo
	touch $lock
        exit 1
}

[[ ! -x `which wc` ]] && echo cannot find wc executable && exit 1

hour=`date +%Y-%m-%d-%H:00`
lock=/var/lock/$host-$svc.$hour.lock

[[ -f $lock ]] && echo $host-$svc - there is a lock already for this hour \($hour\) && exit 0

check_pid

#
# alert function exists from here
#

[[ -z $pids ]] && send_webhook "service $svc is not running on $host (pid not found)"

pid=`echo "$pids" | head -1`
(( ! pid > 0 )) && send_webhook "service $svc is not running on $host (pid $pid should be a number)"

if [[ -n $many ]]; then
	pid_count=`echo "$pids" | wc -l`

	# the delay for handling custom made websocat scripts which reiterate every hour or so
	# there might be a little delay before it gets killed and restarted
	(( pid_count < many )) && echo $host-$svc - $pid_count/$many - checking again before sending alert \
		&& sleep 1 && check_pid \
		&& (( pid_count < many )) && send_webhook "only $pid_count pids for service $svc on $host while expecting $many"

	unset pid_count
fi

#
# everything went well, exit normally
#

unset pids pid

