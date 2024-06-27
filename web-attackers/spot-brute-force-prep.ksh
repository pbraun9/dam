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

# total remains an integer
typeset -F 4 nok nok_percent

total=`/data/dam/bin/count.bash $index "$query_total" $delay`
#echo -n "total count is "
#printf "%'d" $total
#echo

nok=`/data/dam/bin/count.bash $index "$query_nok" $delay`
#echo -n "nok count is "
#printf "%'d" $nok
#echo

(( nok_percent = nok / total * 100 ))

echo -e \ $index $delay \\t NOK status is $nok_percent% out of $total entries

