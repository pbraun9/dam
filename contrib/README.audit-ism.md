# auditing rollover scenarii

    datastream=DS-OR-WILDCARD

check which indices are larger in terms of size and doc counts

    mkdir -p traces/
    ./index-stats.bash $datastream > traces/index-stats.$datastream

    # sort by index primaries size
    sort -V -k2 -t' ' traces/index-stats.$datastream | tail

    # sort by index primaries docs count
    sed -r 's/[[:space:]]/,/g;
            s/,+/,/g' traces/index-stats.$datastream | \
    sort -V -k4 -t, | \
    sed -r 's/,/ /g' | tail

now the same but per shard

    ./index-stats-shards.bash $datastream > traces/index-stats-shards.$datastream

    sort -V shards.size | tail -50
    sort -V shards.docs | tail -50

    # sort by primary shard size
    sort -V -k2 -t' ' traces/index-stats-shards.$datastream | tail

    # sort by primary shard docs count
    sed -r 's/[[:space:]]/,/g;
            s/,+/,/g' traces/index-stats-shards.$datastream | \
    sort -V -k4 -t, | \
    sed -r 's/,/ /g' | tail

