# sample search queries

## aggs flavors

_keywords & numeric_ 

    single terms aggs       doc count ordering

    nested terms aggs       shows results per terms1 doc count ordering then terms2 within

    multi terms aggs        combines two fields then does doc count ordering

    composite aggs          (?) combines two fields doc count but w/o ordering

_sub-aggs metrics only_

    multi metric aggs       specific stats per field

    extended stats aggs     calculate min, avg, max, deviation, ...

    percentiles             show outliner values for a metric

## example usage

    index='nginx-prod-access*'

    ./request-custom.bash $index query-aggs.json

    ./request-custom.bash $index query-aggs-nested-terms.json
    ./request-custom.bash $index query-aggs-multi-terms.json
    ./request-custom.bash $index query-aggs-composite.json

    ./request-custom.bash $index query-aggs-nested-metric.json
    ./request-custom.bash $index query-aggs-extended-stats.json
    ./request-custom.bash $index query-aggs-percentiles.json

<!-- TODO try to combine multi-terms aggs + multi-metrics aggs -->

## resources

### multi-fields

https://opster.com/guides/elasticsearch/search-apis/elasticsearch-aggregation-multiple-fields/

https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-aggregations-pipeline.html

https://opensearch.org/docs/latest/aggregations/pipeline-agg/

### percentiles

https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-aggregations-metrics-percentile-aggregation.html

https://opensearch.org/docs/latest/aggregations/metric/percentile/

