#!/bin/bash

cd /home/witness/
exec /home/witness/steem/programs/cli_wallet/cli_wallet -s wss://gtg.steem.house:8090 -d --rpc-endpoint 127.0.0.1:8092
