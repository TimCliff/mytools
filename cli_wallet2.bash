#!/bin/bash

api_url="wss://anyx.io"

cd /home/witness/
exec /home/witness/steem/programs/cli_wallet/cli_wallet -s $api_url -d --rpc-endpoint 127.0.0.1:8092
