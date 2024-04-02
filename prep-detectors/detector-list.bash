#!/bin/bash

# load credentials and endpoint
source /data/dam/dam.conf

function list-detectors {
	cat <<EOF | tee /data/dam/traces/detector-list.request.json | \
	curl -sk "$endpoint/_plugins/_anomaly_detection/detectors/_search?pretty" -u $user:$passwd \
	-X POST -H "Content-Type: application/json" -d@-
{
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

echo "# full output /data/dam/traces/detector-list.result.json"
list-detectors | tee /data/dam/traces/detector-list.result.json | \
	jq -r '.hits.hits[] | ._source.name + "," + ._id + "," + ._source.result_index'

