# elk alerts

# alerts setup

elk search query alerts

	cp -Ri conf/hits/ /etc/dam/

elk count query alerts

    cp -Ri conf/aggs/ /etc/dam/

elk search & count query alerts

    cp -Ri conf/query-aggs/ /etc/dam/

elk alive index alerts

    cp -Ri conf/alive/ /etc/dam/

## acceptance

	ls -lF /var/lock/*.lock

	cd alerts/

	./alert-hit.bash hits/suricata-src1024.conf
	#/data/dam/alert-hit-dql.bash ...
	#/data/dam/alert-count.bash ...
	./alert-alive.bash /data/dam/alive/suricata.conf

## wrapper setup

    cd alerts/
    cp -i wrapper.bash.sample wrapper.bash
    vi wrapper.bash

    ...

    cd ../

## enable

```
crontab -e

# Search query alerts
*/15 * * * * /data/dam/alerts/wrapper.bash >> /var/log/dam-alerts.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

