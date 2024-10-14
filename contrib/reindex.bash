#!/bin/bash

[[ -z $2 ]] && echo data-stream start end && exit 1
ds=$1
start=$2
end=$3

request=/tmp/dam.contrib.reindex.request.json
result=/tmp/dam.contrib.reindex.result.json

source /etc/dam/dam.conf

function send_admin_request {
        [[ -z $1 ]] && echo function $0 needs api && exit 1
        api=$1

        #curl -fsSk -X POST -H "Content-Type: application/json" "$api" -u $admin_user:$admin_passwd -d@-
        curl -fsSk -X POST -H "Content-Type: application/json" "$api" -u $user:$passwd -d@-
}

function send_delete_request {
        [[ -z $1 ]] && echo function $0 needs api && exit 1
        api=$1

        curl -fsSk -X DELETE "$api" -u $admin_user:$admin_passwd
	echo
}

echo -n writing $request\ 
cat > $request <<EOF
{
  "conflicts": "proceed",
  "source": {
    "index": [
EOF

for i in `seq -w $start $end`; do
	if [[ $i = $end ]]; then
		echo \".ds-$ds-000$i\" >> $request && echo -n .
	else
		echo \".ds-$ds-000$i\", >> $request && echo -n .
	fi
done; unset i

cat >> $request <<EOF && echo \ done
    ]
  },
  "dest": {
    "index": "$ds",
    "op_type": "create"
  }
}
EOF

echo writing $result
# slices=auto
cat $request | send_admin_request "$endpoint/_reindex?pretty&refresh" | tee $result && echo done
echo

echo task done?  ready to delete indices?
read -r

for i in `seq -w $start $end`; do
	echo deleting .ds-$ds-000$i
        send_delete_request "$endpoint/.ds-$ds-000$i"
done; unset i
echo

