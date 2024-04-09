#!/bin/bash

date --rfc-email >> /var/log/dam.daily.percent.log
for conf in /data/dam/spot/conf.d/*.conf; do

	/data/dam/spot/spot-brute-force-prep.ksh $conf 1d >> /var/log/dam.daily.percent.log
	/data/dam/spot/spot-brute-force-prep.ksh $conf 3d >> /var/log/dam.daily.percent.log
	/data/dam/spot/spot-brute-force-prep.ksh $conf 1w >> /var/log/dam.daily.percent.log

done; unset conf
echo >> /var/log/dam.daily.percent.log

