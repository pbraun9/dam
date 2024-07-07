#!/bin/bash

echo `date --rfc-email` - $0

/data/dam/detectors/list-detectors.bash | grep -vE '^#|^$' | while read line; do
	detector=`echo $line | cut -f1 -d,`
	id=`echo $line | cut -f2 -d,`
	custom_index=`echo $line | cut -f3 -d,`

	/data/dam/detectors/detector-results.ksh $detector $id $custom_index

	unset detector id custom_index
done

echo

