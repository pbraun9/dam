#!/bin/ksh
set -e

# 0|1|2
debug=0

#
# overall
# - count overall http codes 2xx
# - count overall http codes non-2xx
# - report on non-2xx precent above bad_percent
#
# per vhost & client
# - search for currently active item
# - count http codes 2xx per item
# - count http codes non-2xx per item
# - report on non-2xx precent above score_trigger
#

[[ -z $2 ]] && echo -e \\n \ usage: ${0##*/} conf.d/conf delay \\n && exit 1
conf=$1
delay=$2
frame=`echo $delay | sed -r 's/^[[:digit:]]+//'`

[[ ! -r /data/dam/damlib.ksh ]] && echo cannot read /data/dam/damlib.ksh && exit 1
[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1
[[ ! -r $conf ]] && echo cannot read $conf && exit 1
[[ ! -r /data/dam/lib/send_webhook_sev.bash ]] && echo cannot read /data/dam/lib/send_webhook_sev.bash && exit 1

source /etc/dam/dam.conf
source /data/dam/damlib.ksh
source $conf
source /data/dam/lib/send_webhook_sev.ksh

[[ -z $endpoint ]]	&& echo define endpoint in /etc/dam/dam.conf && exit 1
[[ -z $user ]]		&& echo define user in /etc/dam/dam.conf && exit 1
[[ -z $passwd ]]	&& echo define passwd in /etc/dam/dam.conf && exit 1
# webhook_$sev will be checked within send_webhook_sev function

[[ -z $index ]]		&& echo define index in $conf && exit 1
[[ -z $query_total ]]	&& echo define query_total in $conf && exit 1
[[ -z $query_nok ]]	&& echo define query_nok in $conf && exit 1
[[ -z $remote_addr_field ]] && echo define remote_addr_field in $conf && exit 1
[[ -z $vhost_field ]]	&& echo define vhost_field in $conf && exit 1
[[ -z $bad_percent ]]   && echo define bad_percent in $conf && exit 1
[[ -z $score_trigger ]]	&& echo define score_trigger in $conf && exit 1

# indirection / deference to define sev according to current time-frame
typeset -n sev="sev_$delay"
[[ -z $sev ]]		&& echo define sev_$delay in $conf && exit 1

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

        typeset -g total=`cat <<EOF | tee /tmp/dam.web-attackers.vhost.total.request.json | \
		curl -sk -X POST -H "Content-Type: application/json" "$endpoint/$index/_count?pretty" -u $user:$passwd -d @- | \
		tee /tmp/dam.web-attackers.vhost.total.result.json | jq -r .count
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

	typeset -g nok=`cat <<EOF | tee /tmp/dam.web-attackers.vhost.nok.request.json | \
		curl -sk -X POST -H "Content-Type: application/json" "$endpoint/$index/_count?pretty" -u $user:$passwd -d @- | \
		tee /tmp/dam.web-attackers.vhost.nok.result.json | jq -r .count
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

	typeset -g total=`cat <<EOF | tee /tmp/dam.web-attackers.ip.total.request.json | \
		curl -sk -X POST -H "Content-Type: application/json" "$endpoint/$index/_count?pretty" -u $user:$passwd -d @- | \
		tee /tmp/dam.web-attackers.ip.total.result.json | jq -r .count
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

	# overall_total total nok remain integers

	# avoid integer division with 1. float
	typeset -F 2 percent
	(( percent = nok * 1. / total * 100 ))
	(( debug > 1 )) && echo "debug: $item - (( $percent = $nok * 1. / $total * 100 ))"

	if [[ $item_type = overall ]]; then
		# although unnecessary, we should keep a number here to avoid getting rid of the % sign further below
		item_ratio=100
	else
		typeset -F2 item_ratio
		(( item_ratio = total * 100.00 / overall_total ))
		(( debug > 1 )) && echo "debug: (( $item_ratio = $total * 100 / $overall_total ))"
	fi

	text="$index $delay $item ($item_ratio% $item_type) - nok http status $percent% out of $total entries"

	echo \ $text

	if (( percent >= bad_percent )); then

	## no need to calculate hits per second as this is not necessarilly a single attacker
	# attempt to use hits per seconds for vhosts also -- log rejections for now
		if [[ $item_type = overall ]]; then

			send_alarm "$text"

		else

			hits_per_second

			(( debug > 1 )) && echo debug: $item - hits $hits

			typeset -F 2 score
			(( score = hits * percent ))

			(( debug > 1 )) && echo "debug: $item - (( $score = $hits * $percent ))"

			# we do not take item_ratio into consideration for scoring
			# what ever the load an attacker produces can be hidden by heavy-duty upstream
			# however we report on abnormal IP ratio thereafter
			if (( score >= score_trigger )) && [[ $item_type = ip ]]; then

				ptr=`host $item | awk '{print $NF}'`

				# there may be multiple entries for a PTR, hence the echo within the markdown code
				send_alarm "$text / $hits hits per second / score $score / \``echo $ptr`\`"

				unset ptr

			elif (( score >= score_trigger )) && [[ $item_type = vhost ]]; then

				send_alarm "$text / $hits hits per second / score $score"

			elif (( score < score_trigger )) && [[ $item_type = vhost ]]; then

				# not sure we should use hits per second for vhosts
				echo " info: score $score ($percent x $hits hits per second) below score_trigger $score_trigger"

			fi

		fi
	fi

	# bonus warning - may become yet another alert
	if [[ $item_type = ip ]]; then
		(( hits >= 100 )) && echo \ WARN PREVIEW: $hits hits per second reached 100
	fi

	return 0
}

# text= defined here so it can be passed to child function
function send_alarm {
	[[ -z $index ]]	&& echo function $0 needs index && exit 1
	[[ -z $item ]]	&& echo function $0 needs item && exit 1
	[[ -z $delay ]]	&& echo function $0 needs delay && exit 1

	# here we keep reporting in the logs, only the alarm gets throttled
	day=`date +%Y-%m-%d`
	alert=$index-$delay-$item
	lock=/var/lock/$alert.$day.lock

	# exit function, not program
	[[ -f $lock ]] && echo " info: there is a lock already for today ($lock)" && return

	text="$1 (throttle for today $day)"

	send_webhook_sev

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

# we want all unique field values - terms/keyword is appropriate
## assuming less than 100 vhosts
# grab 10 most active vhosts
vhosts=`cat <<EOF | tee /tmp/dam.web-attackers.vhosts.request.json | \
	curl -sk -X POST -H "Content-Type: application/json" "$endpoint/$index/_search?pretty" -u $user:$passwd -d @- | \
	tee /tmp/dam.web-attackers.vhosts.result.json | jq -r ".aggregations.terms_$vhost_field.buckets[].key"
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

#
# per client
#

# no need to proceed further for the 1w time-frame
[[ $delay = 1w ]] && echo && exit 0

# do not proceed with ip aggs for small time-frames, that's too noisy
if [[ $frame = m ]]; then
	minutes=`echo $delay | sed 's/m$//'`
	(( minutes < 60 )) && echo && exit 0
fi

# jq: error (at <stdin>:34): Cannot iterate over null (null)
# HOTFIX - sometimes the field we are targetting (as defined with remote_addr_field variable)
# is not yet of the right field type (ip).  workaround is to define "field_type" in the web-attackers config.
# field type IP ==> no keyword
# other field types (string) ==> keyword
if [[ $field_type = string ]]; then
	echo " warn: field_type is $field_type"
	fix=$remote_addr_field.keyword
else
	fix=$remote_addr_field
fi

# we want all unique field values - terms/ip is appropriate
## assuming less than 1,000 IPs (time-frame short enough)
# grab only 10 most active IPs
ips=`cat <<EOF | tee /tmp/dam.web-attackers.ips.request.json | \
	curl -sk -X POST -H "Content-Type: application/json" "$endpoint/$index/_search?pretty" -u $user:$passwd -d @- | \
	tee /tmp/dam.web-attackers.ips.results.json | jq -r ".aggregations.\"terms_$remote_addr_field\".buckets[].key"
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

