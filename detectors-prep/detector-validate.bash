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
[[ -z $interval ]] && echo could not define interval && exit 1
[[ -z $window_delay ]] && echo could not define window_delay && exit 1

function validate_detector {
	[[ -z $1 ]] && echo function validate_detector needs url && exit 1
	url=$1

	cat <<EOF | tee /tmp/dam.$detector.request.json | \
	curl -sk "$url" -u $user:$passwd \
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
      "interval": $interval,
      "unit": "Minutes"
    }
  },
  "window_delay": {
    "period": {
      "interval": $window_delay,
      "unit": "Seconds"
    }
  }
}
EOF
	unset url
}

echo $detector basic config check
validate_detector "$endpoint/_plugins/_anomaly_detection/detectors/_validate?pretty"
echo

echo $detector model training check
validate_detector "$endpoint/_plugins/_anomaly_detection/detectors/_validate/model?pretty"
echo

