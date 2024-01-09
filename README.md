# diy alerts monitor

## requirements

- an elastic/opensearch cluster
- some logs to be pushed over there (here suricata eve)
- specific fields to be available for alert verbosity as for `alerts-hit.bash` (here `sensor src.name dest.name`)

## install

	mkdir -p /data/
	cd /data/
	git clone ...
	cd dam/
	cp -pi dam.conf.sample dam.conf
	vi dam.conf

	...

setup alerts e.g.

	cp -i suricata-src1024.conf.sample suricata-src1024.conf
	cp -i suricata-count-sigs.conf.sample suricata-count-sigs.conf
	vi suricata-src1024.conf
	vi suricata-count-sigs.conf

	...

	chmod 600 *.conf

## test

	cd /data/dam/
	ls -lF *.lock
	./alert-hit.bash suricata-src1024.conf
	./alert-count.bash suricata-count-sigs.conf

## enable

```
*/15 * * * * /data/dam/alert-wrapper.bash >> /var/log/dam.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

