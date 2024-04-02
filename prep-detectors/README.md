# prepare anomaly detectors

## from scratch

first, create a sample detector from the UI
then eventually grab its config (helps to get the syntax right)

list existing detectors with their respective ID

	./detector-list.bash

and grab the sample config

	./detector-get.bash DETECTOR-NAME DETECTOR-ID

or all configs at once

	./wrapper-detector-get.bash

## generate new detectors

you can now create a configs for the detectors you want to create

	vi suri-max-flow-age.conf

check the generated config syntax and against the data

_beware we hard-coded 5 minutes interval with 1 minute window delay_

	./detector-validate.bash suri-max-flow-age.conf

create the validated detectors

	./detector-create.bash suri-max-flow-age.conf

now go to the opensearch dashboard and enable those

	Anomaly Detection // Detectors

	select all & actions enable

	also enable historical data for as long as possible

