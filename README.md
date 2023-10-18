<!--
SPDX-FileCopyrightText: 2023 Emma Turner <mail@emturner.co.uk>

SPDX-License-Identifier: MIT
-->

# Outboxer

An indexer for outboxes!

## Sandbox

We use **flextesa** for setting up a network, with the smart rollup pre-configured.

```sh
scripts/init_sandbox.sh
```

We use `octez-client` from the sandbox. By default this comes with one baker, and two non-baker accounts:

```sh
alias oclient='scripts/oclient.sh'

oclient get balance for alice
# 2000000 ꜩ

oclient get balance for bob
# 1900000 ꜩ
```

We can confirm the smart rollup was started successfully with:

```sh
docker exec tx_sandbox nairobibox smart_rollup_info
# {
#   "smart_rollup_node_config":  {
#   "smart-rollup-address": "sr1Gyas9pW5FyUAmp7ewQYAc8q98PWWEF7SU",
#   "smart-rollup-node-operator": {
#     "operating": "tz1SEQPRfF2JKz7XFF3rN2smFkmeAmws51nQ",
#     "batching": "tz1SEQPRfF2JKz7XFF3rN2smFkmeAmws51nQ",
#     "cementing": "tz1SEQPRfF2JKz7XFF3rN2smFkmeAmws51nQ"
#   },
#   "rpc-addr": "0.0.0.0",
#   "rpc-port": 20010,
#   "fee-parameters": {},
#   "mode": "operator"
# },
# }
```

## `tx-client`

The `tx-client` is a cli for interacting with the deployed Tx Kernel.

```sh
TX_CONFIG=$(pwd)/.config/tx-client-nairobibox.json

alias tx-client='../tx-client/target/debug/tx_kernel_client --config-file $TX_CONFIG'
```

And we initialise it:

```shell
. scripts/tx-client-setup.sh
```

### TODO deposit/transfer/withdraw args
