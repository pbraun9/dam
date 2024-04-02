#!/bin/bash

./detector-list.bash | grep -vE '^#|^$' | while read line; do
	detector=`echo $line | cut -f1 -d,`
	id=`echo $line | cut -f2 -d,`

	./detector-get.bash $detector $id

	unset detector id
done

