# setting up anomaly detectors

### setup

the hard part was to create the detectors [through the api](contrib/README) -- you can now simply proceed with the wrapper.

	contrib/detector-list.bash
	./wrapper-detectors.bash

### acceptance

	vi detector-results.bash

	# override to 1H for testing
	delay_minutes=60

### enable

```
 */5 * * * * /data/dam/wrapper-detectors.bash >> /var/log/dam-detectors.log 2>&1
```

