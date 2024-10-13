#!/bin/ksh

LC_NUMERIC=C

[[ -z $2 ]] && echo "usage: ${0##*/} host trigger_p" && exit 1
host=$1
trigger=$2

source /etc/dam/dam.conf

[[ ! -r /etc/dam/services/space.conf ]] && echo \ error: cannot read /etc/dam/services/space.conf && exit 1

function check_space {
	echo "$spaces" | while read line; do
		mountpoint=`echo $line | awk '{print $NF}'`
		space=`echo $line | awk '{print $5}' | sed 's/%//'`

		if (( space >= trigger )); then
			echo \ $host $mountpoint $space% NOK
			send_webhook "running out of space on $host: $mountpoint is at $space%"
		else
			echo \ $host $mountpoint $space% OK
		fi

		unset mountpoint space
	done
}

function send_webhook {
	text=$@

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
	echo \ $host - there is a lock already for this hour \($lock\)
	exit 1
fi

# special case for localhost, no need to ssh
if [[ $host = `hostname` ]]; then
	spaces=`df -P | grep ^/dev/`
else
	ssh-ping -W1 -c1 $host </dev/null >/dev/null && host_alive=1 || host_alive=0
	if (( host_alive == 0 )); then
		echo \ $host - NOK cannot check disk space, ssh service not reachable
		send_webhook "cannot check disk space on $host, ssh service not reachable"
	fi
	spaces=`ssh -n $host df -P | grep ^/dev/`
fi

[[ -z $spaces ]] && echo \ error: could not find any mount point on $host && exit 1

check_space

