# fix failed managed policies

prepare the list, then re-enable and check previously failed index policies.

let's handle the datastream leafs first

    time ./wrapper-datastreams-ism-explain-leaf.bash | grep -v OK$ > leafs_failed

    for index in `cat leafs_failed | awk '{print $1}'`; do
        ./ism-managed-retry-policy.bash $index
    done; unset index

    for index in `cat leafs_failed | awk '{print $1}'`; do
        ./ism-explain.bash $index
    done; unset index

now let's handle all datastream indices

    time ./wrapper-datastreams-ism-explain.bash | grep -vE '^$|^[[:alnum:]-]+$|OK$' > indices_failed

    for index in `cat indices_failed | awk '{print $1}'`; do
        ./ism-managed-retry-policy.bash $index
    done; unset index

    for index in `cat indices_failed | awk '{print $1}'`; do
        ./ism-explain.bash $index
    done; unset index

