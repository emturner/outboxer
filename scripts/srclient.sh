#!/bin/sh

docker exec tx_sandbox octez-smart-rollup-client-PtNairob \
       --endpoint 'http://localhost:20010' "$@"
