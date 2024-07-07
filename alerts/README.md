# elk alerts

## requirements

- an elk cluster (elasticsearch or opensearch)
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source.geo.name` and `destination.geo.name`

## alerts setup

elk alive index alerts

    cp -Ri conf/alert-alive/ /etc/dam/

elk count query alerts

    cp -Ri conf/alert-aggs/ /etc/dam/

elk search query alerts

	cp -Ri conf/alert-hits/ /etc/dam/

elk search and count query alerts

    cp -Ri conf/alert-query-aggs/ /etc/dam/

## acceptance

	ls -lF /var/lock/*.lock

	cd alerts/

	./alert-alive.bash /etc/dam/alert-alive/suricata.conf
	./alert-count.bash /etc/dam/alert-aggs/suricata-count-sigs.conf
	./alert-hit.bash /etc/dam/alert-hits/brutes-internal.conf
    ./alert-query-count.bash /etc/dam/alert-query-aggs/ingress-dev-access-auth.conf

## ready to go

check the wrapper works accordingly

    ./wrapper.bash

and enable

```
crontab -e

# Search query alerts
*/15 * * * * /data/dam/alerts/wrapper.bash >> /var/log/dam-alerts.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

