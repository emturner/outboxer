#!/bin/sh

echo '#################################'
echo '#      Welcome to Outboxer      #'
echo '#                               #'
echo '#    The indexer for outboxes   #'
echo '#################################'

docker run --rm --detach \
       --volume $(pwd)/artifacts:/rollup \
       -p 20000:20000 -p 20010:20010 \
       --name tx_sandbox \
       oxheadalpha/flextesa:latest nairobibox \
       start_custom_smart_rollup wasm_2_0_0 '(pair string (ticket string))' \
       /rollup/tx_kernel.wasm

echo '[info] bootstrapping node'

while ! $(pwd)/scripts/oclient.sh bootstrapped 2> /dev/null
do
    sleep 1
done

echo '[info] activating nairobi'
while [ -z $($(pwd)/scripts/oclient.sh rpc get /chains/main/blocks/head/protocols | jq '.protocol' | grep Nairobi) ]
do
    sleep 1
done

echo '[info] Originating ticketer contract'
$(pwd)/scripts/oclient.sh originate contract mint_and_deposit_to_rollup \
      transferring 0 from alice \
      running file:/rollup/mint_and_deposit_to_rollup.tz \
      --init "Unit" \
      --burn-cap 0.1155
