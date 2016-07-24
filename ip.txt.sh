#! /bin/bash
# Advanced IP.TXT
# The script is named from left over by history.
# A daemon script that keep updating A record of changeable ip address to DNS server.
# By poilynx
# 17 Feb 2016
IPADDR_URL=http://ifconfig.co	# remote script that response ip address of request
SERVER=133.130.88.95			# DNS service address
DOMAIN=http://ifconfig.co		# Domain name
NAME_TTL=86400					# Time to live,604800 is 1 week,86400 is 1 day
KEYNAME=rndc-key				# key name for authentication
SECRET=XXXXX					# Secret key for authentication
PRE_ADDRESS=

while :
do
	# Query export ip address from remote HTTP service
	ADDRESS=`curl -s $IPADDR_URL`
	MATCH=`echo $ADDRESS|grep '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' -`
	# Delay and retry if  getting address failed or address same as before
	if [ -z $MATCH ] || [ "$ADDRESS" = "$PRE_ADDRESS" ]; then
		sleep 60
		continue
	fi
	# Send an UPDATE script of a record to remote DNS service
	nsupdate -y $KEYNAME:$SECRET>&2 2>/dev/null<<EOT
server $SERVER
update delete $DOMAIN A
update add $DOMAIN $NAME_TTL IN A $ADDRESS
send
quit
EOT
	PRE_ADDRESS=$ADDRESS
	sleep 240 # 4 minute
done

