# setup anomaly detectors

<!--
## from scratch

first, create a sample detector from the UI
then eventually grab its config (helps to get the syntax right)

list existing detectors with their respective ID

	../detectors/list-detectors.bash

and grab the sample config

	./detector-get.bash DETECTOR-NAME DETECTOR-ID > DETECTOR-NAME-template.conf

## detectors setup
-->

deploy sample configs

    cp -R conf_samples/detectors-config/ /etc/dam/

you can now proceed with either simple detector and/or advanced detector creation as follows.

### simple detector creation

_single feature / no filter / no category_

define fields and values for the (simple) detectors you want to create

    ls -lF /etc/dam/detectors-config/*.conf

check the generated config syntax and if the fields match with the existing data
(otherwise you might get the too sparse warning)

    cd /data/dam/detectors-config/
    for f in /etc/dam/detectors-config/*.conf; do
        ./detector-validate.bash $f
    done; unset f

create the validated detectors

    for f in /etc/dam/detectors-config/*.conf; do
	    ./detector-create.bash $f
    done; unset f

### advanced detector creation

tune the json for the (advanced) detectors you want to create

    ls -lF /etc/dam/detectors-config/*.json

validate and create the detectors at once

    cd /data/dam/detectors-config/
    for f in /etc/dam/detectors-config/*.conf; do
        ./create-detector-from-json.bash $f
    done; unset f

## ready to go

now go to the opensearch dashboard and enable those

	Anomaly Detection // Detectors

	select all & actions ==> enable

	and eventually enable historical data for e.g. 2 weeks

## troubleshooting

you can review the detectors' setup using those scripts

    cd /data/dam/detectors/
    ./list-detectors.bash
    ./detector-get.bash DETECTOR-ID

## resources

https://opensearch.org/docs/latest/observing-your-data/ad/api/
==> create anomaly detector

https://opensearch.org/docs/2.11/observing-your-data/ad/index/
==> about detection_interval and window_delay

