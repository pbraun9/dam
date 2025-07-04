# heavy-duty rollovers

say you want to check that every data-stream has a leaf-index with the right number of shards

work on a specific env

    prefix=file-d-dev
    prefix=file-d-stag
    prefix=file-d-prod-app
    prefix=file-d-prod-data
    prefix=file-d-infra

first, show data-streams with number of shards

    ./show-data-streams-shard-num.bash | grep $prefix

grep-out the faulty ones with not the right number of shards (here 5 for small streams or 8 for large streams)

    ./show-data-streams-shard-num.bash | grep $prefix | grep -vE '"[58]",$' | awk '{print $1}' > shards1

now grep-out a specific prefix AND convert back to data-stream name

    sed -r 's/^\.ds-//; s/-[[:digit:]]+$//' shards1 > shards1-$prefix-ds

you a ready to rollover in a batch

    for ds in `cat shards1-$prefix-ds`; do ./rollover.bash $ds; done; unset ds

clean-up

    rm -f shards1*

