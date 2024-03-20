#!/bin/bash

#
# this script remains silent as long as there's nothing to report
#
# warning / lessons learned: to avoid the "shallowing" issue,
# namely the ssh and ssh-ping commands to eat away the parent script while loop
# (this script is called by wrapper-svc.bash), we had to squeeze stdin.
# ssh -n
# ssh-ping </dev/null

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

	echo -n enabling 1 hour lock \($lock\) ...
	touch $lock && echo done

        exit 1
}

[[ ! -x `which wc` ]] && echo cannot find wc executable && exit 1
[[ ! -x `which ssh-ping` ]] && echo cannot find ssh-ping executable && exit 1

hour=`date +%Y-%m-%d-%H:00`
lock=/var/lock/$host-$svc.$hour.lock

if [[ -f $lock ]]; then
	echo $host-$svc - there is a lock already for this hour \($lock\)
	exit 1
fi

ssh-ping -W1 -c1 $host </dev/null >/dev/null && host_alive=1 || host_alive=0

#
# first alert exists from here
#

(( host_alive == 0 )) && send_webhook "cannot check service $svc on $host (ssh service not reachable)"

#
# proceed with the PID check
#

check_pid

#
# second alert exists from here
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

