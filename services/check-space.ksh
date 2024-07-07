#!/bin/ksh

LC_NUMERIC=C

[[ -z $2 ]] && echo "usage: ${0##*/} host trigger_p" && exit 1
host=$1
trigger=$2

source /etc/dam/dam.conf

[[ ! -r /etc/dam/services/space.conf ]] && echo \ error: cannot read /etc/dam/services/space.conf && exit 1

function check_space {
	[[ -z $spaces ]] && echo \ error: could not find any mount point on $host && exit 1
	for space in $spaces; do
		text="running out of space on $host: some moint point is at $space%"
		(( space >= trigger )) && echo \ $text && send_webhook "$text" \
			|| echo " $host is fine: some moint point is at $space%"
		unset text
	done; unset space
}

function send_webhook {
	text=$@

	echo "$text"

        echo -n \ sending svc_webhook ...
        curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $svc_webhook; echo

	echo -n \ enabling 1 hour lock \($lock\) ...
	touch $lock && echo done

        exit 1
}

[[ ! -x `which wc` ]] && echo \ error: cannot find wc executable && exit 1
[[ ! -x `which ssh-ping` ]] && echo \ error: cannot find ssh-ping executable && exit 1

hour=`date +%Y-%m-%d-%H:00`
lock=/var/lock/$host-space.$hour.lock

if [[ -f $lock ]]; then
	echo $host-space - there is a lock already for this hour \($lock\)
	exit 1
fi

# special case for localhost, no need to ssh
if [[ $host = `hostname` ]]; then
	spaces=`df -P | grep ^/dev/ | awk '{print $5}' | sed 's/%//'`
	check_space
	exit 0
fi

ssh-ping -W1 -c1 $host </dev/null >/dev/null && host_alive=1 || host_alive=0

(( host_alive == 0 )) && send_webhook "cannot check disk space on $host (ssh service not reachable)"

spaces=`ssh -n $host df -P | grep ^/dev/ | awk '{print $5}' | sed 's/%//'`
check_space

