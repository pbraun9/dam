# setup alerts

setup elastic/opensearch alerts e.g.

	cp -i hits/suricata-src1024.conf.sample hits/suricata-src1024.conf
	vi hits/suricata-src1024.conf

	...

	chmod 600 hits/*.conf

## acceptance

	cd /data/dam/

elastic/opensearch alerts

	ls -lF /var/lock/*.lock
	./alert-hit.bash hits/suricata-src1024.conf

service alerts

	./check-svc.bash host service-name

## enable

```
crontab -e

# Query Alerts
*/15 * * * * /data/dam/wrapper-alerts.bash >> /var/log/dam-alerts.log 2>&1
```

