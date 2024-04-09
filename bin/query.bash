#!/bin/bash
set -e

debug=0

function usage {
	cat <<EOF

	${0##*/} index/stream lucene-query delay

EOF
	exit 1
}

[[ -z $3 ]] && usage
index=$1
query=$2
delay=$3

source /data/dam/dam.conf

(( debug > 0 )) && echo index is $index
(( debug > 0 )) && echo query is $query
(( debug > 0 )) && echo delay is $delay

frame=${delay##*/}
frame=`echo $frame | sed -r 's/^[[:digit:]]+//'`

(( debug > 0 )) && echo frame is $frame

    #"size": 0,
cat > /var/tmp/query-tmp.json <<EOF
{
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
    }
}
EOF

curl -sk -X POST -H "Content-Type: application/json" \
        "$endpoint/$index/_search?pretty" -u $user:$passwd \
	-d @/var/tmp/query-tmp.json

(( debug > 0 )) && echo cat /var/tmp/query-tmp.json || rm -f /var/tmp/query-tmp.json

