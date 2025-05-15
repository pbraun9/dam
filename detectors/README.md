# setting up anomaly detectors

## requirements

you need some anomaly detectors in place
-- eventually create those [through the api](../detectors-config/README.md).
once you are done, check they are up and running

    cd /data/dam/detectors/
	./list-detectors.bash

## setup

place the conf files in place (ideally accoriding to detector names for clarity)

    mkdir -p /etc/dam/detectors/
    cp -R /data/dam/conf_samples/detectors/*conf /etc/dam/detectors/
    vi /etc/dam/detectors/*conf

and eventually some helper for building up the link

    query="EdgeResponseStatus:[500 TO 599]"

note there's also some code to handle this one

    cathegory=...

## ready to go & acceptance

check that the wrapper works fine

	/data/dam/detectors/wrapper.bash

and enable

```
crontab -e

# Anomaly detection
* * * * * /data/dam/detectors/wrapper.bash >> /var/log/dam-detectors.log 2>&1
```

## resources

https://opensearch.org/docs/latest/observing-your-data/ad/api/
==> search detector result

