#!/bin/bash

echo `date --rfc-email` - ${0##*/}

/data/dam/alert-hit.bash suricata-src1024.conf

/data/dam/alert-count.bash suricata-count-sigs.conf

echo

