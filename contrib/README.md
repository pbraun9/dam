# anomaly detectors - additional notes

## list and grab existing detectors

list existing detectors with their respective ID

	cd contrib/
	./detector-list.bash

eventually grab the config of an existing detector (helps to get the syntax right)

	./detector-get.bash DETECTOR-NAME DETECTOR-ID

or all configs at once

	./wrapper-detector-get.bash

## generate & create new detectors

create a few configs for the detectors you want to create

	cd detectors/
	cp -pi logs-suricata-max-flow-age.conf.sample logs-suricata-max-flow-age.conf
	vi logs-suricata-max-flow-age.conf
	cd ../

check the generated config syntax and against the data

_beware we hard-coded 5 minutes interval with 1 minute window delay_

	./wrapper-detectors-validate.bash detectors/logs-suricata-max-flow-age.conf

create the validated detectors

	./detector-create.bash detectors/logs-suricata-max-flow-age.conf

now go to the opensearch dashboard and enable those

	anomaly detection // Detectors
	select all & actions enable
	also enable historical data e.g. for 2 last weeks

