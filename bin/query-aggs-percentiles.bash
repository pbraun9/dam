#!/bin/bash
set -e

debug=1

function usage {
	cat <<EOF

	${0##*/} index/stream lucene-query delay field

EOF
	exit 1
}

[[ -z $4 ]] && usage
index=$1
query=$2
delay=$3
field=$4

source /data/dam/dam.conf

(( debug > 0 )) && echo index is $index
(( debug > 0 )) && echo query is $query
(( debug > 0 )) && echo delay is $delay
(( debug > 0 )) && echo field is $field

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 0 )) && echo frame is $frame

cat <<EOF | curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
	-d @-
{
    "size": 0,
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
                            "to": "now/$frame"
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "${field}_outliner": {
            "percentiles": {
                "field": "$field"
            }
        }
    }
}
EOF

