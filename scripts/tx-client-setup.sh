#!/bin/sh

echo '[info] Initialising tx-client'
tx-client config-init \
          --tz-client $(pwd)/scripts/oclient.sh \
          --tz-client-base-dir /root/.tezos-client \
          --tz-rollup-client $(pwd)/scripts/srclient.sh \
          --forwarding-account alice

echo '[info] Importing l1 accounts from sandbox'

alice=$($(pwd)/scripts/oclient.sh show address alice | grep 'Hash' | awk '{print $2}')
tx-client import-address --address $alice --alias 'l1-alice'

bob=$($(pwd)/scripts/oclient.sh   show address bob   | grep 'Hash' | awk '{print $2}')
tx-client import-address --address $bob   --alias 'l1-bob'

echo '[info] Generating l2 accounts'

tx-client gen-key l2-alice
tx-client gen-key l2-bob
