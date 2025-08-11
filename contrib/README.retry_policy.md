# fix failed managed policies

prepare the list of failed index policies

    mv -i index_policies index_policies.`date +%s`
    time ./wrapper-datastreams-ism-explain-action.bash > index_policies

<!--
just in case

	grep 'retry failed:true' failed_policies
-->

check which indices went wrong as for rollovers

	grep failed:true index_policies | grep rollover
	grep failed:true index_policies | grep read_only
	grep failed:true index_policies | grep -vE 'rollover|read_only'

	indices=`grep failed:true index_policies | grep rollover | awk '{print $1}'`
	indices=`grep failed:true index_policies | grep read_only | awk '{print $1}'`

	for index in $indices; do
		echo $index
		./ism-retry-failed-index.bash $index
		sleep 1
	done; unset index

