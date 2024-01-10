#!/bin/bash

echo `date --rfc-email` - ${0##*/}

# simple hits
/data/dam/alert-hit.bash brutes-internal.conf
/data/dam/alert-hit.bash cf-kzn-waf.conf
/data/dam/alert-hit.bash cf-ru-waf.conf
/data/dam/alert-hit.bash peers-unknown-peer.conf
/data/dam/alert-hit.bash suricata-src1024.conf
/data/dam/alert-hit.bash suricata-tunnel-age.conf
/data/dam/alert-hit.bash suricata-tunnel-bytes.conf
/data/dam/alert-hit.bash suricata-tunnel-pkts.conf

# aggs count
/data/dam/alert-count.bash suricata-count-sigs.conf

# aggs query then count
/data/dam/alert-query-count.bash dev-ingress-auth-brute.conf

echo

