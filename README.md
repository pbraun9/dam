# diy alerts monitor

## requirements

- an elastic/opensearch cluster
- some logs to be pushed over there (suricata eve with `flow` enabled as an alert sample)
- specific fields to be available for alert verbosity (`sensor src.name dest.name` in our example)

## install

	mkdir -p /data/
	cd /data/
	git clone ...
	cd dam/
	cp -pi dam.conf.sample dam.conf
	vi dam.conf

	...

setup an alert e.g.

	cp -pi suricata-src1024.conf.sample suricata-src1024.conf
	vi suricata-src1024.conf

	...

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

