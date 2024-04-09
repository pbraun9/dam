# setup alerts

elastic/opensearch search query alerts

	cp -i hits/suricata-src1024.conf.sample hits/suricata-src1024.conf
	vi hits/suricata-src1024.conf

elastic/opensearch count query alerts

	cp -i hits/suricata-src1024.conf.sample hits/suricata-src1024.conf
	vi hits/suricata-src1024.conf

elastic/opensearch alive index alerts

	cp -pi alive/suricata.conf.sample alive/suricata.conf
	vi alive/suricata.conf

## acceptance

	ls -lF /var/lock/*.lock

	cd /data/dam/
	./alert-hit.bash hits/suricata-src1024.conf
	#/data/dam/alert-hit-dql.bash ...
	#/data/dam/alert-count.bash ...
	./alert-alive.bash /data/dam/alive/suricata.conf

## enable

```
crontab -e

# Search query alerts
*/15 * * * * /data/dam/wrapper-alerts.bash >> /var/log/dam-alerts.log 2>&1
```

## resources

https://elastic.co/guide/en/elasticsearch/reference/7.17/query-dsl-range-query.html

