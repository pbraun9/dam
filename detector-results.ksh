#!/bin/ksh
set -e

dummy=0

debug=0

# according to cron job + 1 minute as a window delay
delay_minutes=6

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

function search_results {
	cat <<EOF | tee /data/dam/traces/detector-results-$detector.request.json | curl -sk \
		"$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$custom_index?pretty" \
		-u $user:$passwd \
		-X POST -H "Content-Type: application/json" -d@-
{
  "size": 1,
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
              "gt": 0
            }
          }
        },
        {
          "range": {
            "approx_anomaly_start_time": {
              "from": "now-${delay_minutes}m/m",
              "to": "now/m"
            }
          }
        }
      ]
    }
  }
}
EOF
}

function prep_alert {
	details=`/data/dam/contrib/detector-get.bash $detector $id`

	descr=`echo $details | jq -r '.anomaly_detector.description'`
	index=`echo $details | jq -r '.anomaly_detector.indices[]'`
	aggs_query=`echo $details | jq '.anomaly_detector.feature_attributes[].aggregation_query.aggs0'`

	cat <<EOF
$feature_name ($descr) - \`$index\`
anomaly detected (grade $anomaly_grade) at $human_time
expected value was $expected while feature value was $feature

\`\`\`
$aggs_query
\`\`\`
EOF
	unset details descr index
}

[[ -z $3 ]] && echo -e \\n usage: ${0##*/} detector-name detector-id custom_index \\n && exit 1
detector=$1
id=$2
custom_index=$3

[[ -z $detector ]] && echo need to define detector && exit 1
[[ -z $id ]] && echo need to define id && exit 1
[[ -z $custom_index ]] && echo need to define custom_index && exit 1

# load credentials and endpoint
source /data/dam/dam.conf

echo -n "$detector - "
results=`search_results`

echo "$results" > /data/dam/traces/detector-results-$detector.result.json

hits=`echo $results | jq -r '.hits.total.value'`

(( debug > 0 )) && echo hits - $hits

[[ $hits = null ]] && echo could not parse hits total value && exit 1

(( hits == 0 )) && echo no hits && exit 0

typeset -F 2 anomaly_grade
typeset -F 2 expected
typeset -F 2 feature

#detector_id=`echo $results | jq -r '.hits.hits[]._source.detector_id'`
approx_anomaly_start_time=`echo $results | jq -r '.hits.hits[0]._source.approx_anomaly_start_time'`
feature_name=`echo $results | jq -r '.hits.hits[0]._source.feature_data[].feature_name'`
anomaly_grade=`echo $results | jq -r '.hits.hits[0]._source.anomaly_grade'`
expected=`echo $results | jq -r '.hits.hits[0]._source.expected_values[].value_list[].data' 2>/dev/null` || true
feature=`echo $results | jq -r '.hits.hits[0]._source.feature_data[].data'`

approx_anomaly_start_time_no_millis=`echo $approx_anomaly_start_time | sed -r 's/[[:digit:]]{3}$//'`
human_time=`date --rfc-email -d@$approx_anomaly_start_time_no_millis`

[[ -z $approx_anomaly_start_time ]] && echo error: could not parse approx_anomaly_start_time && exit 1
[[ -z $feature_name ]] && echo error: could not parse feature_name && exit 1
[[ -z $anomaly_grade ]] && echo error: could not parse anomaly_grade && exit 1
[[ -z $expected ]] && echo error: could not parse expected value && exit 1
[[ -z $feature ]] && echo error: could not parse feature value && exit 1

if (( expected == 0.00 )); then
	echo warn: could not parse expected value
	typeset -u expected=none
fi

if (( debug > 0 )); then
	echo approx_anomaly_start_time - $approx_anomaly_start_time
	echo feature_name - $feature_name
	echo anomaly_grade - $anomaly_grade
	echo expected - $expected
	echo feature - $feature
	echo approx_anomaly_start_time_no_millis - $approx_anomaly_start_time_no_millis
	echo human_time - $human_time
fi

text=`prep_alert`

if (( dummy == 1 )); then
        echo the following would be sent to $webhook
        echo "$text"
else
        echo -n $alert - sending webhook to slack ...
        curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
        exit 1
fi

(( debug > 0 )) && echo all done

