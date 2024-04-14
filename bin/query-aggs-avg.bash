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

(( debug > 1 )) && echo index is $index
(( debug > 1 )) && echo query is $query
(( debug > 1 )) && echo delay is $delay
(( debug > 1 )) && echo field is $field

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 1 )) && echo frame is $frame

cat > /var/tmp/query-aggs-avg.json <<EOF
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
                            "to": "now"
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "${field}_avg": {
            "avg": {
                "field": "$field"
            }
        }
    }
}
EOF

curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
	-d @/var/tmp/query-aggs-avg.json

(( debug > 0 )) || rm -f /var/tmp/query-aggs-avg.json

