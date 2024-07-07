# prepare anomaly detectors

<!--
## from scratch

first, create a sample detector from the UI
then eventually grab its config (helps to get the syntax right)

list existing detectors with their respective ID

	../detectors/list-detectors.bash

and grab the sample config

	./detector-get.bash DETECTOR-NAME DETECTOR-ID > DETECTOR-NAME-template.conf
-->

## detectors setup

deploy sample configs

    cd /data/dam/
    cp -R conf/detectors-prep/ /etc/dam/

## simple detector creation (single feature / no filter / no category)

define fields and values for the (simple) detectors you want to create

    ls -lF /etc/dam/detectors-prep/*.conf

check the generated config syntax and if the fields match with the existing data
(otherwise you might get the too sparse warning)

    cd /data/dam/detectors-prep/
    for f in /etc/dam/detectors-prep/*.conf; do
        ./detector-validate.bash $f
    done; unset f

create the validated detectors

    for f in /etc/dam/detectors-prep/*.conf; do
	    ./detector-create.bash $f
    done; unset f

## advanced detector creation (json)

tune the json for the (advanced) detectors you want to create

    ls -lF /etc/dam/detectors-prep/*.json

validate and create the detectors at once

    cd /data/dam/detectors-prep/
    for f in /etc/dam/detectors-prep/*.conf; do
        ./create-detector-from-json.bash $f
    done; unset f

## ready to go

now go to the opensearch dashboard and enable those

	Anomaly Detection // Detectors

	select all & actions enable

	also enable historical data for as long as possible

## troubleshooting

you can review the detectors' setup using those scripts in the detectors/ folder

    cd /data/dam/detectors/
    ./list-detectors.bash
    ./detector-get.bash DETECTOR-ID

