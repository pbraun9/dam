# setting up anomaly detectors

## requirements

you need some anomaly detectors in place
-- eventually create those [through the api](../detectors-prep/README.md)

    cd /data/dam/detectors/
	./list-detectors.bash

## setup

place the conf files accoriding to detector names e.g. start with those samples

    cp -R ../conf_samples/detectors/ /etc/dam/
    ls -lF /etc/dam/detectors/

make sure the aggs time-frame corresponds to the cron-job further below (+ 1 minute)

    cd /data/dam/detectors/
	vi detector-results.bash

	delay_minutes=11

## ready to go & acceptance

check that the wrapper works fine

    ls -lF /var/lock/*.lock | grep `date +%Y-%m-%d`
	/data/dam/detectors/wrapper.bash

and enable

```
crontab -e

# Anomaly detection
*/10 * * * * /data/dam/detectors/wrapper.bash >> /var/log/dam-detectors.log 2>&1
```

## resources

https://opensearch.org/docs/latest/observing-your-data/ad/api/
==> search detector result

