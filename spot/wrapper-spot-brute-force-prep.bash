#!/bin/bash

date --rfc-email
for conf in /data/dam/spot/conf.*/*.conf; do

	/data/dam/spot/spot-brute-force-prep.ksh $conf 1d
	/data/dam/spot/spot-brute-force-prep.ksh $conf 3d
	/data/dam/spot/spot-brute-force-prep.ksh $conf 1w

done; unset conf
echo

