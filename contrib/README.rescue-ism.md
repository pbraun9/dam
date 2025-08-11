# reassign policies to all indices

note you can assign multiple indices at once by pointing to the datastream

generate the list of datastreams

    ./show-data-streams.bash > list

for precise index patterns that match a specific datastream, proceed individually

    ./ism-add-policy.bash test-mgmt test-access
    ./ism-update-managed-policy.bash test-mgmt test-access

for an index pattern that matches multiple datastreams, use the wrapper

    ./wrapper-add-policy.bash test-mgmt test-

clean-up

    rm -f list*

