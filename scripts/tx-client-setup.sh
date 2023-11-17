#!/bin/sh

export TX_CONFIG=".config/tx-client-nairobibox.json"
export T2_CONFIG=".config/t2-client-nairobibox.json"

alias tx-client='../tx-client/target/debug/tx_kernel_client --config-file $TX_CONFIG'
alias t2-client='../tx-client/target/debug/tx_kernel_client --config-file $T2_CONFIG'

echo '[info] Initialising tx-client'
tx-client config-init \
          --tz-client $(pwd)/scripts/oclient.sh \
          --tz-client-base-dir /root/.tezos-client \
          --tz-rollup-client $(pwd)/scripts/srclient.sh \
          --forwarding-account alice

t2-client config-init \
          --tz-client $(pwd)/scripts/oclient.sh \
          --tz-client-base-dir /root/.tezos-client \
          --tz-rollup-client $(pwd)/scripts/srclient.sh \
          --forwarding-account bob

echo '[info] Importing l1 accounts from sandbox'

alice=$($(pwd)/scripts/oclient.sh show address alice | grep 'Hash' | awk '{print $2}')
bob=$($(pwd)/scripts/oclient.sh   show address bob   | grep 'Hash' | awk '{print $2}')

tx-client import-address --address $alice --alias 'l1-alice'
tx-client import-address --address $bob   --alias 'l1-bob'

t2-client import-address --address $alice --alias 'l1-alice'
t2-client import-address --address $bob   --alias 'l1-bob'

echo '[info] Generating l2 accounts'

tx-client gen-key l2-alice
t2-client gen-key l2-bob

tx-client mint-and-deposit --target l2-alice --amount 1000 --contents "hi" --ticket-alias hi
t2-client mint-and-deposit --target l2-bob   --amount 1000 --contents "ao" --ticket-alias ao

function multi-withdraw() {
    tx-client withdraw --from l2-alice --ticket hi --amount 1 &
    t2-client withdraw --from l2-bob   --ticket ao --amount 1 &
}
