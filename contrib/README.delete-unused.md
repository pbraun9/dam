# delete unused datastreams

## low-size datastreams

find low-size datastreams

    ./show-data-stream-stats.bash

and delete those with standard -- kind of empty -- size

    ./delete-datastream.bash ...

## empty indices

find indices with zero documents

    ./show-indices-emtpy.bash

and delete those

    ./delete-index.bash ...

