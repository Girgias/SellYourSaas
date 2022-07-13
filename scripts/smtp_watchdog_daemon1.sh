#!/bin/bash

#
# smtp watch dog daemon 1.
#

export now=`date '+%Y-%m-%d %H:%M:%S'`
export WDLOGFILE='/var/log/ufw.log'

export DOMAIN=`grep '^domain=' /etc/sellyoursaas.conf | cut -d '=' -f 2`

echo >> /var/log/smtp_watchdog1.log
echo "**** ${0} started" >> /var/log/smtp_watchdog1.log
echo $now" Try to detect a smtp connexion from $WDLOGFILE and log who do it" >> /var/log/smtp_watchdog1.log 

#echo "${0} ${@}"
#echo "# User id --------> $(id -u)"
#echo "# Now ------------> $now"
#echo "# PID ------------> ${$}"
#echo "# PWD ------------> $PWD" 
#echo "# arguments ------> ${@}"
#echo "# path to me -----> ${0}"
#echo "# parent path ----> ${0%/*}"
#echo "# my name --------> ${0##*/}"
#echo "# realname -------> $(realpath ${0})"
#echo "# realname name --> $(basename $(realpath ${0}))"
#echo "# realname dir ---> $(dirname $(realpath ${0}))"

export EMAILFROM=`grep '^emailfrom=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export EMAILTO=`grep '^emailsupervision=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
if [ "x$EMAILFROM" == "x" ]; then
	export EMAILFROM=noreply@$DOMAIN
fi
if [ "x$EMAILTO" == "x" ]; then
	export EMAILTO=supervision@$DOMAIN
fi

export PID=${$}
export scriptdir=$(dirname $(realpath ${0}))

echo "DOMAIN=$DOMAIN" >> /var/log/smtp_watchdog1.log
echo "EMAILFROM=$EMAILFROM" >> /var/log/smtp_watchdog1.log
echo "EMAILTO=$EMAILTO" >> /var/log/smtp_watchdog1.log
echo "PID=$PID" >> /var/log/smtp_watchdog1.log

tail -F $WDLOGFILE | grep --line-buffered 'UFW ALLOW' | 
while read -r line ; do
	export now=`date '+%Y-%m-%d %H:%M:%S'`
	echo "$now ----- start smtp_watchdog_daemon1" >> /var/log/smtp_watchdog1.log 2>&1
	echo "Found a UFW ALLOW, in $WDLOGFILE, now try to find process owner..." >> /var/log/smtp_watchdog1.log 2>&1
	echo "$line" >> /var/log/smtp_watchdog1.log 2>&1

	export smtpipcaller=`echo $line | sed 's/.*SRC=//' | sed 's/\s.*//'`
	export smtpipcalled=`echo $line | sed 's/.*DST=//' | sed 's/\s.*//'`
	export smtpportcaller=`echo $line | sed 's/.*SPT=//' | sed 's/\s.*//'`
	export smtpportcalled=`echo $line | sed 's/.*DPT=//' | sed 's/\s.*//'`
	
	command="ss -p -t -a state all dport = $smtpportcalled dst = $smtpipcalled"
	result=`$command`
	
	export processid="smtpsocket"
	export processownerid="xxxx"
	
	echo "Emails were sent using SMTP by process $processowner" > /tmp/phpsendmail-$processowner-$processid.tmp
	echo "SMTP server called by $smtpipcaller:$smtpportcaller is $smtpipcalled:$smtpportcalled" >> /tmp/phpsendmail-$processowner-$processid.tmp
	echo $result >> /tmp/phpsendmail-$processowner-$processid.tmp
	#echo "smtp_watchdog_daemon1 has found an abusive smtp usage." | mail -aFrom:$EMAILFROM -s "[Warning] smtp_watchdog_daemon1 has found an abusive smtp usage on "`hostname`"." $EMAILTO
	#sleep 5
	export now=`date '+%Y%m%d%H%M%S'`
done

# This script never end