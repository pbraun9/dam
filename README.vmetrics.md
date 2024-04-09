# dam - vmetrics

## setup

	cd vmetrics-gauge/
	cp -pi ... ...
	vi ...
	cd ../

	cp -pi wrapper-vmetrics.bash.sample wrapper-vmetrics.bash
	vi wrapper-vmetrics.bash

## enable

```
crontab -e

# Performance monitoring
   * * * * * /data/dam/wrapper-vmetrics.bash >> /var/log/dam-vmetrics.log 2>&1
```

## resources

https://github.com/VictoriaMetrics/VictoriaMetrics/wiki/url-examples

https://docs.victoriametrics.com/metricsql/

