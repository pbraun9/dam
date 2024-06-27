#!/bin/bash

echo `date --rfc-email` - $0

cd /data/dam/vmetrics/

./vmetrics-gauge.ksh /etc/dam/vmetrics/cpu.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/ram.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/disk-read.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/disk-write.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/tx-bytes.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/tx-pkts.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/rx-bytes.conf
./vmetrics-gauge.ksh /etc/dam/vmetrics/rx-pkts.conf

echo

