#!/bin/bash

api_url="wss://anyx.io"

cd /home/witness/
exec /usr/bin/cli_wallet -s $api_url -d --rpc-http-endpoint 127.0.0.1:8092 --rpc-http-allowip 127.0.0.1
