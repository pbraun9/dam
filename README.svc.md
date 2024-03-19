# service checks

## requirements

alerts system

	ssh-keygen -t ed25519
	cat ~/.ssh/*pub

target machines

	useradd -m -g users -s /bin/bash alerts
	mkdir ~alerts/.ssh/
	vi ~alerts/.ssh/authorized_keys

	chmod 700 ~alerts/.ssh/
	chmod 600 ~alerts/.ssh/authorized_keys
	chown -R alerts:users /home/alerts/

## setup

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

