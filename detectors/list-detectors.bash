#!/bin/bash

# list all detectors with _plugins/_anomaly_detection/detectors
# then select only active ones with _plugins/_anomaly_detection/detectors/<detectorId>/_profile

# load credentials and endpoint
source /etc/dam/dam.conf

function list-detectors {
	# assuming no more than 1000 detectors
	cat <<EOF | tee /tmp/dam.list-detectors.request.json | \
	curl -fsSk "$endpoint/_plugins/_anomaly_detection/detectors/_search?pretty" \
		-u $user:$passwd -X POST -H "Content-Type: application/json" -d@- | \
		tee /tmp/dam.list-detectors.result.json
{
  "size": 1000,
  "query": {
    "wildcard": {
      "indices": {
        "value": "*"
      }
    }
  }
}
EOF
}

function detector-profile {
	[[ -z $detector_id ]] && echo \ error: function $0 requires detector_id && exit 1

	cat <<EOF | tee /tmp/dam.detector-profile-$detector_id.request.json | \
	curl -fsSk "$endpoint/_plugins/_anomaly_detection/detectors/$detector_id/_profile" \
		-u $user:$passwd | tee /tmp/dam.detector-profile-$detector_id.result.json
EOF
}

echo "# /tmp/dam.list-detectors.result.json"
echo "# /tmp/dam.detector-profile-*.result.json"
list=`list-detectors | jq -r '.hits.hits[] | ._source.name + "," + ._id + "," + ._source.result_index'`

echo "$list" | while read line; do
	detector_id=`echo $line | cut -f2 -d,`

	detector_state=`detector-profile | jq -r .state`
	#echo DEBUG $detector_id has state $detector_state
	[[ $detector_state = RUNNING ]] && echo $line
done

