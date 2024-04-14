# dam - tools

## descr

query allows to --either-- grab only affected entries (with field present)
--or-- to refine the search to reduce scope of aggregation.

aggs allows to perform operation against a specific aggregatable field
which should be either numeric or keyword (string won't do).

## example usage

### count api

total entries with http status code

        count.bash nginx-prod-access 'status:*' 1w

### search api

more details on the activity of a specific IP

        query.bash nginx-prod-access 'remote_addr:\"x.x.x.x\"' 5m 1

### search api aggs [keyword]

top 3 remote IPs last 4 hours (descending)

        ${0##*/} 'nginx-prod-*' '!remote_addr:\"10.0.0.0/8\"' 4h remote_addr 3

http status codes last 4 hours (descending)

        ${0##*/} 'nginx-prod-*' 'status:*' 4h status

### search api aggs [numeric]

average response time

        query-aggs-avg.bash 'nginx-prod-*' 'request_time:*' 1w request_time

request time outliners

        query-aggs-percentiles.bash nginx-prod-access 'request_time:*' 1w request_time

