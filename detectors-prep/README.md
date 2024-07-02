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

## setup detectors

define fields and values for the detectors you want to create

    ls -lF conf/detectors-prep/*

    cd /etc/dam/detectors-prep/
    vi cloudflare-TAG-min-waf.conf
    vi falco-count-rule.conf
    vi ...

## generate detectors

check the generated config syntax and against the data

    for f in /etc/dam/detectors-prep/*; do
        ./detector-validate.bash $f
    done; unset f

create the validated detectors

    for f in /etc/dam/detectors-prep/*; do
	    ./detector-create.bash $f
    done; unset f

## ready to go

now go to the opensearch dashboard and enable those

	Anomaly Detection // Detectors

	select all & actions enable

	also enable historical data for as long as possible

