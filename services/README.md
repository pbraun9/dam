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

## ready to go & acceptance

check the wrapper works fine

    ls -lF /var/lock/*.lock | grep `date +%Y-%m-%d`
	/data/dam/check-svc.bash HOST SERVICE-NAME

and enable

```
crontab -e

# Service alerts
 */5 * * * * /data/dam/services/wrapper.bash >> /var/log/dam-services.log 2>&1
  43 * * * * /data/dam/services/wrapper-space.bash >> /var/log/dam-services.log 2>&1
```

