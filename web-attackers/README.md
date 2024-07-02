# dam - spot the attacker

## requirements

- an elk cluster (elasticsearch or opensearch)
- some logs to be pushed over there
- specific fields to be available for alert verbosity e.g. `sensor`, `source.geo.name` and `destination.geo.name`

## goals

- spot web path brute forces
- spot auth attempt brute forces
- spot failing services

## descr

the `spot-brute-force` script is calling the **count API twice**

    1   OK http codes
    2   NOK http codes

and that for different scopes

    overall
    per vhost
    per remote_addr

and different timeframes according to the cron job and delay configuration setting.

## setup

we want to differenciate valid/OK http status codes from the rest

    cd conf.d/
    cp -pi nginx-prod.conf.sample nginx-prod.conf
    vi nginx-prod.conf

define the thresholds

    /data/dam/spot/wrapper-spot-brute-force-prep.bash

now you know what to expect in terms of failed http requests

    vi nginx-prod.conf

    ref_percent=...

## enable

```
# Track relative amount of non-2xx http status codes
 20 06 * * 1 /data/dam/web-attackers/wrapper.bash 1w    >> /var/log/dam-web-attackers-1w.log 2>&1
 02 06 * * * /data/dam/web-attackers/wrapper.bash 1d    >> /var/log/dam-web-attackers-1d.log 2>&1
02 */4 * * * /data/dam/web-attackers/wrapper.bash 4h    >> /var/log/dam-web-attackers-4h.log 2>&1
  02 * * * * /data/dam/web-attackers/wrapper.bash 1h    >> /var/log/dam-web-attackers-1h.log 2>&1
 */3 * * * * /data/dam/web-attackers/wrapper.bash 3m    >> /var/log/dam-web-attackers-3m.log 2>&1
```

## resources

https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

