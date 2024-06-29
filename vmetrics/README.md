# dam - vmetrics

## setup

eventually install `sysstat` and then [parse its output](https://pub.nethence.com/monitoring/flb-vmetrics) with fluent-bit
-- that way you get all rates in percent which makes it easier for alerting.

    which sar

    ls -lF /etc/fluent-bit/flb_metrics.conf

    cp -R conf/vmetrics/ /etc/dam/

## enable

```
crontab -e

# Performance monitoring
   * * * * * /data/dam/vmetrics/wrapper.bash >> /var/log/dam-vmetrics.log 2>&1
```

## resources

https://github.com/VictoriaMetrics/VictoriaMetrics/wiki/url-examples

https://docs.victoriametrics.com/metricsql/

