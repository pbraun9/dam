#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_tasks?pretty" -u $user:$passwd | \
	jq -r '.nodes | to_entries[] | .value.tasks | to_entries[] | .value.action'

