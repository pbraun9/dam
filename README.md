# diy alerts monitor

## requirements

- an elastic/opensearch cluster
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source.geo.name` and `destination.geo.name`

## install

	mkdir -p /data/
	cd /data/
	git clone https://github.com/pbraun9/dam.git

    mkdir -p /etc/dam/
	cp dam/conf/dam.conf /etc/dam/
	vi /etc/dam/dam.conf

	...

    chmod 700 /etc/dam/
	chmod 600 /etc/dam/dam.conf

## setup

[elastic/opensearch alerts](alerts/README.md)

[anomaly detection](detectors/README.md)

[service checks](services/README.md)

[prom-like metrics](vmetrics/README.md)

[spot web attackers](web-attackers/README.md)

## resources

https://api.slack.com/messaging/webhooks

https://api.slack.com/apps/

