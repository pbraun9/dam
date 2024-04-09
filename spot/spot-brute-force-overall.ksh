#!/bin/ksh

debug=0

#
# assuming conf full path
#

[[ -z $2 ]] && echo conf delay? && exit 1
conf=$1
delay=$2

[[ -z $conf ]] && echo need \$conf && exit 1
[[ -z $delay ]] && echo need \$delay && exit 1

[[ ! -r $conf ]] && echo cannot read $conf && exit 1
source $conf

[[ -z $index ]]		&& echo define index in $conf && exit 1
[[ -z $ref_delay ]]	&& echo define ref_delay in $conf && exit 1
[[ -z $ref_percent ]]	&& echo define ref_percent in $conf && exit 1
[[ -z $overall_fib ]]	&& echo define overall_fib in $conf && exit 1

[[ ! -r /data/dam/dam.conf ]] && echo cannot read /data/dam/dam.conf && exit 1
source /data/dam/dam.conf

[[ -z $webhook ]]	&& echo define webhook in /data/dam/dam.conf && exit 1

LC_NUMERIC=C

echo $index

typeset -F 4 ref_percent trigger overall_fib

# set trigger level above the reference
(( trigger = overall_fib * ref_percent ))

typeset -F 4 total nok percent

total=`/data/dam/bin/count.bash $index 'status:*' $delay`

nok=`/data/dam/bin/count.bash $index '!status:[200 TO 304]' $delay`

(( percent = nok / total * 100 ))

echo -e \ overall \\t\\t $percent vs. $trigger

text="$index overall - non-2xx http status $delay $percent% vs. $trigger% (ref $ref_delay $ref_percent% @$overall_fib)"

if (( percent >= trigger )); then
	echo "ALARM - $text"

        echo -n sending webhook to slack ...
        curl -sX POST -H 'Content-type: application/json' --data "{\"text\":\"$text\"}" $webhook; echo
        exit 1
fi

