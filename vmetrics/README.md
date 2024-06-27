# dam - vmetrics

## setup

    cp -R conf/vmetrics/ /etc/dam/

	vi vmetrics/wrapper.bash

## enable

```
crontab -e

# Performance monitoring
   * * * * * /data/dam/vmetrics/wrapper.bash >> /var/log/dam-vmetrics.log 2>&1
```

## resources

https://github.com/VictoriaMetrics/VictoriaMetrics/wiki/url-examples

https://docs.victoriametrics.com/metricsql/

