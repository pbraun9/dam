#!/bin/bash
set -e

# load credentials and endpoint
source /etc/dam/dam.conf

function create-detector {
	cat <<EOF | tee /tmp/dam.$detector.request.json | \
	curl -sk "$endpoint/_plugins/_anomaly_detection/detectors" \
	-u $user:$passwd \
	-X POST -H "Content-Type: application/json" -d@-
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
      "interval": 5,
      "unit": "Minutes"
    }
  },
  "window_delay": {
    "period": {
      "interval": 1,
      "unit": "Seconds"
    }
  },
  "result_index" : "opensearch-ad-plugin-result-$suffix"
}
EOF
}

[[ -z $1 ]] && echo detectors/config_file? && exit 1
config_file=$1

source $config_file

[[ -z $detector ]] && echo could not define detector && exit 1
[[ -z $descr ]]    && echo could not define descr && exit 1
[[ -z $index ]]    && echo could not define index && exit 1
[[ -z $aggs ]]     && echo could not define aggs && exit 1
[[ -z $field ]]    && echo could not define field && exit 1
[[ -z $suffix ]]   && echo could not define suffix && exit 1

echo
echo CREATE DETECTOR FROM CONFIG $config_file
echo results will be stored in index opensearch-ad-plugin-result-$suffix
echo

echo create $detector
create-detector "$endpoint/_plugins/_anomaly_detection/detectors?pretty"
echo
echo

