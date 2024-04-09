#!/bin/ksh

#
# this script checks average amout of 2* vs. non-2* http status code as a reference
# it produces a percentage to be used by spot-brute-force script
#

[[ -z $2 ]] && echo conf delay? && exit 1
conf=$1
delay=$2

source $conf

LC_NUMERIC=C

typeset -F 4 total nok nok_percent

total=`/data/dam/bin/count.bash $index 'status:* AND !remote_addr:\"10.0.0.0/8\"' $delay`
#echo -n "total count is "
#printf "%'d" $total
#echo

nok=`/data/dam/bin/count.bash $index 'status:* AND !status:[200 TO 304] AND !remote_addr:\"10.0.0.0/8\"' $delay`
#echo -n "nok count is "
#printf "%'d" $nok
#echo

(( nok_percent = nok / total * 100 ))

echo -e \ $index \\t percentage of NOK status for last $delay is $nok_percent%

