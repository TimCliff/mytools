#!/bin/bash

account="timcliff"
init_misses=2238  #witness current total_misses count
misses_failover_count=5   #misses count threshold for failing over to backup pubkey
backup_pub_signing_key=STM1111111111111111111111111111111114T1Anm
wallet="http://127.0.0.1:8092/rpc"  #steemd's rpc
wallet_passphrase="TODO"
props='{"account_creation_fee":"3.000 HIVE","maximum_block_size":65536,"hbd_interest_rate":1000}'
witness_url="https://peakd.com/witness-category/@timcliff/timcliff-s-updated-witness-application"  #edit to match your witness URL/CV
email_to="TODO@PHONE.com"
email_from="TODO@hotmail.com"
email_pw="TODO"

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
   echo "[`date`] FAILOVER updating witness public signing key"
   curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"unlock\",\"params\":[\"$wallet_passphrase\"]}" $wallet
   curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"update_witness\",\"params\":[\"$account\",\"$witness_url\",\"$backup_pub_signing_key\",$props,true]}" $wallet 2>/dev/null
   curl -H "content-type: application/json" -X POST -d "{\"id\":0,\"method\":\"lock\",\"params\":[]}" $wallet
   sendemail -f $email_from -t $email_to -u subject -m "Witness Missing Blocks" -s smtp-mail.outlook.com -o tls=yes -xu $email_from -xp $email_pw
   exit 2
fi
echo "[`date`] no failover"
