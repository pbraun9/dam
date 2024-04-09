# dam - spot the attacker

## setup

### spot web path brute force

we want to differenciate 2xx and 301-304 http status codes from the rest (incl. 4xx and 5xx)

    cd conf.d/
    cp -pi nginx-prod.conf.sample nginx-prod.conf
    vi nginx-prod.conf

    index=...

define the thresholds

    /data/dam/spot/wrapper-spot-brute-force-prep.bash
    cat /var/log/dam.daily.percent.log
    vi nginx-prod.conf

    ref_percent=...

## acceptance

    /data/dam/spot/wrapper-spot-brute-force-overall.bash 3m
    /data/dam/spot/wrapper-spot-brute-force-client.bash 3m

## enable

```
# Track relative amount of non-2xx http status codes
 20 04 * * * /data/dam/spot/wrapper-spot-brute-force-prep.bash >> /var/log/dam-spot.log 2>&1
 */3 * * * * /data/dam/spot/wrapper-spot-brute-force-overall.bash 3m >> /var/log/dam-spot.log 2>&1
 */3 * * * * /data/dam/spot/wrapper-spot-brute-force-client.bash 3m >> /var/log/dam-spot.log 2>&1
```

