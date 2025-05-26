#!/bin/bash
set -e

# load credentials and endpoint
source /etc/dam/dam.conf

[[ -z $1 ]] && echo detectors/config_file? && exit 1
config_file=$1

source $config_file

[[ -z $detector ]] && echo could not define detector && exit 1
[[ -z $descr ]]    && echo could not define descr && exit 1
[[ -z $index ]]    && echo could not define index && exit 1
[[ -z $aggs ]]     && echo could not define aggs && exit 1
[[ -z $field ]]    && echo could not define field && exit 1
[[ -z $suffix ]]   && echo could not define suffix && exit 1
[[ -z $interval ]] && echo could not define interval && exit 1
[[ -z $window_delay ]] && echo could not define window_delay && exit 1

function create-detector {
	echo debug: /tmp/dam.detectors-prep.create.request.json
	echo calling _plugins/_anomaly_detection/detectors ...
	cat <<EOF | tee /tmp/dam.detectors-prep.create.request.json | \
		curl -sk --fail -X POST -H "Content-Type: application/json" \
			"$endpoint/_plugins/_anomaly_detection/detectors?pretty" \
			-u $user:$passwd -d@- && echo done
{
  "name": "$detector",
  "description": "$descr",
  "time_field": "@timestamp",
  "indices": [
    "$index"
  ],
  "feature_attributes": [
    {
      "feature_name": "$detector",
      "feature_enabled": true,
      "aggregation_query": {
        "aggs0": {
          "$aggs": {
            "field": "$field"
          }
        }
      }
    }
  ],
  "detection_interval": {
    "period": {
      "interval": $interval,
      "unit": "Minutes"
    }
  },
  "window_delay": {
    "period": {
      "interval": $window_delay,
      "unit": "Minutes"
    }
  },
  "result_index" : "opensearch-ad-plugin-result-$suffix"
}
EOF
}

echo
echo CREATE DETECTOR FROM CONFIG $config_file
echo results will be stored in index opensearch-ad-plugin-result-$suffix
echo

create-detector
echo

