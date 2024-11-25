#!/bin/bash
set -e

[[ ! -r /etc/dam/dam.conf ]] && echo cannot read /etc/dam/dam.conf && exit 1

# load credentials and endpoint
source /etc/dam/dam.conf

[[ -z $endpoint ]]	&& echo need endpoint && exit 1
[[ -z $user ]]		&& echo need user && exit 1
[[ -z $passwd ]]	&& echo need passwd && exit 1

[[ -z $1 ]] && echo json file? && exit 1
json_file=$1

[[ ! -r $json_file ]] && echo cannot read $json_file && exit 1

function send_request {
	[[ -z $1 ]] && echo function $0 needs api && exit 1
	api=$1

	curl -sk -X POST -H "Content-Type: application/json" "$api" -u $user:$passwd -d@$json_file
}

echo

detector=`jq -r '.name' < $json_file`
result_index=`jq -r '.result_index' < $json_file`

[[ -z $detector ]] && echo could not find .name in $json_file && exit 1
[[ -z $result_index ]] && echo could not find .result_index in $json_file && exit 1

# we simply use shared 'anomalies' suffix for all detections
#[[ ! $detector = ${result_index#opensearch-ad-plugin-result-} ]] && \
#	echo -e warn: detector name and result_index suffix are not the same \\n

echo $detector detector basic config check
send_request "$endpoint/_plugins/_anomaly_detection/detectors/_validate?pretty"
echo

echo $detector detector model training check
send_request "$endpoint/_plugins/_anomaly_detection/detectors/_validate/model?pretty"
echo

echo anomalies will be stored in $result_index
echo

echo all good?  ready to go? \(press enter or Ctrl-C\)
read -r

echo creating detector $detector
send_request "$endpoint/_plugins/_anomaly_detection/detectors?pretty"
echo

