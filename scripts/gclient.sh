#!/bin/sh

BASE_DIR="/home/emma/sources/outboxer/.ghostnet-client"

docker run -v "$BASE_DIR":/var/run/tezos/client tezos/tezos:v18.1 octez-client \
       --endpoint "http://et-tanpi-0:8733" "$@"
