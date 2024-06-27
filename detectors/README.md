# setting up anomaly detectors

## descr

the hard part was to create the detectors [through the api](detectors-prep/README.md)

	contrib/detector-list.bash

### acceptance

you can now simply proceed with the wrapper

    cd detectors/

	vi detector-results.bash

	# override to 1H for testing
	delay_minutes=60

	./wrapper.bash

### enable

```
crontab -e

# Anomaly detection
 */5 * * * * /data/dam/detectors/wrapper.bash >> /var/log/dam-detectors.log 2>&1
```

## resources

https://opensearch.org/docs/latest/observing-your-data/ad/api/

https://opensearch.org/docs/2.11/observing-your-data/ad/index/
==> about detection_interval and window_delay

