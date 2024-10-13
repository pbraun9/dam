# diy alerts monitor

## description

DAM offers several components to check various kinds of alerts

- hits and aggregates from log servers
- performance triggers from metric servers
- service and space checks through SSH

you do not have to use them all: you can choose which component you want to use.

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

[elk alerts](alerts/README.md)

[anomaly detection](detectors/README.md)

[service checks](services/README.md)

[prom-like metrics](vmetrics/README.md)

[spot web attackers](web-attackers/README.md)

## usage

some kind of a SIEM interface...

    tail -F /var/log/dam-alerts.log
    tail -F /var/log/dam-detectors.log
    tail -F /var/log/dam-services*.log
    tail -F /var/log/dam-vmetrics.log
    tail -F /var/log/dam-web-attackers-*log

## log rotation

```
vi /etc/logrotate.d/dam

/var/log/dam-*.log {
        daily
        missingok
        rotate 3
        notifempty
}
```

## resources

https://api.slack.com/messaging/webhooks

https://api.slack.com/apps/

