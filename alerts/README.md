# elk alerts

## requirements

- an elk cluster (elasticsearch or opensearch)
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source_name` and `destination_name`

## alerts setup

elk alive index alerts

    cp -R conf_samples/alert-alive/ /etc/dam/

elk count query alerts

    cp -R conf_samples/alert-aggs/ /etc/dam/

elk search query alerts

	cp -R conf_samples/alert-hits/ /etc/dam/

elk search and count query alerts

    cp -R conf_samples/alert-query-aggs/ /etc/dam/

## ready to go & acceptance

check the wrapper works accordingly

	ls -lF /var/lock/*.lock | grep `date +%Y-%m-%d`
    /data/dam/alerts/wrapper.bash

and enable

```
crontab -e

# Search query alerts
*/15 * * * * /data/dam/alerts/wrapper.bash >> /var/log/dam-alerts.log 2>&1

# Hot pages
   * * * * * /data/dam/alerts/wrapper-hot-pages.bash >> /var/log/dam-alerts-hot-pages.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

