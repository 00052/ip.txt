#! /bin/bash
# IP.TXT for DNSPOD
# Li hsilin (lihsilyn@gmail.com)
# 7 Oct 2019

# Begin configure
DOMAIN='<DOMAIN>' # Root-domain 

SUB_DOMAIN='<SUBDOMAIN>' # Sub-domain

LOGIN_TOKEN='<TOKEN_ID>,<TOKEN>' # https://support.dnspod.cn/Kb/showarticle/tsid/227

RECORD_ID='<RECORD_ID>' # https://www.dnspod.cn/docs/records.html#record-list
# End configure

DDNS_POST="\
login_token=$LOGIN_TOKEN\
&format=json\
&domain=$DOMAIN\
&record_id=$RECORD_ID\
&record_line_id=10%3D0\
&sub_domain=$SUB_DOMAIN"

RECORD_INFO_POST="\
login_token=$LOGIN_TOKEN\
&format=json\
&domain=$DOMAIN\
&record_id=$RECORD_ID"

PRE_ADDRESS=
while [ -z $PRE_ADDRESS ]
do
	JSON=$(curl -X POST -s -f https://dnsapi.cn/Record.Info -d "$RECORD_INFO_POST")
	if [ ! $? ] || [ "$(echo $JSON|jq '.status.code')" != '"1"' ]; then
		sleep 60
		continue
	fi
	read PRE_ADDRESS< <(echo $JSON|jq '.record.value')
done
PRE_ADDRESS=${PRE_ADDRESS//\"/}
echo $PRE_ADDRESS

while :
do
	ADDRESS=$(curl -f -s http://ifconfig.cc)
	if [ ! $? ] || [ -z $ADDRESS ] || [ "$ADDRESS" = "$PRE_ADDRESS" ]; then
		echo OFF-LINE OR SAME
		sleep 60
		continue
	fi

	STATUS_CODE=$(curl  https://dnsapi.cn/Record.Ddns \
		-X POST -f -s \
		-d "${DDNS_POST}&value=$ADDRESS" \
		| jq '.status.code')

	if [ ${PIPESTATUS[0]} ] && [[ $STATUS_CODE = '"1"' ]]; then
		PRE_ADDRESS=$ADDRESS
		sleep 240 # 4 minute
	else
		sleep 60
	fi
done

