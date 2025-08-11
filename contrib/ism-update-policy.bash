#!/bin/bash
set -e

[[ -z $2 ]] && echo policy json_file? && exit 1
policy=$1
json_file=$2

[[ ! -r $json_file ]] && echo cannot read json file $json_file && exit 1

source /etc/dam/dam.conf

seqno=`jq -r '._seq_no' < $json_file`
priterm=`jq -r '._primary_term' < $json_file`

echo
echo debug seqno is $seqno
echo debug priterm is $priterm
echo

cat <<EOF
curl -fsSk -X PUT -H "Content-Type: application/json" \
	"$endpoint/_plugins/_ism/policies/$policy?if_seq_no=$seqno&if_primary_term=$priterm" \
	-u $admin_user:$admin_passwd -d@$json_file
EOF

echo

