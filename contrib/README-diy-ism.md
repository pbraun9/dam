## diy ism

## clean-up - delete unused datastreams

### low-size datastreams

find low-size datastreams

    ./datastream-stats-bytes.bash | head -50

and delete those with _kind of empty_ size

    ./datastream-delete.bash ...

or in a batch

    for ds in `awk '{print $2}' tmp_output`; do ./datastream-delete.bash $ds; done; unset ds

### empty indices

find indices with zero documents

    # todo - don't use _cat unless you fix the limit
    cd scripts/
    ./cat-indices-empty.bash

and delete those

    ./index-delete.bash ...

## clean-up - delete old indices

    cd scripts/

wipe out non-leaft indices older than one week
-- e.g. for DEV and UAT

    ./delete-old-dsindices.bash some-pattern 1w

wipe out non-leaft indices older than one month
-- but exclude specific datastreams from that list

    ./delete-old-dsindices.bash another-pattern 1m exclude_long_term.conf

or even three months

    cat exclude_long_term.conf
    ./delete-old-dsindices.bash excluded_datastream 3m
    ...

## auditing rollover scenarii

first, you need to know what's going on and seek for large shards
-- both, in terms of size and docs count

sometimes, you can define multiple datastreams at once simply by defining a prefix instead of the full ds name

    prefix=file-d-dev

don't ask me why it sometimes doesn't work e.g.

    prefix=audithack
    # ==> give you ALL the datastreams

    prefix=audithack-
    # ==> gives you nothing

so you have to be more precise e.g.

    prefix=audithack-peers

check which indices are larger in terms of size and doc counts

    rm -rf traces/
    mkdir traces/
    ./index-stats.bash $prefix > traces/index-stats.$prefix

    # sort by index primaries size
    sed -r 's/[[:space:]]/,/g; s/,+/,/g' traces/index-stats.$prefix | \
        sort -V -k2 -t, | \
        sed -r 's/,/ /g' | tail -50

    # sort by index primaries docs count
    sed -r 's/[[:space:]]/,/g; s/,+/,/g' traces/index-stats.$prefix | \
        sort -V -k4 -t, | \
        sed -r 's/,/ /g' | tail -50

now the same but per shard

    ./index-stats-shards.bash $prefix > traces/index-stats-shards.$prefix

    # sort by primary shard size
    sed -r 's/[[:space:]]/,/g; s/,+/,/g' traces/index-stats-shards.$prefix | \
        sort -V -k2 -t, | \
        sed -r 's/,/ /g' | tail -50

    # sort by primary shard docs count
    sed -r 's/[[:space:]]/,/g; s/,+/,/g' traces/index-stats-shards.$prefix | \
        sort -V -k4 -t, | \
        sed -r 's/,/ /g' | tail -50

