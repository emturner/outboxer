#!/bin/sh

docker run \
       --entrypoint octez-smart-rollup-client-PtNairob \
       tezos/tezos:v18.1 \
       --endpoint 'http://et-tanpi-0:8932' "$@"
