#!/bin/bash

# remains silent if everything is good

[[ -z $2 ]] && echo usage: ${0##*/} ssh-host service && exit 1
host=$1
svc=$2

source /data/dam/dam.conf

function send_webhook {
	echo "$text"
        echo -n sending webhook to slack ...
        curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $svc_webhook; echo
        exit 1
}

# works against suricata
pids=`ssh -n $host pidof $svc`

# works against fluent-bit
[[ -z $pids ]] && pids=`ssh -n $host pgrep $svc`

pid=`echo "$pids" | head -1`

if [[ -n $pid ]]; then
	if (( ! pid > 0 )); then
		text="service $svc is not running on $host (pid $pid should be a number)"
	fi
else
	text="service $svc is not running on $host (pid $pid not found)"
fi

[[ -n $text ]] && send_webhook

unset pids pid

