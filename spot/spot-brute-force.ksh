#!/bin/ksh
set -e

# 0|1|2
debug=0

#
# overall
# - count overall http codes 2xx
# - count overall http codes non-2xx
# - report on non-2xx precent above overall_fib
#
# per vhost & client
# - search for currently active item
# - count http codes 2xx per item
# - count http codes non-2xx per item
# - report on non-2xx precent above score_trigger
#
# assuming conf relative path /data/dam/spot/
#

[[ -z $2 ]] && echo -e \\n \ usage: ${0##*/} conf.d/conf delay \\n && exit 1
conf=/data/dam/spot/$1
delay=$2
frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

[[ ! -r /data/dam/damlib.ksh ]] && echo cannot read /data/dam/damlib.ksh && exit 1
[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
[[ ! -r $conf ]] && echo cannot read $conf && exit 1

source /data/dam/dam.conf
source /data/dam/damlib.ksh
source $conf

[[ -z $endpoint ]]	&& echo define endpoint in /data/dam/dam.conf && exit 1
[[ -z $user ]]		&& echo define user in /data/dam/dam.conf && exit 1
[[ -z $passwd ]]	&& echo define passwd in /data/dam/dam.conf && exit 1
[[ -z $webhook ]]       && echo define webhook in /data/dam/dam.conf && exit 1

[[ -z $index ]]		&& echo define index in $conf && exit 1
[[ -z $query_total ]]	&& echo define query_total in $conf && exit 1
[[ -z $query_nok ]]	&& echo define query_nok in $conf && exit 1
[[ -z $remote_addr_field ]] && echo define remote_addr_field in $conf && exit 1
[[ -z $vhost_field ]]	&& echo define vhost_field in $conf && exit 1
[[ -z $score_trigger ]]	&& echo define score_trigger in $conf && exit 1
[[ -z $overall_fib ]]   && echo define overall_fib in $conf && exit 1

[[ ! -x `whence jq` ]]	&& echo install jq first && exit 1
[[ ! -x `whence host` ]] && echo install host command first && exit 1

function count_overall {
	typeset -g total=$overall_total

	# less than 100 entries overall isn't really relevant
	# TODO make that dynamic/proportional
	(( overall_total < 100 )) && echo \ overall - skip $overall_total entries && return 1

	(( debug > 1 )) && echo "debug: (( $overall_total < 100 ))"

	typeset -g nok=`/data/dam/bin/count.bash $index "$query_nok" $delay`

	(( debug > 1 )) && echo "debug: nok $nok"

	return 0
}

function count_per_vhost {
	[[ -z $vhost ]] && echo function $0 needs vhost && exit 1

        typeset -g total=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
                "$endpoint/$index/_count?pretty" -u $user:$passwd \
                -d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query_total AND $vhost_field:\"$vhost\""
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	(( debug > 1 )) && echo debug: $vhost - total $total

	typeset -g nok=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query_nok AND $vhost_field:\"$vhost\""
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	(( debug > 1 )) && echo debug: $vhost - nok $nok

	return 0
}

function count_per_ip {
	[[ -z $ip ]] && echo function $0 needs ip && exit 1

	typeset -g total=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query_total AND $remote_addr_field:\"$ip\""
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	(( debug > 1 )) && echo debug: $ip - total $total

	# less than 10 entries per client isn't really relevant
	# TODO make that dynamic/proportional
	(( total < 10 )) && echo \ $ip - skip $total entries && return 1

	typeset -g nok=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
		"$endpoint/$index/_count?pretty" -u $user:$passwd \
		-d @- | jq -r .count
{
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$remote_addr_field:\"$ip\" AND $query_nok"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    }
}
EOF`

	(( debug > 1 )) && echo debug: $ip - nok $nok

	return 0
}

function attack_score {
	item_type=$1
	[[ -z $item_type ]] && echo function $0 needs item_type && exit 1

	[[ -z $total ]] && echo function $0 needs total && exit 1
	[[ -z $nok ]] && echo function $0 needs nok && exit 1
	[[ -z $overall_total ]] && echo function $0 needs overall_total && exit 1

	if [[ ! $delay = 1w ]]; then
		if [[ $item_type = vhost ]]; then
			# TODO enable log-rotation or make this less of a dirty hack
			# assuming a vhost would show up only once in a single env
			ref_percent=`grep -E "^ $index 1w $item " /var/log/dam-spot-1w.log | tail -1 | \
				awk '{print $9}' | cut -f1 -d%`
		else
			# for both overall & IP
			# TODO check vhost even when dealing with per IP
			ref_percent=`grep -E "^ $index 1w overall " /var/log/dam-spot-1w.log | tail -1 | \
				awk '{print $9}' | cut -f1 -d%`
		fi

		# not knowing about a vhost can happen in case there's no 1w reference for it
		[[ -z $ref_percent ]] && echo -n " WARN: new $item_type $item? -- using overall ref_percent " && \
			ref_percent=`grep -E "^ $index 1w overall " /var/log/dam-spot-1w.log | tail -1 | \
                                awk '{print $9}' | cut -f1 -d%` \
			&& echo $ref_percent

		(( debug > 1 )) && echo debug: $item - ref_percent $ref_percent
		(( ref_percent >= 0 )) || bomb ref_percent $ref_percent not a number for $item_type $item?
	fi

	# overall_total total nok remain integers
	# ref_percent remains float

	# avoid integer division with 1. float
	typeset -F 2 percent
	(( percent = nok * 1. / total * 100 ))
	(( debug > 1 )) && echo "debug: $item - (( $percent = $nok * 1. / $total * 100 ))"

	# fib levels are only valuable against the weekly reference
	if [[ ! $delay = 1w ]]; then
		typeset -F 3 result_fib
		(( result_fib = percent / ref_percent ))
		(( debug > 1 )) && echo "debug: $item - (( $result_fib = $percent / $ref_percent ))"
	else
		typeset -F 3 result_fib
		result_fib=1.000
	fi

	if [[ item_type = overall ]]; then
		item_ratio=100
	else
		typeset -F2 item_ratio
		(( item_ratio = total * 100.00 / overall_total ))
		(( debug > 1 )) && echo "debug: (( $item_ratio = $total * 100 / $overall_total ))"
	fi

	# $ref_percent $overall_fib
	if [[ ! $delay = 1w ]]; then
		text="$index $delay $item ($item_ratio%) - nok http status $percent% out of $total entries as fib $result_fib compared to $ref_percent%"
	else
		text="$index $delay $item ($item_ratio%) - nok http status $percent% out of $total entries"
	fi

	echo \ $text

	if [[ $item_type = vhost && $result_fib -ge $overall_fib ]]; then
		send_alarm "$text"
	elif [[ $item_type = ip && $result_fib -gt 1.000 ]]; then
		hits_per_second

		(( debug > 1 )) && echo debug: $item - hits $hits

		typeset -F 2 score
		(( score = hits * percent * result_fib ))

		(( debug > 1 )) && echo "debug: $item - (( $score = $hits * $percent * $result_fib ))"

		# we do not take item_ratio into consideration for scoring
		# what ever the load an attacker produces can be hidden by heavy-duty upstream
		# however we report on abnormal IP ratio thereafter
		if (( score > score_trigger )); then
			ptr=`host $item | awk '{print $NF}'`

			send_alarm "$text
$hits hits per second / score $score / \`$ptr\`"

			unset ptr
		else
			echo \ $index $delay info: score $score below score_trigger $score_trigger
		fi

	fi

	if [[ $item_type = ip ]]; then
		(( hits >= 1.00 )) && echo \ $index $delay WARN: $hits hits per second reached 1.00
		#(( item_ratio > 0.20 )) && echo \ $index $delay WARN: item_ratio $item_ratio is above 20%
	fi

	return 0
}

function send_alarm {
	[[ -z $index ]]	&& bomb function $0 needs index
	[[ -z $item ]]	&& bomb function $0 needs item
	[[ -z $delay ]]	&& bomb function $0 needs delay

	# here we keep reporting in the logs, only the alarm gets throttled
	day=`date +%Y-%m-%d`
	alert=$index-$delay-$item
	lock=/var/lock/$alert.$day.lock
	#(( debug > 0 )) && echo debug: lock $lock
	echo DEBUG lock is $lock

	# exit function, not program
	[[ -f $lock ]] && echo \ $index $delay info: $alert - there is a lock already for today \($lock\) && return

	text="$1
(throttle for today $day)"

	(( debug > 0 )) && echo " ALARM"

	if (( debug < 1 )); then
		echo -n \ sending webhook to slack ...
		curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook && echo
		touch $lock
	fi

	unset day alert lock
}

LC_NUMERIC=C

echo `date --rfc-email` - $index - $delay

#
# overall
#

# this variable we need thereafter
overall_total=`/data/dam/bin/count.bash $index "$query_total" $delay`

(( debug > 1 )) && echo "debug: overall_total $overall_total"

item=overall
count_overall && attack_score overall
unset item total nok

#
# per vhost
#

# we want all unique field values - terms is appropriate
## assuming less than 100 vhosts
# grab 10 most active vhosts
# field type STRING ==> keyword
vhosts=`cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
        -d @- | jq -r ".aggregations.terms_$vhost_field.buckets[].key"
{
    "size": 0,
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query_total"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "terms_$vhost_field": {
            "terms": {
                "field": "$vhost_field.keyword",
		"size": 10,
                "order": [
                    {
                        "_count": "desc"
                    }
                ]
            }
        }
    }
}
EOF`

(( debug > 0 )) && echo debug: active vhosts are $vhosts

for vhost in $vhosts; do
	typeset -n item=vhost

	# count_per_vhost globally defines total nok
	# first function may skip second function with exit code
	count_per_vhost && attack_score vhost

	unset item total nok
done; unset vhost

# no need to proceed further for the reference time-frame
[[ $delay = 1w ]] && echo && exit 0

#
# per client
#

# same here, unique field values
## assuming less than 1,000 IPs (time-frame short enough)
# grab only 10 most active IPs
# field type IP ==> no keyword
# HOTFIX
if [[ -n `echo $index | grep cloudflare` ]]; then
	fix=$remote_addr_field.keyword
else
	fix=$remote_addr_field
fi

ips=`cat <<EOF | tee /var/tmp/debug.json | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
        -d @- | tee /var/tmp/debug-results.json | jq -r ".aggregations.\"terms_$remote_addr_field\".buckets[].key"
{
    "size": 0,
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query_total"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "terms_$remote_addr_field": {
            "terms": {
		"size": 10,
                "field": "$fix",
                "order": [
                    {
                        "_count": "desc"
                    }
                ]
            }
        }
    }
}
EOF`
                #"field": "$remote_addr_field",
# HOTFIX
unset fix

(( debug > 0 )) && echo debug: active ips are $ips

for ip in $ips; do
	typeset -n item=ip

	# count_per_ip globally defines total nok
        # first function may skip second function with exit code
        count_per_ip && attack_score ip

	unset item total nok
done; unset ip

echo

