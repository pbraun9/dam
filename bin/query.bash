#!/bin/bash
set -e

# 0|1|2
debug=1

function usage {
	cat <<EOF

	${0##*/} index/stream lucene-query delay [size]

EOF
	exit 1
}

[[ -z $3 ]] && usage
index=$1
query=$2
delay=$3
size=$4

source /etc/dam/dam.conf

(( debug > 1 )) && echo index is $index
(( debug > 1 )) && echo query is $query
(( debug > 1 )) && echo delay is $delay

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 1 )) && echo frame is $frame

debugfile=/var/tmp/query.json

cat > $debugfile <<EOF
{
EOF

[[ -n $size ]] && cat >> $debugfile <<EOF
    "size": $size,
EOF

cat >> $debugfile <<EOF
    "query": {
        "bool": {
            "filter": [
                {
                    "query_string": {
                        "query": "$query"
                    }
                },
                {
                    "range": {
                        "@timestamp": {
                            "from": "now-$delay/$frame",
                            "to": "now"
                        }
                    }
                }
            ]
        }
    }
}
EOF

curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
	-d @$debugfile

(( debug > 0 )) || rm -f $debugfile

