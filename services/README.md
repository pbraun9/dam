# service checks

## requirements

we need `ssh-ping` command to be available

	apt install ssh-tools

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

## acceptance

	cd /data/dam/
	./check-svc.bash host service-name

## enable

```
crontab -e

# Service alerts
 */5 * * * * /data/dam/services/wrapper.bash >> /var/log/dam-services.log 2>&1
```

