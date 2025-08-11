#!/bin/bash

# parse datastream list with a given index pattern (without *)
# we assume pattern from the start of the line
# e.g. test- will search ^test-
# and apply policy to those

[[ -z $2 ]] && echo policy pattern-wo-wildcard? && exit 1
policy=$1
pattern=$2

#echo -n writing list-index-leafs ...
#./show-data-streams-leaf-policy.bash > list-index-leafs && echo done

#echo -n writing list-datastreams ...
#[[ ! -f list-datastreams ]] && ./show-data-streams.bash > list-datastreams

#for index in `grep $pattern list-index-leafs | grep null | awk '{print $1}'`; do
for index in `grep ^$pattern list-datastreams | awk '{print $1}'`; do
	./ism-policy-add.bash $policy $index
	sleep 1
done; unset index

