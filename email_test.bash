#!/bin/bash

email_to="TODO@umn.edu"
email_from="TODO@hotmail.com"
email_pw="TODO"

sendemail -f $email_from -t $email_to -u subject -m "Witness Test" -s smtp.live.com -o tls=yes -xu $email_from -xp $email_pw

echo "done"

