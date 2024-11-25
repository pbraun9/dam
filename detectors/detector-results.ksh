#!/bin/ksh
set -e

# show curl command
#debug=1

# do not send alerts
#dummy=1

#
# query both default index and custom result index and send detailed alert
#

[[ -z $3 ]] && echo -e \\n usage: ${0##*/} detector-name detector-id custom-index \\n && exit 1
detector=$1
id=$2
custom_index=$3

[[ ! -r /data/dam/lib/send_webhook_sev.ksh ]] && echo cannot read /data/dam/lib/send_webhook_sev.ksh && exit 1
source /data/dam/lib/send_webhook_sev.ksh

# load credentials and endpoint
source /etc/dam/dam.conf

function parse_anomaly {
	[[ -z $i ]] && echo function $0 requires \$i && exit 1

	# we already have id
	#detector_id=`echo $results | jq -r '.hits.hits[]._source.detector_id'`

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

	details=`/data/dam/detectors/detector-get.bash $id | tee /tmp/dam.detector.$id.details.results.json`

	echo $details | jq -r '.anomaly_detector.description' > /tmp/dam.detectors.$detector.conf

	# double-quotes are encoded as HTML hence we cannot simply use variables in there and source it from here
	          url=`grep ^url /tmp/dam.detectors.$detector.conf | sed 's/^url //'`
	grade_trigger=`grep ^grade_trigger /tmp/dam.detectors.$detector.conf | sed 's/^grade_trigger //'`
	          sev=`grep ^sev /tmp/dam.detectors.$detector.conf | sed 's/^sev //'`
	        query=`grep ^query /tmp/dam.detectors.$detector.conf | sed 's/^query //'` || true # optional
	 enable_alert=`grep ^enable_alert /tmp/dam.detectors.$detector.conf | sed 's/^enable_alert //'`


	[[ -z $url ]]		&& echo warn: url not defined in /etc/dam/detectors/$detector.conf && exit 0
	[[ -z $grade_trigger ]]	&& echo warn: grade_trigger not defined in /etc/dam/detectors/$detector.conf && exit 0
	[[ -z $sev ]]		&& echo warn: sev not defined in /etc/dam/detectors/$detector.conf && exit 0
	# $query is optional
	# enable_alert is optional

	[[ $enable_alert = false ]] && echo \ warn: alert for detector $detector is disabled && exit 0

	index=`echo $details | jq -r '.anomaly_detector.indices[]'`
	aggs=`echo $details | jq -r '.anomaly_detector.feature_attributes[].aggregation_query.aggs0 | keys[]'`
	field=`echo $details | jq -r ".anomaly_detector.feature_attributes[].aggregation_query.aggs0.$aggs.field"`

	[[ -n $category && -n $query ]] && echo detector - error: both category and query are defined && exit 1
	# double-escape double-quotes around category name so it fits into text=
	[[ -n $category ]] && query="${field%\.keyword}:\\\"$category\\\""

	text="anomaly on $detector with anomaly grade $anomaly_grade - ${field%\.keyword} $aggs (expected $expected / feature $feature)
\`\`\`
start  $start_human_time
end    $end_human_time
\`\`\`
[$detector $query]($url?_g=(time:(from:'$zulu_start.000Z',to:'$zulu_end.000Z'))&_a=(query:(language:lucene,query:'$query')))
throttle for today ($day)"


	# understands dummy lock
	# needs alert text sev
	alert=$detector
	send_webhook_sev

	unset url grade_trigger sev query alert
}

day=`date +%Y-%m-%d`
lock=/var/lock/dam.detectors.$detector.$day.lock

[[ -f $lock ]] && echo \ $detector - there is a lock already for today \($lock\) && exit 0

# load url grade_trigger sev

[[ ! -r /etc/dam/detectors/$detector.conf ]] && echo error: cannot read /etc/dam/detectors/$detector.conf && exit 1
source /etc/dam/detectors/$detector.conf


# deal with max 10 anomalies found in given time-frame
cat <<EOF > /tmp/dam.detectors.$detector.request.json
{
  "size": 10,
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "detector_id": "$id"
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
              "from": "now-1d/d",
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

	# warning escapes are in there \\
	cat <<EOF
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

# exit here if there are not hits
(( hits == 0 )) && echo \ $detector - no hits && exit 0

# proceed with anomaly _source parsing
echo \ $detector - $hits hit\(s\)

for i in `seq 0 $(( hits - 1 ))`; do
	parse_anomaly
done; unset i

