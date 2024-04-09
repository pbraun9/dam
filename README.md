# diy alerts monitor

## requirements

- an elastic/opensearch cluster
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source.geo.name` and `destination.geo.name`

## install

	mkdir -p /data/
	cd /data/
	git clone https://github.com/pbraun9/dam.git
	cd dam/
	cp -pi dam.conf.sample dam.conf
	vi dam.conf

	...

	chmod 600 dam.conf

## setup

[elastic/opensearch alerts](README.alerts.md)

[anomaly detection](README.detectors.md)

[spot the attacker](spot/README.md)

[service checks](README.svc.md)

[vmetrics](README.vmetrics.md)

## resources

https://api.slack.com/messaging/webhooks

https://api.slack.com/apps/

