# diy alerts monitor

## requirements

- an elastic/opensearch cluster
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source.geo.name` and `destination.geo.name`

## install

	mkdir -p /data/
	cd /data/
	git clone ...
	cd dam/
	cp -pi dam.conf.sample dam.conf
	vi dam.conf

	...

	chmod 600 *.conf

setup elastic/opensearch alerts e.g.

	cp -i hits/suricata-src1024.conf.sample hits/suricata-src1024.conf
	vi hits/suricata-src1024.conf

	...

	chmod 600 hits/*.conf

setup service alerts e.g.

_assuming ssh client config is in place_

	cp -i check-svc-wrapper.conf.sample check-svc-wrapper.conf
	vi check-svc-wrapper.conf

	...

	chmod 600 *.conf

## acceptance

	cd /data/dam/

elastic/opensearch alerts

	ls -lF /var/lock/*.lock
	./alert-hit.bash hits/suricata-src1024.conf

service alerts

	./check-svc.bash host service-name

## enable

```
*/15 * * * * /data/dam/alert-wrapper.bash >> /var/log/dam-alert.log 2>&1
 */5 * * * * /data/dam/check-svc-wrapper.bash >> /var/log/dam-svc.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

