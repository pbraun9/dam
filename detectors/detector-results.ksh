#!/bin/ksh
set -e

custom_index=opensearch-ad-plugin-result-anomalies

# enable to show curl commands
debug=0

# enable to avoid sending alerts
dummy=0

#
# get details on a given detector using its id
# then query custom result index and send detailed alert
#

[[ -z $2 ]] && echo detector alert conf and id? && exit 1
conf=$1
detector_id=$2

[[ ! -r $conf ]] && echo error: cannot read conf: $conf && exit 1
[[ -z $detector_id ]] && echo error: missing detector_id as argument: $detector_id && exit 1

[[ ! -r /data/dam/lib/send_webhook_sev.ksh ]] && echo cannot read /data/dam/lib/send_webhook_sev.ksh && exit 1
source /data/dam/lib/send_webhook_sev.ksh

# load credentials and endpoint
source /etc/dam/dam.conf

function parse_anomaly {
	[[ -z $i ]] && echo function $0 requires \$i && exit 1

	typeset -F 2 anomaly_grade
	typeset -F 2 expected
	typeset -F 2 feature

	anomaly_grade=`echo $results | jq -r ".hits.hits[$i]._source.anomaly_grade"`
	expected=`echo $results | jq -r ".hits.hits[$i]._source.expected_values[].value_list[].data" 2>/dev/null` || true
	feature=`echo $results | jq -r ".hits.hits[$i]._source.feature_data[].data"`

	[[ -z $anomaly_grade ]]	&& echo error: could not parse anomaly_grade && exit 1
	[[ -z $expected ]]	&& echo error: could not parse expected value && exit 1
	[[ -z $feature ]]	&& echo error: could not parse feature value && exit 1

	#if (( expected == 0.00 )); then
	#	echo warn: could not parse expected value
	#	typeset -u expected=none
	#fi

	#(( expected == 0.00 && feature == 0.00 )) && echo DEBUG ALL GOOD && return

	# optional // jq: error (at <stdin>:1): Cannot iterate over null (null)
        category=`echo $results | jq -r ".hits.hits[$i]._source.entity[].value" 2>/dev/null` || true

	start_time=`echo $results | jq -r ".hits.hits[$i]._source.data_start_time" | sed -r 's/[[:digit:]]{3}$//'`
	end_time=`echo $results | jq -r ".hits.hits[$i]._source.data_end_time" | sed -r 's/[[:digit:]]{3}$//'`

	[[ -z $start_time ]]	&& echo error: could not parse start_time && exit 1
	[[ -z $end_time ]]	&& echo error: could not parse end_time && exit 1

	start_human_time=`date --rfc-email -d@$start_time`
	end_human_time=`date --rfc-email -d@$end_time`

	zulu_start=`date --utc --iso-8601=seconds -d@$start_time | sed -r 's/[+-]+[[:digit:]]{2}:[[:digit:]]{2}$//'`
	zulu_end=`date --utc --iso-8601=seconds -d@$end_time | sed -r 's/[+-]+[[:digit:]]{2}:[[:digit:]]{2}$//'`

	if [[ -n $category && -n $query ]]; then
		# todo eventually merge both with an AND
		echo warn: both category-from-results and query-from-conf are defined - using query
	elif [[ -n $category ]]; then
		# double-escape double-quotes around category name so it fits into text=
		query="${field%\.keyword}:\\\"$category\\\""
	fi

	text="anomaly on $detector with anomaly grade $anomaly_grade - ${field%\.keyword} $aggs (expected $expected / feature $feature)
\`\`\`
start  $start_human_time
end    $end_human_time
\`\`\`
[$detector $query]($url?_g=(time:(from:'$zulu_start.000Z',to:'$zulu_end.000Z'))&_a=(query:(language:lucene,query:'$query')))"

	# understands dummy lock
	# needs alert text sev
	alert=$detector
	send_webhook_sev
	unset alert
}

source $conf

[[ -z $url ]]           && echo define url in $conf && exit 1
[[ -z $grade_trigger ]] && echo define grade_trigger in $conf && exit 1
[[ -z $sev ]]           && echo define sev in $conf
# query is optional

details=`curl -fsSk "$endpoint/_plugins/_anomaly_detection/detectors/$detector_id?pretty" -u $user:$passwd`

detector=`echo $details | jq -r '.anomaly_detector.name'`
   index=`echo $details | jq -r '.anomaly_detector.indices[]'`
    aggs=`echo $details | jq -r '.anomaly_detector.feature_attributes[].aggregation_query.aggs0 | keys[]'`

[[ -z $index ]] && echo error: could not define detector && exit 1
[[ -z $index ]] && echo error: could not define index && exit 1
[[ -z $aggs ]]  && echo error: could not define aggs && exit 1

field=`echo $details | jq -r ".anomaly_detector.feature_attributes[].aggregation_query.aggs0.$aggs.field"`

[[ -z $field ]] && echo error: could not define field && exit 1

unset details

# todo lock per anomaly - just make sure an alert was sent for every recorded anomaly
# we can only define the lock after we found out about detector's name
hour=`date +%Y-%m-%d-%Hh`
lock=/var/lock/dam.detectors.$detector.$hour.lock
[[ -f $lock ]] && echo \ $detector - there is an hourly lock already \($lock\) && exit 0

# deal with max 10 anomalies found in a given time-frame
cat <<EOF > /tmp/dam.detectors.$detector.request.json
{
  "size": 10,
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "detector_id": "$detector_id"
          }
        },
        {
          "range": {
            "anomaly_grade": {
              "gte": $grade_trigger
            }
          }
        },
        {
          "range": {
            "approx_anomaly_start_time": {
              "from": "now-1h/h",
              "to": "now"
            }
          }
        }
      ]
    }
  }
}
EOF

if (( debug > 0 )); then
	# warning carriage return escapes are in there
	cat <<-EOF
	DEBUG
	curl -fsSk -X POST -H "Content-Type: application/json" -u $user:$passwd \\
	 "$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$custom_index?pretty" \\
	 -d@/tmp/dam.detectors.$detector.request.json
EOF
	exit 0
else
	results=`curl -fsSk -X POST -H "Content-Type: application/json" -u $user:$passwd \
	 "$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$custom_index?pretty" \
	 -d@/tmp/dam.detectors.$detector.request.json | tee /tmp/dam.detectors.$detector.result.json`

	# doesn't work when cmd within variable?
	#(( $? > 0 )) && echo $detector - error: request exited abormally && exit 1
fi

[[ -z $results ]] && echo $detector - error: results are empty && exit 1

hits=`echo $results | jq -r '.hits.total.value'`

[[ $hits = null ]] && echo $detector - error: could not parse hits total value && exit 1

# exit here if there are no hits
(( hits == 0 )) && echo \ $detector - no hits && exit 0

# proceed with anomaly _source parsing
echo \ $detector - $hits hit\(s\)

for i in `seq 0 $(( hits - 1 ))`; do
	parse_anomaly
done; unset i

