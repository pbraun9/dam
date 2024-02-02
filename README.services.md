# service checks

setup service checks e.g.

_assuming ssh client config is in place_

	cp -i wrapper-svc.conf.sample wrapper-svc.conf
	vi wrapper-svc.conf

	...

	chmod 600 *.conf

## acceptance

	cd /data/dam/

	./check-svc.bash host service-name

## enable

```
 */5 * * * * /data/dam/wrapper-svc.bash >> /var/log/dam-svc.log 2>&1
```

