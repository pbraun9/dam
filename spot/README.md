# dam - spot the attacker

## setup

### spot web path brute force

we want to differenciate 2xx and 301-304 http status codes from the rest (incl. 101, 4xx and 5xx)

    cd conf.d/
    cp -pi nginx-prod.conf.sample nginx-prod.conf
    vi nginx-prod.conf

    index=...

define the thresholds

    /data/dam/spot/wrapper-spot-brute-force-prep.bash

now you know what to expect in terms of failed http requests

    vi nginx-prod.conf

    ref_percent=...

## acceptance

    /data/dam/spot/wrapper-spot-brute-force-overall.bash 3m
    /data/dam/spot/wrapper-spot-brute-force-client.bash 3m

    /data/dam/spot/wrapper-spot-brute-force-overall.bash 1h
    /data/dam/spot/wrapper-spot-brute-force-client.bash 1h

## enable

```
# Track relative amount of non-2xx http status codes
 20 04 * * * /data/dam/spot/wrapper-spot-brute-force-prep.bash  >> /var/log/dam-spot-prep.log 2>&1
  02 * * * * /data/dam/spot/wrapper-spot-brute-force.bash 1h    >> /var/log/dam-spot-1h.log 2>&1
 */3 * * * * /data/dam/spot/wrapper-spot-brute-force.bash 3m    >> /var/log/dam-spot-3m.log 2>&1
```

## resources

https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

