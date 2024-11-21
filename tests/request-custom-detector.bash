#!/bin/bash
set -e

#debug=1

#index=opensearch-ad-plugin-result-anomalies

[[ -z $2 ]] && echo "usage: ${0##*/} <anomalies custom index> <json-file>" && exit 1
index=$1
file=$2

source /etc/dam/dam.conf

[[ ! -r $file ]] && echo cannot read file $file && exit 1

if (( debug > 0 )); then
	# warnings escapes are in there: \\
	cat <<EOF
	curl -fsSk -X POST -H "Content-Type: application/json" -u $user:$passwd \\
		"$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$index?pretty" \\
		-d @$file
EOF
else
	curl -fsSk -X POST -H "Content-Type: application/json" -u $user:$passwd \
		"$endpoint/_plugins/_anomaly_detection/detectors/results/_search/$index?pretty" \
		-d @$file
fi

(( $? > 0 )) && echo error: curl request failed && exit 1

