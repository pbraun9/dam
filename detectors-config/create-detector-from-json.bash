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

detector=`jq -r '.name' < $json_file`
result_index=`jq -r '.result_index' < $json_file`

[[ -z $detector ]] && echo could not find .name in $json_file && exit 1
[[ -z $result_index ]] && echo could not find .result_index in $json_file && exit 1

# we simply use shared 'anomalies' suffix for all detections
#[[ ! $detector = ${result_index#opensearch-ad-plugin-result-} ]] && \
#	echo -e warn: detector name and result_index suffix are not the same \\n

echo $detector detector basic config check
curl -sk -X POST -H "Content-Type: application/json" "$endpoint/_plugins/_anomaly_detection/detectors/_validate" \
	-u $user:$passwd -d@$json_file
echo

echo $detector detector model training check
curl -sk -X POST -H "Content-Type: application/json" "$endpoint/_plugins/_anomaly_detection/detectors/_validate/model" \
	-u $user:$passwd -d@$json_file
echo

echo anomalies will be stored in $result_index
echo

echo ready?
read -r

echo creating detector $detector
curl -sk -X POST -H "Content-Type: application/json" "$endpoint/_plugins/_anomaly_detection/detectors?pretty" \
        -u $user:$passwd -d@$json_file
echo

