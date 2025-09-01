# heavy duty ism repairs

## reassign policies to all indices

note you can assign multiple indices at once by pointing to the datastream

generate the list of datastreams' indices and their attached policy

    ./wrapper-datastreams-ism-explain.bash | grep '^\.' | awk '{print $1, $2}' > tmp_output

find specific indices without any policy attached

    grep -E '^[^ ]+$' tmp_output

for precise index patterns that match a specific datastream, proceed individually

    ./ism-managed-add-policy.bash    policy-name datastream-or-pattern
    ./ism-managed-change-policy.bash policy-name datastream-or-pattern

for an index pattern that matches multiple datastreams, use the wrapper

    cd scripts/
    ./wrapper-datastreams-ism-policy-add.bash policy-name test-pattern

## prepare list of failed ism tasks

prepare the list, then re-enable and check previously failed index policies
-- look for all kinds of ISM failures

    time ./wrapper-datastreams-ism-explain-leaf.bash | grep -v OK$ > leaf_fails

check there's only rollover failures

    grep -v rollover leaf_fails
    # ==> should be empty

## re-trigger failed managed policies

plan A] attempt to just re-trigger the policy

let's handle the datastream leafs first
    
    for index in `cat leaf_fails | awk '{print $1}'`; do
        ./ism-managed-retry-policy.bash $index
    done; unset index

    for index in `cat leaf_fails | awk '{print $1}'`; do
        ./ism-explain.bash $index
    done; unset index

now let's handle all datastream indices

    time ./wrapper-datastreams-ism-explain.bash | grep -vE '^$|^[[:alnum:]-]+$|OK$' > index_fails

    for index in `cat index_fails | awk '{print $1}'`; do
        ./ism-managed-retry-policy.bash $index
    done; unset index

    for index in `cat index_fails | awk '{print $1}'`; do
        ./ism-explain.bash $index
    done; unset index

plan B] proceed with manual rollovers

    cat leaf_fails | wc -l
    fails=`awk '{print $1}' leaf_fails | tail`

    for fail in $fails; do
        # index to datastream
        ds=`echo $fail | sed -r 's/^.ds-//; s/-[[:digit:]]+$//'`
        ./datastream-rollover.bash $ds
        unset ds
    done; unset fail

