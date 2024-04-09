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

[elastic/opensearch alerts](README.alerts)

[anomaly detection](README.detectors)

[spot the attacker](spot/README)

[service checks](README.svc)

[vmetrics](README.vmetrics)

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

https://api.slack.com/messaging/webhooks

https://api.slack.com/apps/

### anomaly detection

https://opensearch.org/docs/latest/observing-your-data/ad/api/

https://opensearch.org/docs/2.11/observing-your-data/ad/index/
==> about detection_interval and window_delay

