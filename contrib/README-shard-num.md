# wrong shard num

say you want to check that every data-stream has a leaf-index with the right number of shards

show all data-streams with number of shards per index

    ./wrapper-datastreams-index-settings-shard-num.bash

now only the leafs

    ./wrapper-datastreams-index-settings-shard-num-leaf.bash

grep-out the faulty ones with the wrong number of shards
-- here right amount of shards are 3 for small streams and 6 for large streams

    ./wrapper-datastreams-index-settings-shard-num-leaf.bash | grep -vE '"[36]",$'

    ./wrapper-datastreams-index-settings-shard-num-leaf.bash | grep -vE '"[36]",$' | \
        awk '{print $1}' > shards1

now grep-out a specific prefix AND convert back to data-stream name

    sed -r 's/^\.ds-//; s/-[[:digit:]]+$//' shards1 > shards1-ds

you a ready to rollover in a batch

    for ds in `cat shards1-ds`; do ./index-rollover.bash $ds; done; unset ds

clean-up

    rm -f shards1*

