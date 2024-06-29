#!/bin/bash
set -e

source /etc/dam/dam.conf

query="avg_over_time(log_metric_gauge_cpu_p[5m])"

curl -s "$vmetrics_endpoint" -d "query=$query" | jq

