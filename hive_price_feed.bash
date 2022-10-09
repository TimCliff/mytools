#!/bin/bash

# Price feed logic according to Dan:
# Apr 27th
# dan
# 9:11 PM @clayop max frequency 1 hr, min frequency 7 days max change 3%
# 9:11 also introduce some randomness in your queries
# 9:11 that will prevent everyone from updating at the same time
# 9:12 err.. min change 3% :simple_smile:
# 9:12 you can pick what ever percent you want, these are just my opinion on how to minimize network load while still serving the purpose effectively
# 9:23 PM the range for manual intervention should be +/- 50%
# 9:32 PM +/- 50% of HARD CODED long term average
# 9:32 PM I don't think the safety nets should be a percent of a past value...
# 9:32 yes.. so right now between .0005 and .002 SATS
# 9:33 $0.25 and $1.50
# 9:33 something along those lines
# 9:33 if the price moves up we can manually adjust the feeds

# 2016-09-18: added reduction of 10% from price feed, for trying to improve pegging

#min and max price (usd), to exit script for manual intervention
min_bound=0.1
max_bound=10.0
wallet=http://127.0.0.1:8092/rpc

usage () {
    cat 1>&2 <<__EOU__
Usage: $0 -w|--witness <witness> [-m|--min <min-price>] [-M|--max <max-price>] [-r|--rpc-url <rpc-url>]
-w sets the name of the witness whose price will be set.
-m and -M set the absolute maximum and minimum acceptable price. This script
   will exit if the actual price exceeds these bounds. Defaults are $min_bound
   and $max_bound, respectively.
-r specifies the cli_wallet's HTTP-RPC URL. The default is $wallet.


Hint: for slightly better security you should keep the cli_wallet locked at all
times. This program needs to unlock the wallet. For this,
create a file named "lock" in the current directory with read permission only
for yourself, and paste the following JSON-RPC command into the "lock" file:
{"id":0,"method":"unlock","params":["<your_password>"]}
Obviously, you need to replace the placeholder with your actual password.
__EOU__
    exit 1
}

unlock () {
    if [ -r lock ]; then
        echo -n "Unlocking wallet..."
        curl -s --data-ascii @lock "$wallet"
        echo ""
    fi
}

relock () {
    if [ -r lock ]; then
        echo -n "Re-locking wallet..."
        curl -s --data-ascii '{"id":0,"method":"lock","params":[]}' "$wallet"
        echo ""
    fi
}

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--witness) account="$2";   shift; ;;
        -m|--min)     min_bound="$2"; shift; ;;
        -M|--max)     max_bound="$2"; shift; ;;
        -r|--rpc-url) wallet="$2";    shift; ;;
        *)            usage;          ;;
    esac
    shift
done

if [ -z "$account" ]; then usage; fi

# Avoid problems with decimal separator
export LANG=C

get_wallet_price () {
    curl --data-ascii '{"id":0,"method":"get_witness","params":["'"$account"'"]}' \
         -s "$wallet" \
      | sed "s=[{,]=&$'\n'=g" \
      | grep -A 2 'hbd_exchange_rate' \
      | grep '"base"' \
      | cut -d\" -f 4 \
      | sed 's= HBD==;s= HIVE=='
}

get_last_update () {
    local jtime="$(curl --data-ascii '{"id":0,"method":"get_witness","params":["'"$account"'"]}' \
                        -s "$wallet" \
                     | sed "s=[{,]=&$'\n'=g" \
                     | grep '"last_hbd_exchange_update"' \
                     | cut -d\" -f 4 \
                     | sed 's= HBD==;s= HIVE==')"
    date --date "${jtime}Z" +%s
}

#function get_price {
#  while true ; do
#    while true ; do
#       price_fetch=`curl -s https://api.cryptonator.com/api/full/hive-usd 2>/dev/null`
#       [ $? -eq 0 ] && break
#       sleep 1m
#    done
#    price="$(printf "%0.3f" "$(echo $price_fetch \
#                                 | tr , "\n" \
#                                 | grep '"price"' \
#                                 | cut -d\" -f 4)" )"
#    #price source and way to calculate will probably need to be changed in the future
#    if [[ "$price" = *[[:digit:]]* ]] ; then
#      break
#    fi
#    sleep 1m
#  done
#  #reduction of percentage from feed
#  price=`echo "scale=3; ${price}" | bc`
#  echo "0${price}"
#}

#price_fetch=`curl -s https://bittrex.com/api/v1.1/public/getticker?market=BTC-HIVE 2>/dev/null`
#hive_price="$(printf "%0.8f" "$(echo $price_fetch | tr , "\n" | grep '"Last"' | cut -d: -f 2 | cut -d} -f 1 )")"
#echo $hive_price


#price_fetch=`curl -s https://api.binance.com/api/v1/ticker/price?symbol=HIVEBTC 2>/dev/null`
#hive_price="$(echo $price_fetch | tr , "\n" | grep '"price"' | cut -d: -f 2 | cut -d} -f 1 | sed -e 's/^"//' -e 's/"$//')"
#echo $hive_price

function get_price {
  while true ; do
    while true ; do
       #price_fetch=`curl -s https://bittrex.com/api/v1.1/public/getticker?market=BTC-HIVE 2>/dev/null`
       price_fetch=`curl -s https://api.binance.com/api/v1/ticker/price?symbol=HIVEBTC 2>/dev/null`
       [ $? -eq 0 ] && break
       sleep 1m
    done
    #hive_price="$(printf "%0.8f" "$(echo $price_fetch | tr , "\n" | grep '"Last"' | cut -d: -f 2 | cut -d} -f 1 )")"
    hive_price="$(echo $price_fetch | tr , "\n" | grep '"price"' | cut -d: -f 2 | cut -d} -f 1 | sed -e 's/^"//' -e 's/"$//')"
    if [[ "$hive_price" = *[[:digit:]]* ]] ; then
      break
    fi
    sleep 1m
  done

  while true ; do
    while true ; do
       price_fetch=`curl -s https://blockchain.info/ticker 2>/dev/null`
       [ $? -eq 0 ] && break
       sleep 1m
    done
    btc_price="$(printf "%0.8f" "$(echo $price_fetch | tr , "\n" | grep '"USD"' | cut -d: -f 3 )")"
    if [[ "$btc_price" = *[[:digit:]]* ]] ; then
      break
    fi
    sleep 1m
  done

calc_price=$(echo "${btc_price}*${hive_price}" |bc)

  # reduction of percentage from feed
price="$(printf "%0.3f" "$(echo $calc_price)")"
  echo "${price}"
}

init_price="`get_wallet_price`"
if [ "$init_price" = "" ]; then
    echo "Empty price - wallet not running?" 1>&2
    exit 1
fi
last_feed="`get_last_update`"

#while true ; do
  #check price
  price="`get_price`"
  echo "PRICE: $price"
  if [ "$price" = 0.000 ]; then
    echo "Zero price a - ignoring"
    exit 1
  fi
  if [ "$price" = 00 ]; then
    echo "Zero price b - ignoring"
    exit 1
  fi
  if [ "$price" = 0 ]; then
    echo "Zero price c - ignoring"
    exit 1
  fi
  #check persentage
  price_permillage="`echo "scale=3; (${price} - ${init_price}) / ${price} * 1000" | bc | tr -d '-'`"
  price_permillage="${price_permillage%.*}"
  now="`date +%s`"
  update_diff="$(($now-$last_feed))"
  #check bounds, exit script if more than 50% change, or minimum/maximum price bound
#  if [ "`echo "scale=3;$price>$max_bound" | bc`" -gt 0 -o "`echo "scale=3;$price<$min_bound" | bc`" -gt 0 ] ; then
#     echo "manual intervention (bound) $init_price $price, exiting"
#     exit 1
#  fi
#  if [ "$price_permillage" -gt 500 ] ; then
#     echo "manual intervention (percent) $init_price $price, exiting"
#     exit 1
#  fi
  #check if to send update (once an hour maximum, 3% change minimum, 1/48 hours minimum)
#  if [ "$price_permillage" -gt 30 -a "$update_diff" -gt 3600 \
#       -o "$update_diff" -gt 172600 ] ; then
    init_price="$price"
    last_feed="$now"
    unlock
    echo "sending feed ${price_permillage}/10% price: $price"
    curl --data-ascii '{"method":"publish_feed","params":["'"$account"'",{"base":"'"$price"' HBD","quote":"1.000 HIVE"},true],"jsonrpc":"2.0","id":0}' \
         -s "$wallet"
    relock
#  fi
  echo "${price_permillage}/10% | price: $price | time since last post: $update_diff"
#  wait="$(($RANDOM % 60))"
#  echo -n "Waiting until "
#  date --date=@"$(( $wait * 60 + $(date +%s) ))"
#  sleep "${wait}m"
#done


