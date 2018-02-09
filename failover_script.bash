#!/bin/bash

account="timcliff"
init_misses=82  #witness current total_misses count
misses_failover_count=3   #misses count threshold for failing over to backup pubkey
misses_failover_stop=5 #misses count threshold to stop failing over (will be taken over by other backup)
backup_pub_signing_key=STM5AVZZA9fJLvMA6de43z43643uXPtAU7gMSLrFJe7VTCi84UvdH
wallet="http://127.0.0.1:8092/rpc"  #steemd's rpc
wallet_passphrase="TODO"
props='{"account_creation_fee":"0.100 STEEM","maximum_block_size":65536,"sbd_interest_rate":0}'
witness_url="https://steemit.com/witness-category/@timcliff/timcliff-s-updated-witness-application"  #edit to match your witness URL/CV

##

function check_misses {
  misses="$(curl --data-ascii '{"id":0,"method":"get_witness","params":["'"$account"'"]}' \
                        -s "$wallet" \
                     | sed "s/,/\n/g" \
                     | grep "total_missed" \
                     | cut -d":" -f 2)"
  echo $misses
}

misses=`check_misses`
if [ -z "`echo $misses | grep -E '[[:digit:]]'`" ] ; then
  echo "[`date`] failed to fetch misses from steemd (not a number)"
  exit 1
fi
echo "[`date`] misses: $misses"
if [ $(($misses-$init_misses)) -ge $misses_failover_count ] ; then
   if [ $(($misses-$init_misses)) -le $misses_failover_stop ] ; then
      echo "[`date`] FAILOVER updating witness public signing key"
      curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"unlock\",\"params\":[\"$wallet_passphrase\"]}" $wallet
      curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"update_witness\",\"params\":[\"$account\",\"$witness_url\",\"$backup_pub_signing_key\",$props,true]}" $wallet 2>/dev/null
      curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"lock\",\"params\":[]}" $wallet
      sendemail -f TODO -t TODO -u subject -m "Witness Missing Blocks" -s smtp.live.com -o tls=yes -xu TODO -xp TODO
      exit 2
   fi
fi
echo "[`date`] no failover"

