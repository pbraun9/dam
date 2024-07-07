#!/bin/bash

# TODO show only enabled detectors (there's no difference between enabled and disabled detectors in the output)

# load credentials and endpoint
source /etc/dam/dam.conf

function list-detectors {
	# assuming no more than 1000 detectors
	cat <<EOF | tee /tmp/dam.list-detectors.request.json | \
	curl -sk "$endpoint/_plugins/_anomaly_detection/detectors/_search?pretty" -u $user:$passwd \
	-X POST -H "Content-Type: application/json" -d@-
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

echo "# full output /tmp/dam.list-detectors.result.json"
list-detectors | tee /tmp/dam.list-detectors.result.json | \
	jq -r '.hits.hits[] | ._source.name + "," + ._id + "," + ._source.result_index'

