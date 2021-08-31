import os
import time
from beem import Hive
from beem.utils import construct_authorperm

hive_key="TODO"

parent_author = "hbd.funder"
parent_permlink = "upvote-this-post-to-fund-hbdstabilizer"
reply_identifier = construct_authorperm(parent_author, parent_permlink)
print("reply_identifier: " + str(reply_identifier))

title="RE: Upvote this post to fund @hbdstabilizer"
author="hbd.funder"
tags=["hbd"]
beneficiaries=[{'account': "hbdstabilizer", 'weight': 10000}]
body="The rewards for this comment are set to 100% beneficiary going to the @hbdstabilizer account."

h = Hive(keys=[hive_key])
#hive.wallet.unlock("wallet-passphrase")

for x in range(0, 10):
   print("posting (" + str(x)+ ")")

   tx = h.post(title=title, body=body, author=author,
            reply_identifier=reply_identifier,
            tags=tags,beneficiaries=beneficiaries)

   print("post complete")

   print(tx)

   time.sleep(10)  # can only post once per block. give extra time in case of error.

print("done")
