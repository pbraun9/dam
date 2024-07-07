#!/bin/ksh
set -e

dummy=0

# according to cron job + 1 minute as the wrapper proceeds with detectors one after another
# no throttling required
delay_minutes=11

# override to 1H for testing
#delay_minutes=60

# override to 10H for testing
#delay_minutes=600

# override to 100H for testing
#delay_minutes=6000

#
# query both default index and custom result index and send detailed alert
#
# no lock required here
#

[[ -z $3 ]] && echo -e \\n usage: ${0##*/} detector-name detector-id custom_index \\n && exit 1
detector=$1
id=$2
custom_index=$3

[[ ! -r /data/dam/lib/send_webhook_sev.ksh ]] && echo cannot read /data/dam/lib/send_webhook_sev.ksh && exit 1
source /data/dam/lib/send_webhook_sev.ksh

# load credentials and endpoint
source /etc/dam/dam.conf

# load url sev grade_trigger
[[ ! -r /etc/dam/detectors/$detector.conf ]] && echo error: cannot read /etc/dam/detectors/$detector.conf && exit 1
source /etc/dam/detectors/$detector.conf

[[ -z $url ]]		&& echo error: url not defined in /etc/dam/detectors/$detector.conf && exit 1
[[ -z $sev ]]		&& echo error: sev not defined in /etc/dam/detectors/$detector.conf && exit 1
[[ -z $grade_trigger ]]	&& echo error: grade_trigger not defined in /etc/dam/detectors/$detector.conf && exit 1

function parse_anomaly {
	[[ -z $i ]] && echo function $0 requires \$i && exit 1

	# hit 1 becomes hits[0]
	(( i-- ))

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

	if (( expected == 0.00 )); then
		echo warn: could not parse expected value
		typeset -u expected=none
	fi

	start_time=`echo $results | jq -r ".hits.hits[$i]._source.data_start_time" | sed -r 's/[[:digit:]]{3}$//'`
	end_time=`echo $results | jq -r ".hits.hits[$i]._source.data_end_time" | sed -r 's/[[:digit:]]{3}$//'`

	[[ -z $start_time ]]	&& echo error: could not parse start_time && exit 1
	[[ -z $end_time ]]	&& echo error: could not parse end_time && exit 1

	start_human_time=`date --rfc-email -d@$start_time`
	end_human_time=`date --rfc-email -d@$end_time`

	zulu_start=`date --utc --iso-8601=seconds -d@$start_time | sed -r 's/[+-]+[[:digit:]]{2}:[[:digit:]]{2}$//'`
	zulu_end=`date --utc --iso-8601=seconds -d@$end_time | sed -r 's/[+-]+[[:digit:]]{2}:[[:digit:]]{2}$//'`

	details=`/data/dam/detectors/detector-get.bash $id`

	descr=`echo $details | jq -r '.anomaly_detector.description'`
	index=`echo $details | jq -r '.anomaly_detector.indices[]'`
	aggs=`echo $details | jq -r '.anomaly_detector.feature_attributes[].aggregation_query.aggs0 | keys[]'`
	field=`echo $details | jq -r ".anomaly_detector.feature_attributes[].aggregation_query.aggs0.$aggs.field"`

	text="$detector ($descr) with grade $anomaly_grade

$index $aggs $field (expected $expected / feature $feature)
\`\`\`
data start  $start_human_time
data end    $end_human_time
\`\`\`
$url?_g=(time:(from:'$zulu_start.000Z',to:'$zulu_end.000Z'))"

	send_webhook_sev
}

# deal with max 10 anomalies found in given time-frame
results=`cat <<EOF | tee /tmp/dam.detectors.$detector.request.json | \
	curl -sk --fail -X POST -H "Content-Type: application/json" \
		"$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$custom_index?pretty" -u $user:$passwd -d@- | \
	tee /tmp/dam.detectors.$detector.result.json
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
              "from": "now-${delay_minutes}m/m",
              "to": "now"
            }
          }
        }
      ]
    }
  }
}
EOF`

(( $? > 0 )) && echo $detector - error: request exited abormally && exit 1

hits=`echo $results | jq -r '.hits.total.value'`

[[ $hits = null ]] && echo $detector - error: could not parse hits total value && exit 1

# exit here if there are not hits
(( hits == 0 )) && echo \ $detector - no hits && exit 0

# proceed with anomaly _source parsing
(( hits > 0 )) && echo \ $detector - $hits hits

for i in `seq 1 $hits`; do
	parse_anomaly
done; unset i

