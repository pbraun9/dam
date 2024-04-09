#!/bin/bash
set -e

debug=0

# 
# query-aggs-*
#
# aggs allows to perform operation against a specific aggregated field
# which should be either numeric or keyword
#
# query allows to either grab only affected entries (with field present)
# --or-- to refine the search to reduce aggregation scope
#

function usage {
	cat <<EOF

	${0##*/} index/stream lucene-query delay field [0|size]

	e.g.

	${0##*/} 'nginx-prod-*' '!remote_addr:\"10.0.0.0/8\"' 1d remote_addr
	${0##*/} 'nginx-prod-*' 'status:*' 1d status

EOF
	exit 1
}

[[ -z $4 ]] && usage
index=$1
query=$2
delay=$3
field=$4
size=$5

[[ -z $size ]] && size=3

source /data/dam/dam.conf

(( debug > 0 )) && echo index is $index
(( debug > 0 )) && echo query is $query
(( debug > 0 )) && echo delay is $delay
(( debug > 0 )) && echo field is $field
(( debug > 0 )) && echo size is $size

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 0 )) && echo frame is $frame

cat > /var/tmp/query-aggs-tmp.json <<EOF
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
                            "from": "now-$delay",
                            "to": "now/$frame"
                        }
                    }
                }
            ]
        }
    },
    "aggs": {
        "count": {
            "terms": {
                "field": "$field",
EOF

(( size != 0 )) && cat >> /var/tmp/query-aggs-tmp.json <<EOF
                "size": $size,
EOF

cat >> /var/tmp/query-aggs-tmp.json <<EOF
                "order": [
                    {
                        "_count": "desc"
                    }
                ]
            }
        }
    }
}
EOF

curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
	-d @/var/tmp/query-aggs-tmp.json

(( debug > 0 )) && echo cat /var/tmp/query-aggs-tmp.json || rm -f /var/tmp/query-aggs-tmp.json

